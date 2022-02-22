local Super = require(script.Parent)
local Weapon = Super:Extend()

Weapon.DisplayName = "Internal Template Weapon"
Weapon.DescriptionLight = "Light attack."
Weapon.DescriptionHeavy = "Heavy attack."

Weapon.CooldownLightTime = 1
Weapon.CooldownHeavyTime = 1

function Weapon:OnCreated()
	Super.OnCreated(self)
end

function Weapon:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:Use()

	return true
end

function Weapon:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	self.CooldownHeavy:Use()
	self.CooldownLight:Use()
	
	return true
end

function Weapon:ClearParts()
	self:ClearPartsHelper()
end

function Weapon:AddParts()
	
end

function Weapon:Equip()
	self:Unsheath()
end

function Weapon:Unequip()
	self:ClearParts()
end

function Weapon:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld()
	
	self.Legend:SetRunAnimation("NoWeapons")
end

function Weapon:Unsheath()
	self:ClearParts()
	self:AddParts()

	self.Legend:SetRunAnimation("SingleWeapon")
end

return Weapon