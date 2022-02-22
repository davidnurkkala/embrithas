local Super = require(script.Parent)
local Ability = Super:Extend()

Ability.Type = "Offense"

Ability.Duration = 4
Ability.Radius = 12
Ability.SpeedBuff = 1/3

function Ability:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 16
end

function Ability:GetDamagePerSecond()
	return self:GetPowerHelper(self:GetWeaponProperty("PrimaryStatName")) * (self.Duration + 2) / self.Duration
end

function Ability:GetDamageType()
	return self:GetWeaponProperty("DamageType")
end

function Ability:GetDescription()
	local damageString
	if self:IsDualWeapon(self:GetWeaponClassName()) then
		damageString = string.format(
			"%d %s damage per second",
			self:GetDamagePerSecond(),
			self:GetDamageType()
		)
	else
		damageString = "damage based on your weapon"
	end
	
	return string.format(
		"Requires a dual-wielded weapon. Channel to begin spinning dangerously for %d seconds, dealing %s to enemies around you. During this time, move %d%% faster.",
		self.Duration,
		damageString,
		self.SpeedBuff * 100
	)
end

-- DarkModule was here 7/6/2021
function Ability:OnActivatedServer()
	local weapon = self.Legend.Weapon
	
	if not self:IsDualWeapon(self:GetWeaponClassName()) then return end
	
	local duration = self.Duration
	local attackCount = self.AttackCount
	local interval = 0.2
	local damageType = self:GetDamageType()
	local attackNumber = 0
	
	spawn(function()
		self.Legend:AnimationPlay("SaberSpin", nil, nil, 1 / interval)
		weapon:SetTrailsEnabled(true)
		
		local status = self.Legend:AddStatus("Status", {
			Type = "AbilitySpinAttackSpeedBuff",
			Time = duration,
			
			Category = "Good",
			ImagePlaceholder = "SPIN\nSPEED",
			
			OnStarted = function(status)
				status.Character.Speed.Percent += self.SpeedBuff
			end,
			OnEnded = function(status)
				status.Character.Speed.Percent -= self.SpeedBuff
			end,
		})
		
		self.Legend:Channel(duration, "Spin Attack", "Normal", {
			Interval = interval,
			CustomOnTicked = function(t, dt)
				if self.Legend.Weapon ~= weapon then
					return t:Fail()
				end
				
				weapon:AttackSound()
				
				local enemiesHit = {}

				self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
					Position = self.Legend:GetPosition(),
					Range = self.Radius,
					Callback = function(enemy)
						table.insert(enemiesHit, enemy)
					end,
				})

				local count = #enemiesHit
				for index, enemy in pairs(enemiesHit) do
					local ratio = (index - 1) / count
					delay(interval * ratio, function()
						self:GetService("DamageService"):Damage{
							Source = self.Legend,
							Target = enemy,
							Amount = self:GetDamagePerSecond() * dt,
							Weapon = self,
							Type = damageType,
						}

						weapon:HitEffects(enemy)
					end)
				end
			end,
		})
		
		status:Stop()
		
		self.Legend:AnimationStop("SaberSpin")
		weapon:SetTrailsEnabled(false)
	end)
	
	self.Legend.InCombatCooldown:Use()
	return true
end

return Ability