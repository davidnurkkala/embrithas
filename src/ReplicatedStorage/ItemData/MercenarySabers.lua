return {
	Name = "Mercenary Sabers",
	Class = "WeaponSabers",
	AssetsName = "MercenarySabers",
	Description = "Blades wielded by elite Lorithasi mercenaries. Steeped in the shadowy essence of the strong soul that once wielded them.",
	Image = "rbxassetid://5465136831",
	UpgradeMaterials = {Steel = 0.1},
	Rarity = "Rare",
	
	Args = {
		DescriptionHeavy = "Dash forward, dealing damage to enemies hit.",
		
		CooldownHeavyTime = 4,
		AttackHeavy = function(self)
			if not self.CooldownHeavy:IsReady() then return end
			self.CooldownHeavy:Use()
			self.CooldownLight:Use()
			
			local direction = self.Legend:GetAimCFrame().LookVector

			local duration = 0.175
			local distance = 20
			local speed = distance / duration

			local mover = Instance.new("BodyVelocity")
			mover.MaxForce = Vector3.new(1e5, 0, 1e5)
			mover.Velocity = direction * speed
			mover.Parent = self.Legend.Root

			self:FireRemote("FaceDirectionCalled", self.Legend.Player, direction, duration)
			self.Legend:AnimationPlay("SaberDash")
			self.Legend:SoundPlay("AdrenalineRush")
			
			local trails = {
				self.Right.Trail,
				self.Left.Trail,
			}
			for _, trail in pairs(trails) do
				trail.Enabled = true
			end

			local here = self.Legend:GetPosition()
			local there = here + direction * (distance / 2)

			self.Targeting:TargetSquare(self.Targeting:GetEnemies(), {
				CFrame = CFrame.new(there, here) * CFrame.Angles(0, math.pi, 0),
				Length = distance,
				Width = 9,
				Callback = function(enemy, data)
					if not self.Legend:CanSeePoint(enemy:GetPosition()) then return end

					delay(data.LengthWeight * duration, function()
						local damage = self:GetService"DamageService":Damage{
							Source = self.Legend,
							Target = enemy,
							Amount = self:GetDamage() * 2,
							Weapon = self,
							Type = "Slashing",
						}

						self:HitEffects(enemy)
					end)
				end
			})

			self.Legend:SetCollisionGroup("PlayerEthereal")

			delay(duration, function()
				self.Legend:SetCollisionGroup("Player")

				mover:Destroy()
				self.Legend.Root.Velocity = Vector3.new()
				self.Legend:AnimationStop("SaberDash")
				
				for _, trail in pairs(trails) do
					trail.Enabled = false
				end
			end)

			return true
		end,
	}
}