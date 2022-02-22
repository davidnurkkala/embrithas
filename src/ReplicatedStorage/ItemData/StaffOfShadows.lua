return {
	Name = "Staff of Shadows",
	Class = "WeaponStaff",
	AssetsName = "StaffOfShadows",
	Description = "A staff set with shadow-infused worldstone. Invented by the College to leverage its strange power.",
	Image = "rbxassetid://5465318895",
	UpgradeMaterials = {Steel = 0.1, Worldstone = 0.01},
	Rarity = "Rare",
	Perks = {
		function(self)
			return string.format("Dealing damage to an enemy afflicts them with shadow. Damaging afflicted enemies launches a bolt to the nearest enemy which deals %d damage. Each \"leap\" penalizes the damage slightly.", self:GetBoltDamage())
		end,
	},
	
	Args = {
		DescriptionHeavy = function(self)
			return string.format("Send bolts to all nearby afflicted enemies, dealing %d damage per target to each target and removing the affliction.", self:GetBoltDamage())
		end,
		
		GetBoltDamage = function(self)
			return self:GetPowerHelper("Dominance") * 1.0
		end,
		
		AttackHeavy = function(self)
			if not self.CooldownHeavy:IsReady() then return end
			
			local victims = {}
			self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
				Position = self.Legend:GetPosition(),
				Range = 256,
				Callback = function(enemy)
					if enemy:HasStatusType("ShadowAfflicted") then
						table.insert(victims, enemy)
					end
				end
			})
			local count = #victims
			
			if count <= 0 then return end
			
			self.CooldownHeavy:Use()
			self.CooldownLight:Use()
			
			self.Legend:AnimationPlay("StaffCast", 0)
			
			
			local damage = self:GetBoltDamage() * count
			
			self:Shuffle(victims)
			
			local effects = self:GetService("EffectsService")
			
			for index, victim in pairs(victims) do
				local pause = (index - 1) * 0.1
				
				delay(pause, function()
					effects:RequestEffectAll("ShadowAfflictedSpread", {
						Duration = 0.2,
						RootStart = self.Legend.Root,
						RootFinish = victim.Root,
					})
					self.Legend:SoundPlayByObject(self.Assets.Sounds.Bolt)
					
					wait(0.2)
					
					local status = victim:GetStatusByType("ShadowAfflicted")
					if status then
						status:Stop()
					end
					
					effects:RequestEffectAll("ShadowAfflictedSpread", {
						Duration = 0.2,
						RootStart = victim.Root,
						RootFinish = self.Legend.Root,
					})
					victim:SoundPlayByObject(self.Assets.Sounds.Bolt)
					
					local damage = self:GetService"DamageService":Damage{
						Source = self.Legend,
						Target = victim,
						Amount = damage,
						Weapon = self,
						ShadowAfflictedDisabled = true,
						Type = "Piercing",
						Tags = {"Magical"},
					}
				end)
			end

			return true
		end,
		
		OnDealtDamage = function(self, damage)
			if damage.ShadowAfflictedDisabled then return end
			if damage.Weapon ~= self then return end
			
			local enemy = damage.Target
			local status = enemy:GetStatusByType("ShadowAfflicted")
			
			if status then
				status:Restart()
				
				local targets = self:GetService("TargetingService"):GetEnemies()
				local bestTarget = nil
				local bestRangeSq = 32 ^ 2
				for _, target in pairs(targets) do
					local isNewTarget = (damage.ShadowAfflictedVictims == nil) or (table.find(damage.ShadowAfflictedVictims, target) == nil)
					if (target ~= enemy) and isNewTarget then
						local distanceSq = enemy:DistanceToSquared(target:GetPosition())
						if distanceSq < bestRangeSq then
							bestTarget = target
							bestRangeSq = distanceSq
						end
					end
				end
				
				if bestTarget then
					local duration = 0.5
					
					enemy:SoundPlayByObject(self.Assets.Sounds.Bolt)
					
					self:GetService("EffectsService"):RequestEffectAll("ShadowAfflictedSpread", {
						Duration = duration,
						RootStart = enemy.Root,
						RootFinish = bestTarget.Root,
					})
					
					local victims = {}
					for _, victim in pairs(damage.ShadowAfflictedVictims or {}) do
						table.insert(victims, victim)
					end
					table.insert(victims, enemy)
					
					local loss = 0.1
					local min = 0.2
					local penalty = math.max(min, 1 - (loss * #victims))
					
					delay(duration, function()
						local damage = self:GetService"DamageService":Damage{
							Source = self.Legend,
							Target = bestTarget,
							Amount = self:GetBoltDamage() * penalty,
							Weapon = self,
							Type = "Piercing",
							Tags = {"Magical"},
							
							ShadowAfflictedVictims = victims,
						}
					end)
				end
			else
				enemy:AddStatus("StatusShadowAfflicted", {
					Time = 5,
				})
			end
		end
	},
}