local Super = require(script.Parent)
local AbilityManaDarts = Super:Extend()

AbilityManaDarts.Type = "Offense"

AbilityManaDarts.UsesMana = true
AbilityManaDarts.ManaCost = 10
AbilityManaDarts.Range = 64

function AbilityManaDarts:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 1
end

function AbilityManaDarts:GetDamage()
	return self:GetPowerHelper("Dominance") * 0.4
end

function AbilityManaDarts:GetManaCost()
	return self:Lerp(10, 5, self:GetUpgrades() / 10)
end

function AbilityManaDarts:GetCooldown()
	return self:Lerp(1, 0.15, self:GetUpgrades() / 10)
end

function AbilityManaDarts:GetDescription()
	return string.format(
		"Hurl a magic dart dealing %d damage. Does not require line of sight to the target. Costs %d mana. Cooldown: %4.2fs.",
		self:GetDamage(),
		self:GetManaCost(),
		self:GetCooldown()
	)
end

-- SkilledSniper1 was here 2/9/2021
function AbilityManaDarts:OnActivatedServer()
	local manaCost = self:GetManaCost(self.Data)
	
	if not self.Legend:CanUseMana(manaCost) then return false end
	self.Legend:UseMana(manaCost)
	
	self.Legend:AnimationPlay("MagicCast", 0)
	
	delay(0.1, function()
		self.Legend:SoundPlayByObject(self.Storage.Sounds.ManaCast)
		
		local speed = 32
		local rotSpeed = math.pi
		
		self:GetClass("Projectile").CreateGenericProjectile{
			Model = self.Storage.Models.ManaDartProjectile,
			CFrame = self.Legend:GetAimCFrame(),
			Speed = speed,
			Width = 4,
			Range = 48,
			DeactivationType = "Enemy",
			OnTicked = function(projectile, dt)
				local here = projectile.CFrame.Position
				local there
				
				local targeting = self:GetService("TargetingService")
				targeting:TargetCircleNearest(targeting:GetEnemies(), {
					Position = here,
					Range = 12,
					Callback = function(target)
						there = target:GetPosition()
					end,
				})
				
				if not there then return end
				
				-- trumpetet was here 4/3/2021
				local delta = projectile.CFrame:PointToObjectSpace(there)
				local angle = math.atan2(delta.X, -delta.Z)
				
				local rotation = rotSpeed * -math.sign(angle) * dt
				if math.abs(rotation) > math.abs(angle) then
					rotation = angle
				end
				
				local cframe = projectile.CFrame * CFrame.Angles(0, rotation, 0)
				projectile.Velocity = cframe.LookVector * speed
			end,
			OnHitTarget = function(target)
				self:GetService("DamageService"):Damage{
					Source = self.Legend,
					Target = target,
					Amount = self:GetDamage(),
					Weapon = self,
					Type = "Piercing",
					Tags = {"Magical"},
				}
			end,
			OnEnded = function(projectile)
				self:GetService("EffectsService"):RequestEffectAll("Sound", {
					Position = projectile.CFrame.Position,
					Sound = self.Storage.Sounds.ManaHit,
				})
			end
		}
	end)
	
	-- cooldown management
	self.Cooldown.Time = self:GetCooldown(self.Data)
	self.Legend.InCombatCooldown:Use()
	
	return true
end

return AbilityManaDarts