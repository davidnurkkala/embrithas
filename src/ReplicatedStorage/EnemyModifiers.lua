local function CreateAffector(args)
	args.OnCreated = function(self)
		self.Affected = {}

		self:GetClass("Status").OnCreated(self)
	end
	args.IsAffecting = function(self, character)
		for _, affect in pairs(self.Affected) do
			if affect.Character == character then
				return true
			end
		end
	end
	args.Affect = function(self, character)
		if self:IsAffecting(character) then return end

		table.insert(self.Affected, {
			Character = character,
			Data = self:OnAffected(character),
		})
	end
	args.Unaffect = function(self, index)
		local affect = self.Affected[index]
		self:OnUnaffected(affect.Character, affect.Data)
		table.remove(self.Affected, index)
	end
	args.UnaffectByCharacter = function(self, character)
		for index, affect in pairs(self.Affected) do
			if affect.Character == character then
				self:Unaffect(index)
				break
			end
		end
	end
	args.OnEnded = function(self)
		for index = #self.Affected, 1, -1 do
			self:Unaffect(index)
		end
	end
	return args
end

local function CreateRally(args)
	args.RadiusSq = args.Radius ^ 2
	args.IsInRange = function(self, character)
		if not character.Active then
			return false
		end
		
		local here = self.Character:GetPosition()
		local there = character:GetPosition()
		local delta = (there - here)
		local distanceSq = delta.X ^ 2 + delta.Z ^ 2
		return distanceSq <= self.RadiusSq
	end
	args.OnTicked = function(self)
		for index, affect in pairs(self.Affected) do
			if not self:IsInRange(affect.Character) then
				self:Unaffect(index)
			end
		end

		for _, enemy in pairs(self:GetClass("Enemy").Instances) do
			if self:IsInRange(enemy) then
				self:Affect(enemy)
			end
		end
	end

	return CreateAffector(args)
end

