local Super = require(script.Parent)
local Ability = Super:Extend()

Ability.ProjectileWeaponClassNames = {
	"WeaponBowAndDagger",
	"WeaponCrossbowAndShortsword",
	"WeaponMusket",
}

function Ability:IsProjectileWeapon(weapon)
	for _, className in pairs(self.ProjectileWeaponClassNames) do
		if weapon:IsA(className) then
			return true
		end
	end
	return false
end

return Ability