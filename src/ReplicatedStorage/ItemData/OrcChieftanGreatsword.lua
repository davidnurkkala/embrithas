return {
	Name = "Orc Chieftan's Greatsword",
	Class = "WeaponGreatsword",
	AssetsName = "OrcChieftanGreatsword",
	Description = "A colossal weapon of wood, bone, and tooth. Savage and vicious, much like its last owner.",
	Image = "rbxassetid://5924791726",
	UpgradeMaterials = {Iskith = 0.1, MetallicCorruption = 0.01},
	Rarity = "Mythic",
	Perks = {
		"Spin attacks cost half as much rage and deal half as much damage.",
		"Spin attacks launch damaging air blasts towards the targeted location.",
	},
	Args = {
		AttackHeavyCostRage = 15,
		AttackHeavyDamageMultiplier = 0.5,
		
		OnSpinAttack = function(self)
			local cframe = self.Legend:GetAimCFrame()
			
			self.Legend:SoundPlayByObject(self.Assets.Sounds.AirSlice)
			
			local width = 6
			local speed = 64
			local range = 32
			
			local crescent = self.Storage.Models.Crescent:Clone()
			crescent.Size = Vector3.new(width, 0, 4)

			local model = Instance.new("Model")
			crescent.Parent = model
			model.Name = "AirSlice"
			model.PrimaryPart = crescent

			local projectile = self:CreateNew"Projectile"{
				Model = model,
				CFrame = cframe,
				Velocity = cframe.LookVector * speed,
				FaceTowardsVelocity = true,
				Range = range,
				Victims = {},

				OnTicked = function(p)
					local here = p.LastCFrame.Position
					local there = p.CFrame.Position
					local delta = (there - here)
					local length = delta.Magnitude
					local midpoint = (here + there) / 2
					local cframe = CFrame.new(midpoint, there)

					for _, enemy in pairs(self:GetService("TargetingService"):GetEnemies()) do
						local delta = cframe:PointToObjectSpace(enemy:GetPosition())
						if math.abs(delta.X) <= (width / 2) and math.abs(delta.Z) <= (length / 2) and (not table.find(p.Victims, enemy)) then
							self:GetService("DamageService"):Damage{
								Source = self.Legend,
								Target = enemy,
								Amount = self:GetDamage(),
								Type = "Slashing",
							}
							table.insert(p.Victims, enemy)
						end
					end
				end,
			}
			self:GetWorld():AddObject(projectile)
		end
	}
}