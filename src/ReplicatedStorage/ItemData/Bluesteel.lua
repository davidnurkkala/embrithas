local function onDealtDamage(self, damage)
	if damage.IsFrostyExplosion then return end
	if damage.Weapon ~= self then return end
				
	local target = damage.Target
	
	if target:HasStatusType("FrostyImmunity") then return end
	
	local status = target:GetStatusByType("Frosty")
	if status then
		if status.Stacks >= 2 then
			status:Stop()
			
			if not target.Resilient then
				target:AddStatus("StatusStunned", {
					Time = 1,
				})
			end
			
			self:GetService("DamageService"):Damage{
				Source = self.Legend,
				Target = target,
				Amount = self:GetDamage(),
				IsFrostyExplosion = true,
				Weapon = self,
				Type = "Cold",
				Tags = {"Magical"},
			}
			
			target:SoundPlayByObject(self.Storage.Sounds.IceShatter)
			
			self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
				Position = target:GetPosition(),
				Color = Color3.fromRGB(114, 154, 171),
				Radius = 8,
				Duration = 0.25,
			})
			
			if self.OnFrostyExplosion then
				self:OnFrostyExplosion()
			end
			
			target:AddStatus("Status", {
				Type = "FrostyImmunity",
				Time = 5,
				
				ImagePlaceholder = "FRSTY\nCD",
			})
		else
			status:AddStack()
		end
	else
		target:AddStatus("StatusFrosty", {
			Time = 5,
		})
	end
end

local perk = "Attacks apply frost to targets. Three attacks shatters the frost, damaging and stunning targets."

return {
	Handaxes = {
		Name = "Bluesteel Handaxes",
		Class = "WeaponHandaxes",
		AssetsName = "BluesteelHandaxes",
		Description = "A truly Evrigan weapon. Cold to the touch, regardless of environment. Perfectly weighted and masterfully crafted.",
		Image = "rbxassetid://5510543042",
		UpgradeMaterials = {Bluesteel = 0.1},
		Rarity = "Rare",
		Perks = {
			perk,
		},
		
		Args = {
			CustomOnDealtDamage = onDealtDamage,
		}
	},
	
	Crossbow = {
		Name = "Bluesteel Crossbow",
		Class = "WeaponCrossbowAndShortsword",
		AssetsName = "BluesteelCrossbowAndShortsword",
		Description = "Unusual since Evrig prefer close-quarters combat. Durable and well-balanced.",
		Image = "rbxassetid://5673409622",
		UpgradeMaterials = {Bluesteel = 0.1},
		Rarity = "Rare",
		Perks = {
			perk,
		},
		
		Args = {
			CustomOnDealtDamage = onDealtDamage,
		}
	},
	
	Axe = {
		Name = "Bluesteel Axe",
		Class = "WeaponAxeAndBuckler",
		AssetsName = "BluesteelAxeAndBuckler",
		Description = "The most popular weapon of Evrig raid-captains. Brutal and efficient.",
		Image = "rbxassetid://5676915110",
		UpgradeMaterials = {Bluesteel = 0.1},
		Rarity = "Rare",
		Perks = {
			perk,
			"Restore a parry upon shattering frost. Can't occur more than once per 5 seconds.",
		},
		
		Args = {
			CooldownStatusType = "BluesteelAxeParryRestoreCooldown",
			
			CustomOnDealtDamage = onDealtDamage,
			
			OnFrostyExplosion = function(self)
				for _, status in pairs(self.Legend.Statuses) do
					print(status.Type)
				end
				if self.Legend:HasStatusType(self.CooldownStatusType) then return end
				
				self:ChangeParries(1)
				
				print(self.CooldownStatusType)
				self.Legend:AddStatus("Status", {
					Time = 5,
					Type = self.CooldownStatusType,
					
					ImagePlaceholder = "BLSTL\nCD",
				})
			end,
		}
	},
	
	Sword = {
		Name = "Bluesteel Sword",
		Class = "WeaponSwordAndShield",
		AssetsName = "BluesteelSwordAndShield",
		Description = "A weapon often used by the most skilled Evrig warriors. Elegant and deadly.",
		Image = "rbxassetid://5676915202",
		Rarity = "Rare",
		UpgradeMaterials = {Bluesteel = 0.1},
		Perks = {
			perk,
		},
		
		Args = {
			OnDealtDamage = onDealtDamage,
		},
	},
	
	Battleaxe = {
		Name = "Bluesteel Battleaxe",
		Class = "WeaponBattleaxe",
		AssetsName = "BluesteelBattleaxe",
		Description = "A harsh weapon from the harsh land of Evrig. Cold to the touch, regardless of environment. Menacingly well-forged.",
		Image = "rbxassetid://5510858904",
		Rarity = "Rare",
		UpgradeMaterials = {Bluesteel = 0.1},
		Perks = {
			perk,
		},
		
		Args = {
			OnDealtDamage = onDealtDamage,
		}
	},
	
	Claws = {
		Name = "Bluesteel Claws",
		Class = "WeaponClaws",
		AssetsName = "BluesteelClaws",
		Description = "An animalistic weapon favored by a famous Evrig slayer. As ferocious as a polar bear.",
		Image = "rbxassetid://5693865147",
		Rarity = "Mythic",
		UpgradeMaterials = {Bluesteel = 0.1},
		Perks = {
			perk,
		},
		
		Args = {
			OnDealtDamage = onDealtDamage,
		}
	}
}