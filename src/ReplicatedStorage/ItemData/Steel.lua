local function onDealtDamage(self, damage)
	if damage.IsBleed then return end
	if damage.Weapon ~= self then return end
	
	local target = damage.Target
	if target and target.Health > 0 then
		local duration = 5
		local damage = self:GetPowerHelper(self.PrimaryStatName)
		local dps = damage / duration
		
		local status = target:GetStatusByType("Bleeding")
		if status then
			status:Restart()
		else
			target:AddStatus("Status", {
				Type = "Bleeding",
				Time = duration,
				Interval = 0.5,
				OnTicked = function(status, dt)
					self:GetService("DamageService"):Damage{
						Source = self.Legend,
						Target = target,
						Amount = dps * dt,
						Weapon = self,
						IsBleed = true,
						Type = "Internal",
					}
				end,
			})
		end
	end
end

local perk = function(self)
	return string.format("Hitting an enemy causes them to bleed, taking %d damage over 5 seconds. Doesn't stack.", self:GetPrimaryStatValue())
end

return {
	Dirks = {
		Name = "Steel Dual Dirks",
		Class = "WeaponDualDirks",
		AssetsName = "SteelDualDirks",
		Description = "Viciously sharp longdaggers for rapidly lacerating foes.",
		Image = "rbxassetid://5693236900",
		UpgradeMaterials = {Steel = 0.1},
		Perks = {perk},
		
		Args = {
			OnDealtDamage = onDealtDamage,
		}
	},
	
	Rapier = {
		Name = "Steel Rapier",
		Class = "WeaponRapier",
		AssetsName = "SteelRapier",
		Description = "A rapier of superior make and material to its iron counterpart.",
		Image = "rbxassetid://5673074254",
		UpgradeMaterials = {Steel = 0.1},
		Perks = {perk},
		
		Args = {
			OnDealtDamage = onDealtDamage,
		}
	},
	
	Halberd = {
		Name = "Steel Halberd",
		Class = "WeaponHalberd",
		AssetsName = "SteelHalberd",
		Description = "A halberd with an unusually sharp steel blade.",
		Image = "rbxassetid://5071290755",
		UpgradeMaterials = {Steel = 0.1},
		Perks = {perk},
		
		Args = {
			OnDealtDamage = onDealtDamage,
		}
	},
}