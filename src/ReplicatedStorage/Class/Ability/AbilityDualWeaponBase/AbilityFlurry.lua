local Super = require(script.Parent)
local Ability = Super:Extend()

Ability.Type = "Offense"

Ability.Duration = 2
Ability.AttackCount = 25

function Ability:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 8
end

function Ability:GetDamage()
	return self:GetPowerHelper(self:GetWeaponProperty("PrimaryStatName")) * (self.Duration + 3) / self.AttackCount
end

function Ability:GetDamageType()
	return self:GetWeaponProperty("DamageType")
end

function Ability:GetDescription()
	local damageString
	if self:IsDualWeapon(self:GetWeaponClassName()) then
		damageString = string.format(
			"%d %s damage.",
			self:GetDamage(),
			self:GetDamageType()
		)
	else
		damageString = "damage based on your weapon."
	end
	
	return string.format(
		"Requires a dual-wielded weapon. Channel to unleash a flurry of %d blows for up to %d seconds, each dealing %s",
		self.AttackCount,
		self.Duration,
		damageString
	)
end

function Ability:OnActivatedServer()
	local weapon = self.Legend.Weapon
	
	if not self:IsDualWeapon(self:GetWeaponClassName()) then return end
	
	local duration = self.Duration
	local attackCount = self.AttackCount
	local interval = duration / attackCount
	local damageType = self:GetDamageType()
	local attackNumber = 0
	
	spawn(function()
		self.Legend:Channel(duration, "Flurry", "Normal", {
			Interval = interval,
			CustomOnTicked = function(t, dt)
				if self.Legend.Weapon ~= weapon then
					return t:Fail()
				end
				
				weapon:AttackSound()
				
				if attackNumber == 0 then
					self.Legend:AnimationStop(weapon:GetFlurryAnimation(1))
					self.Legend:AnimationPlay(weapon:GetFlurryAnimation(0))
				else
					self.Legend:AnimationStop(weapon:GetFlurryAnimation(0))
					self.Legend:AnimationPlay(weapon:GetFlurryAnimation(1))
				end
				attackNumber = (attackNumber + 1) % 2
				
				self.Targeting:TargetCone(self.Targeting:GetEnemies(), {
					CFrame = self.Legend:GetAimCFrame(),
					Angle = 90,
					Range = 12,
					Callback = function(enemy)
						self:GetService("DamageService"):Damage{
							Source = self.Legend,
							Target = enemy,
							Amount = self:GetDamage(),
							Weapon = self,
							Type = damageType,
						}
						
						weapon:HitEffects(enemy)
					end,
				})
			end,
		})
	end)
	
	self.Legend.InCombatCooldown:Use()
	return true
end

return Ability