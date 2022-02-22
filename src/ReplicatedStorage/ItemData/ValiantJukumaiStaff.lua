return {
	Name = "Valiant Jukumai Staff",
	Class = "WeaponStaff",
	AssetsName = "ValiantJukumaiStaff",
	Description = "A Jukumai necromancer's staff, imbued with some of the quirky magic of the League of Valor's wizards.",
	Image = "rbxassetid://5754320703",
	UpgradeMaterials = {Steel = 0.1, Worldstone = 0.01},
	Rarity = "Mythic",
	Args = {
		DescriptionHeavy = function(self)
			return string.format("Blast the targeted enemy for %d damage. If the enemy is slain by this blast, chain the blast to the nearest enemy.", self:GetBlastDamage())
		end,
		
		GetBlastDamage = function(self)
			return self:GetPowerHelper("Dominance") * 0.8
		end,
		
		AttackHeavyManaCost = 15,
		CooldownHeavyTime = 0.5,
		
		ValorBlast = function(self, target)
			self:GetService("DamageService"):Damage{
				Source = self.Legend,
				Target = target,
				Amount = self:GetBlastDamage(),
				Weapon = self,
				Type = "Disintegration",
				Tags = {"Magical"},
			}

			self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
				Position = target:GetPosition(),
				Radius = 8,
				Duration = 0.2,
				PartArgs = {
					BrickColor = BrickColor.new("Bright orange"),
					Material = Enum.Material.Neon,
				},
			})

			target:SoundPlayByObject(self.Assets.Sounds.Blast)
			
			-- chain the blast
			if target.Health <= 0 then
				local targetDistancePairs = {}
				
				local position = target:GetPosition()
				local range = 48
				
				self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
					Position = position,
					Range = range,
					Callback = function(target, data)
						if target.Health <= 0 then return end
						table.insert(targetDistancePairs, {Target = target, Distance = data.DistanceSq})
					end
				})
				
				local bestTarget, bestDistance
				for _, pair in pairs(targetDistancePairs) do
					if (not bestTarget) or (pair.Distance < bestDistance) then
						bestTarget = pair.Target
						bestDistance = pair.Distance
					end
				end
				
				if bestTarget then
					delay(0.5, function()
						self:ValorBlast(bestTarget)
					end)
				end
			end
		end,
		
		AttackHeavy = function(self)
			if not self.CooldownHeavy:IsReady() then return end
			
			local manaCost = self.AttackHeavyManaCost
			if not self.Legend:CanUseMana(manaCost) then return end
			
			local aimPosition = self.Targeting:GetClampedAimPosition(self.Legend, 32)
			
			if not self.Legend:CanSeePoint(aimPosition) then return end
			
			local didAttack = false
			self.Targeting:TargetCircleNearest(self.Targeting:GetEnemies(), {
				Position = aimPosition,
				Range = 8,
				Callback = function(target)
					self:ValorBlast(target)
					
					didAttack = true
				end
			})
			
			if didAttack then
				self.Legend:AnimationPlay("StaffCast")
				
				self.CooldownHeavy:Use()
				self.CooldownLight:UseMinimum(self.CooldownHeavy.Time)
				
				self.Legend:UseMana(manaCost)
			end

			return true
		end,
	},
}