return {
	{
		Name = "Mortar",
		Type = "Status",
		RandomDelay = true,
		Args = {
			Interval = 2/3,
			OnTicked = function(self)
				local enemy = self.Character

				local theta = math.pi * 2 * math.random()
				local r = 20 * math.random()
				local delta = Vector3.new(math.cos(theta) * r, 0, math.sin(theta) * r)
				local position = enemy:GetFootPosition() + delta

				local duration = 1
				local radius = 8

				self:GetService("EffectsService"):RequestEffectAll("LobProjectile", {
					Start = enemy.Root.Position,
					Finish = position,
					Model = self.Storage.Models.FireStrike,
					Height = 16,
					Duration = duration,
				})
				enemy:AttackCircle{
					Position = position,
					Radius = radius,
					Duration = duration,
					Sound = self.Storage.Sounds.FireHit,
					OnHit = function(legend)
						self:GetService"DamageService":Damage{
							Source = enemy,
							Target = legend,
							Amount = enemy.Damage,
							Type = "Bludgeoning",
							Tags = {"Magical"},
						}
					end
				}
			end,
		}
	},
	
	{
		Name = "Missile",
		IsUnique = true,
		Type = "Status",
		RandomDelay = true,
		Args = {
			Interval = 2,
			OnTicked = function(self)
				local enemy = self.Character
				if enemy:HasStatusType("Stunned") then return end
				if enemy.Hidden then return end
				
				local function projectile(shouldPlaySound)
					local cframe = CFrame.Angles(0, math.pi * 2 * math.random(), 0)
					local projectileSpeed = 16
					
					local function getTelegraphCFrame()
						return cframe * CFrame.new(0, 0, -4) + enemy:GetFootPosition()
					end
					
					enemy:TelegraphDirectional{
						Duration = 1,
						
						Length = 4,
						Width = 2,
						CFrame = getTelegraphCFrame(),
						
						OnTicked = function(t)
							t:UpdateCFrame(getTelegraphCFrame())
						end,
						
						Callback = function()
							local projectile = self:CreateNew"Projectile"{
								Model = self.Storage.Models.ShadowBolt:Clone(),
								CFrame = CFrame.new(enemy:GetPosition()),
								Velocity = cframe.LookVector * projectileSpeed,
								FaceTowardsVelocity = true,
								ShouldIgnoreFunc = function(part)
									if part:IsDescendantOf(enemy.Model) then return true end
									if part:IsDescendantOf(workspace.Enemies) then return true end
								end,
								OnHitPart = function(projectile, part)
									if part:IsDescendantOf(enemy.Model) then return end

									local character = self:GetService("TargetingService"):GetMortalFromPart(part)
									if character then
										if projectile:IsHittingCharacter(character) then
											enemy:DamageFunc(0.25, "Piercing", {"Magical"})(character)
										else
											return
										end
									end

									projectile:Deactivate()
								end
							}
							self:GetWorld():AddObject(projectile)
							self:GetService("EffectsService"):RequestEffectAll("ShowProjectile", {Projectile = projectile.Model, Width = 2})
							
							if shouldPlaySound then
								enemy:SoundPlayByObject(self.Storage.Sounds.ManaCast)
							end
						end,
					}
				end
				
				for number = 1, 3 do
					projectile(number == 1)
				end
			end,
		}
	},
	
	{
		Name = "Electric",
		IsUnique = true,
		Type = "Status",
		RandomDelay = true,
		Args = {
			Interval = 3,
			OnTicked = function(self)
				local enemy = self.Character
				if enemy:HasStatusType("Stunned") then return end
				if enemy.Hidden then return end
				
				local duration = 1.5
				local length = 24
				local width = 8
				local cframe = CFrame.new(enemy:GetFootPosition()) * CFrame.Angles(0, math.pi * 2 * math.random(), 0) * CFrame.new(0, 0, -length/2)
				
				enemy:AttackSquare{
					CFrame = cframe,
					Length = length,
					Width = width,
					Duration = duration,
					Sound = self.Storage.Sounds.ElectricSpark,
					OnHit = enemy:DamageFunc(0.25, "Electrical", {"Magical"}),
					AttachmentType = "Translate",
				}
				
				delay(duration, function()
					local here = enemy:GetPosition()
					
					self:GetService("EffectsService"):RequestEffectAll("ElectricSpark", {
						Start = here,
						Finish = here + cframe.LookVector * length,
						SegmentCount = 8,
						Radius = width / 2,
						Duration = 0.5,
						PartArgs = {
							BrickColor = BrickColor.new("Electric blue"),
							Material = Enum.Material.Neon,
						}
					})
				end)
			end
		}
	},

	{
		Name = "Explosive",
		Type = "Custom",
		Callback = function(self)
			self.Destroyed:Connect(function()
				self:AttackCircle{
					Position = self:GetFootPosition(),
					Radius = 20,
					Duration = 1.5,
					Sound = self.Storage.Sounds.Explosion1,
					OnHit = self:DamageFunc(1, "Bludgeoning", {"Magical"}),
				}
			end)
		end
	},

	{
		Name = "Resilient",
		Type = "Custom",
		IsUnique = true,
		Callback = function(self)
			self.Armor.Base += 0.25
		end,
	},

	{
		Name = "Empowering",
		Type = "Status",
		RandomDelay = true,
		Args = CreateRally{
			Interval = 0.5,

			Power = 0.25,
			Radius = 32,

			OnAffected = function(self, character)
				character.Power.Base += self.Power

				local a0 = Instance.new("Attachment", self.Character.Root)
				local a1 = Instance.new("Attachment", character.Root)
				local beam = self.Storage.Models.EmpoweringBeam:Clone()
				beam.Attachment0 = a0
				beam.Attachment1 = a1
				beam.Parent = self.Character.Model

				return {Beam = beam, A0 = a0, A1 = a1}
			end,

			OnUnaffected = function(self, character, data)
				character.Power.Base -= self.Power
				data.Beam:Destroy()
				data.A0:Destroy()
				data.A1:Destroy()
			end,
		}
	},

	{
		Name = "Restorative",
		Type = "Status",
		Args = {
			Interval = 5,

			RangeSq = 32 ^ 2,

			Heal = function(self, character, dt)
				local amount = self.Character.Level

				self:GetService("DamageService"):Heal{
					Source = self.Character,
					Target = character,
					Amount = amount,
				}

				local a0 = Instance.new("Attachment", self.Character.Root)
				local a1 = Instance.new("Attachment", character.Root)
				local beam = self.Storage.Models.RestorativeBeam:Clone()
				beam.Attachment0 = a0
				beam.Attachment1 = a1
				beam.Parent = self.Character.Model

				self.Character:SoundPlayByObject(self.Storage.Sounds.Heal1)

				delay(1, function()
					beam:Destroy()
					a0:Destroy()
					a1:Destroy()
				end)
			end,

			OnTicked = function(self, dt)
				local enemies = self:GetClass("Enemy").Instances
				for _, enemy in pairs(enemies) do
					if enemy ~= self.Character then
						local delta = enemy:GetPosition() - self.Character:GetPosition()
						if (delta.X ^ 2 + delta.Z ^ 2) < self.RangeSq then
							self:Heal(enemy, dt)
						end
					end
				end
			end,
		}
	}
}