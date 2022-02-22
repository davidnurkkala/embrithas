return {
	Name = "Mercenary Greatmace",
	Class = "WeaponMaul",
	AssetsName = "MercenaryGreatmace",
	Description = "A titanic bulk of metal once wielded by an elite Lorithasi mercenary. The transient shadow of its former wielder remains within it.",
	Image = "rbxassetid://5478235950",
	UpgradeMaterials = {Steel = 0.1},
	Rarity = "Rare",
	Perks = {
		"Damaging enemies afflicts them with shadow. Deal 25% more damage to afflicted enemies.",
	},
	
	Args = {
		OnWillDealDamage = function(self, damage)
			local enemy = damage.Target
			local status = enemy:GetStatusByType("ShadowAfflicted")
			
			if status then
				status:Restart()
				damage.Amount = damage.Amount * 1.25
			end
		end,
		
		OnDealtDamage = function(self, damage)
			local enemy = damage.Target
			
			if not enemy:HasStatusType("ShadowAfflicted") then
				enemy:AddStatus("StatusShadowAfflicted", {
					Time = 5,
				})
			end
		end,
	}
}