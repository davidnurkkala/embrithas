local Super = require(script.Parent)
local WeaponStaffLightning = Super:Extend()

WeaponStaffLightning.DisplayName = "Staff of Lightning"
WeaponStaffLightning.DescriptionHeavy = function(self)
	return string.format(
		"Use mana to strike the targeted location with lightning, dealing %d damage to enemies caught in the blast (%d to enemies in the center).",
		self:GetLightningDamage(),
		self:GetLightningDamageCenter()
	)
end

WeaponStaffLightning.AttackHeavyRange = 48
WeaponStaffLightning.AttackHeavyRadius = 12
WeaponStaffLightning.ManaCost = 15

function WeaponStaffLightning:OnCreated()
	Super.OnCreated(self)
end

function WeaponStaffLightning:GetLightningDamage()
	return self:GetLightningDamageCenter() / 2
end

function WeaponStaffLightning:GetLightningDamageCenter()
	return self:GetPowerHelper("Dominance") * 1.2
end

function WeaponStaffLightning:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	
	local manaCost = self.ManaCost
	if self:HasModifier("Efficient") then
		manaCost *= 0.5
	end
	
	if not self.Legend:CanUseMana(manaCost) then return end
	
	self.CooldownHeavy:Use()
	self.CooldownLight:Use()
	
	self.Legend:UseMana(manaCost)
	
	self.Legend:AnimationPlay("StaffCast", 0)
	
	self:RangedWeaponSlow()
	
	local position = self.Targeting:GetClampedAimPosition(self.Legend, self.AttackHeavyRange)
	local effects = self:GetService("EffectsService")
	effects:RequestEffectAll("Thunderstrike", {
		Position = position,
	})
	effects:RequestEffectAll("AirBlast", {
		Position = position,
		Radius = self.AttackHeavyRadius,
		Duration = 0.25,
		PartArgs = {
			Material = Enum.Material.Neon,
			BrickColor = BrickColor.new("Electric blue"),
		},
	})
	
	local emitter = self.Staff.Top.Emitter
	emitter.Enabled = true
	delay(0.3, function()
		emitter.Enabled = false
	end)
	
	self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
		Position = position,
		Range = self.AttackHeavyRadius,
		Callback = function(enemy, data)
			local damage = self:GetLightningDamage()
			if data.DistanceRatio < 0.33 then
				damage = self:GetLightningDamageCenter()
			end
			
			self:GetService"DamageService":Damage{
				Source = self.Legend,
				Target = enemy,
				Amount = damage,
				Weapon = self,
				Type = "Electrical",
				Tags = {"Magical"},
			}
		end
	})

	return true
end

function WeaponStaffLightning:Equip()
	Super.Equip(self)
end

function WeaponStaffLightning:Unequip()
	Super.Unequip(self)
	
	self:GetService("EffectsService"):CancelEffect(self.RangeEffectId)
end

return WeaponStaffLightning