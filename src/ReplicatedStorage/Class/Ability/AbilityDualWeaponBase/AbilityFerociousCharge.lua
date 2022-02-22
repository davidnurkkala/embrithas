local Super = require(script.Parent)
local Ability = Super:Extend()

Ability.Type = "Offense"

Ability.AttackCount = 10
Ability.Range = 32
Ability.Speed = 96

function Ability:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 30
end

function Ability:GetDamage()
	return self:GetPowerHelper(self:GetWeaponProperty("PrimaryStatName")) * 2
end

function Ability:GetDamageType()
	return self:GetWeaponProperty("DamageType")
end

function Ability:GetDescription()
	local damageString
	if self:IsDualWeapon(self:GetWeaponClassName()) then
		damageString = string.format(
			"%d %s damage",
			self:GetDamage(),
			self:GetDamageType()
		)
	else
		damageString = "damage based on your weapon"
	end
	
	return string.format(
		"Requires a dual-wielded weapon. Charge to the targeted enemy and then chain your attack into up to %d other enemies, dealing %s to each enemy hit. During this charge and for a short period afterwards, you are untargetable.",
		self.AttackCount,
		damageString
	)
end

function Ability:HitTarget(enemy, attackNumber, victims, weapon, status)
	local here = self.Legend:GetPosition()
	local there = enemy:GetPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	delta -= delta.Unit * 4
	there = here + delta
	
	local distance = delta.Magnitude
	local duration = distance / self.Speed
	
	self.Legend:FaceTowards(there)
	local cframe = self.Legend.Root.CFrame + delta
	
	self:GetService("EffectsService"):RequestEffectAll("Tween", {
		Object = self.Legend.Root,
		Goals = {CFrame = cframe},
		Duration = duration,
		Style = Enum.EasingStyle.Linear,
	})
	
	self.Legend:AnimationPlay("DualWieldCharge", 0)
	self:FireRemote("FaceDirectionCalled", self.Legend.Player, delta.Unit, duration)
	weapon:SetTrailsEnabled(true)
	
	delay(duration, function()
		self.Legend:AnimationStop("DualWieldCharge", 0)
		self.Legend.Root.CFrame = cframe
		
		if not weapon:IsEquipped() then return end
		
		weapon:SetTrailsEnabled(false)
		
		self:GetService("DamageService"):Damage{
			Source = self.Legend,
			Target = enemy,
			Amount = self:GetDamage(),
			Weapon = self,
			Type = self:GetDamageType(),
			Tags = weapon.DamageTags,
		}
		weapon:HitEffects(enemy)
		
		status:Restart()

		if attackNumber >= self.AttackCount then return end

		table.insert(victims, enemy)

		local here = enemy:GetPosition()
		local targetDistancePairs = {}

		self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
			Position = here,
			Range = self.Range,
			Callback = function(target, data)
				if target == enemy then return end
				if table.find(victims, target) then return end

				local pair = {
					Target = target,
					DistanceSq = data.DistanceSq,
				}
				table.insert(targetDistancePairs, pair)
			end,
		})

		if #targetDistancePairs == 0 then return end

		table.sort(targetDistancePairs, function(a, b)
			return a.DistanceSq < b.DistanceSq
		end)

		self:HitTarget(targetDistancePairs[1].Target, attackNumber + 1, victims, weapon, status)
	end)
end

function Ability:OnActivatedServer()
	local weapon = self.Legend.Weapon
	
	if not self:IsDualWeapon(self:GetWeaponClassName()) then return end
	
	local position = self.Targeting:GetClampedAimPosition(self.Legend, self.Range)
	local didAttack = false

	self.Targeting:TargetCircleNearest(self.Targeting:GetEnemies(), {
		Position = position,
		Range = 8,
		Callback = function(enemy)
			local status = self.Legend:AddStatus("Status", {
				Time = 2,
				Type = "FerociousChargeUntargetable",
				
				Category = "Good",
				ImagePlaceholder = "FC\nUNTRG",
				
				OnStarted = function(status)
					status.Character.Untargetable += 1
				end,
				OnEnded = function(status)
					status.Character.Untargetable -= 1
				end,
			})
			self:HitTarget(enemy, 1, {}, weapon, status)
			didAttack = true
		end,
	})
	
	self.Legend.InCombatCooldown:Use()
	return didAttack
end

return Ability