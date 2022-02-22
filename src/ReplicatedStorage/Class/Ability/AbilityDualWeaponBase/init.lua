local Super = require(script.Parent)
local Ability = Super:Extend()

Ability.DualWeaponClassNames = {
	"WeaponSabers",
	"WeaponClaws",
	"WeaponDualDirks",
	"WeaponHandaxes",
	
}

function Ability:IsDualWeapon(weaponClassName)
	local handaxes = "WeaponHandaxes"
	
	local weapon
	if self:IsClient() then
		weapon = self:GetClass(weaponClassName)
	else
		weapon = self.Legend.Weapon
	end
	
	for _, className in pairs(self.DualWeaponClassNames) do
		if weapon:IsA(className) then
			if weapon:IsA(handaxes) then
				return weapon.ThrowAble
			else
				return true
			end
		end
	end
	return false
end

return Ability