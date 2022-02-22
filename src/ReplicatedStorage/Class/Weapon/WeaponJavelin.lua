local Super = require(script.Parent)
local WeaponJavelin = Super:Extend()

WeaponJavelin.PrimaryStatName = "Agility"

WeaponJavelin.Range = 10
WeaponJavelin.ThrowRange = 32
WeaponJavelin.DisplayName = "Javelin"
WeaponJavelin.DescriptionLight = "Pierce enemies."
WeaponJavelin.DescriptionHeavy = "Either throw or retrieve javelin. A javelin that has traveled a long distance deals triple damage."
WeaponJavelin.DescriptionPassive = "Thrown javelins lodge into their targets. Retrieving a javelin from a living target deals damage. Without a javelin, you can only punch."

WeaponJavelin.CooldownLightTime = 0.75
WeaponJavelin.CooldownHeavyTime = 1

WeaponJavelin.Length = 16
WeaponJavelin.Width = 3

WeaponJavelin.ImpaleDamage = 2
WeaponJavelin.PullDamage = 2

WeaponJavelin.JavelinState = true

WeaponJavelin.BuffStatusType = "WeaponJavelinThrowBuff"

function WeaponJavelin:OnCreated()
	Super.OnCreated(self)
end

function WeaponJavelin:SetJavelinState(state)
	if self.JavelinState == state then return end
	self.JavelinState = state
	
	if state then
		self.Javelin.Transparency = 0
		self:RemoveImpaledJavelin()
		
		self.Legend:SetRunAnimation("SingleWeapon")
	else
		self.Javelin.Transparency = 1
		
		self.Legend:SetRunAnimation("NoWeapons")
	end
end

function WeaponJavelin:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	
	self.CooldownLight:Use()
	self.CooldownHeavy:UseMinimum(self.CooldownLight.Time)
	
	if self.JavelinState then
		self:AttackSound()
		self.Legend:AnimationPlay("SpearAttackLight", 0)

		local length = 16
		local width = 5
		local cframe = self.Legend:GetAimCFrame() * CFrame.new(0, 0, -length / 2)

		self:GetService("EffectsService"):RequestEffectAll("Pierce", {
			CFrame = cframe,
			Tilt = 4,
			Length = length,
			Width = width - 2,
			Duration = 0.1,
		})

		local didAttack = false

		self.Targeting:TargetSquare(self.Targeting:GetEnemies(), {
			CFrame = cframe,
			Length = length,
			Width = width,
			Callback = function(enemy)
				self:GetService"DamageService":Damage{
					Source = self.Legend,
					Target = enemy,
					Amount = self:GetDamage(),
					Weapon = self,
					Type = "Piercing",
				}

				self:HitEffects(enemy)

				didAttack = true
			end,
		})

		if didAttack then
			self.Attacked:Fire()
		end
	else
		self:AttackSound()
		self.Legend:AnimationPlay("PunchRight", 0)

		local didAttack = false

		self.Targeting:TargetMelee(self.Targeting:GetEnemies(), {
			CFrame = self.Legend:GetAimCFrame(),
			Width = 6,
			Length = 10,
			Callback = function(enemy)
				local damage = self:GetService"DamageService":Damage{
					Source = self.Legend,
					Target = enemy,
					Amount = self:GetDamage() * 0.25,
					Weapon = self,
					Type = "Bludgeoning",
				}

				self:HitEffects(enemy, false)
				enemy:SoundPlay("Bash")

				didAttack = true
			end
		})

		if didAttack then
			self.Attacked:Fire()
		end
	end

	return true
end

function WeaponJavelin:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	
	self.CooldownHeavy:Use()
	self.CooldownLight:Use()
	
	-- throwing javelin
	if self.JavelinState then
		-- shorter cooldown on throw
		self.CooldownHeavy:Use(0.5)
		
		self:AttackSound()
		
		self.Legend:AnimationPlay("JavelinThrow", 0)
		
		-- construct the projectile model
		local model = Instance.new("Model")
		model.Name = "ThrownJavelin"
		
		local root = self.Assets.Javelin:Clone()
		root.Anchored = true
		root.CanCollide = false
		root.Parent = model
		
		local offset = root.RotationOffset.Value
		
		model.PrimaryPart = root
		
		-- function for javelin sticking
		local function lodgeJavelin(projectile, part)
			local fake = self.Assets.Javelin:Clone()
			fake.CFrame = projectile.Model:GetPrimaryPartCFrame()
			
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = part
			weld.Part1 = fake
			weld.Parent = fake
			
			fake.Parent = workspace.Effects
			
			self:GetService("EffectsService"):RequestEffect(self.Legend.Player, "AddJavelinEmitter", {
				Javelin = fake,
			})
			
			local enemy = self:GetClass("Enemy").GetEnemyFromPart(part)
			if enemy then
				self.Victim = enemy
				
				local connection
				connection = enemy.Died:Connect(function()
					connection:Disconnect()
					
					weld:Destroy()
					fake.Anchored = true
				end)
			end
			
			self.ImpaledJavelin = fake
			
			game:GetService("Debris"):AddItem(fake, 10)
		end
		
		local function shockwave(cframe, size)
			self:GetService("EffectsService"):RequestEffectAll("Shockwave", {
				Duration = 0.5,
				CFrame = cframe,
				StartSize = Vector3.new(0, 0, 0),
				EndSize = size,
				PartArgs = {
					Color = Color3.new(1, 1, 1)
				},
			})
		end
		
		-- fire the projectile
		self.Projectile = self:CreateGenericProjectile{
			Model = model,
			CFrame = self.Legend:GetAimCFrame(),
			Speed = 192,
			Width = 4,
			
			Args = {
				Empowered = false,
				EmpoweredEffectCooldown = self:CreateNew"Cooldown"{Time = 0.1},
			},
			
			OnTicked = function(projectile, dt)
				if projectile.Empowered then
					if projectile.EmpoweredEffectCooldown:IsReady() then
						projectile.EmpoweredEffectCooldown:Use()
						
						shockwave(projectile.CFrame * CFrame.Angles(math.pi / 2, 0, 0), Vector3.new(4, 0.25, 4))
					end
				else
					if projectile.DistanceTraversed >= 32 then
						projectile.Empowered = true
						
						shockwave(projectile.CFrame * CFrame.Angles(math.pi / 2, 0, 0), Vector3.new(12, 1, 12))
						
						self:GetService("EffectsService"):RequestEffectAll("Sound", {
							Sound = self.Storage.Sounds.AdrenalineRush,
							Position = projectile.CFrame.Position,
						})
					end
				end
			end,
			OnHitTarget = function(target, projectile)
				lodgeJavelin(projectile, target.Root)
				
				local damage = self.ImpaleDamage
				
				if projectile.Empowered then
					damage *= 2
					
					shockwave(CFrame.new(target:GetFootPosition()), Vector3.new(12, 4, 12))
					target:SoundPlayByObject(self.Storage.Sounds.HeavyJavelinHit)
				end
				
				local status = self.Legend:GetStatusByType(self.BuffStatusType)
				if status then
					damage *= 1 + status:GetBuff()
					status:AddStack()
				else
					self.Legend:AddStatus("Status", {
						Type = self.BuffStatusType,
						Infinite = true,
						Stacks = 0,

						Category = "Good",
						ImagePlaceholder = "JVLN\nSTREAK",

						AddStack = function(status)
							status.Stacks += 1
							status.ExtraInfo = string.format("%d%%", status:GetBuff() * 100)
						end,

						GetBuff = function(status)
							return 0.4 * status.Stacks ^ 0.5
						end,
					}):AddStack()
				end
				
				self:GetService("DamageService"):Damage{
					Source = self.Legend,
					Target = target,
					Amount = self:GetDamage() * damage,
					Weapon = self,
					Type = "Piercing",
				}
				
				self:HitEffects(self.Victim)
				
				if self.OnThrownJavelinHitEnemy then
					self:OnThrownJavelinHitEnemy(target)
				end
				
				if target:IsDead() then
					self:SetJavelinState(true)
				end
			end,
			OnHitPart = function(part, projectile)
				local status = self.Legend:GetStatusByType(self.BuffStatusType)
				if status then
					status:Stop()
				end
				lodgeJavelin(projectile, part)
			end,
			GetOffset = function()
				return CFrame.Angles(math.rad(offset.X), math.rad(offset.Y), math.rad(offset.Z))
			end
		}
		
		-- handle javelin state
		self:SetJavelinState(false)
		
	-- attempting to yank javelin out
	-- tothetix was here 2/3/2021
	else
		-- just in case
		local inFlight = (self.Projectile and self.Projectile.Active)
		if inFlight then return end
		
		local javelin = self.ImpaledJavelin
		local isMissing = (not javelin) or (not javelin:IsDescendantOf(workspace)) 
		if isMissing then
			self.Legend:AnimationPlay("StaffCast", 0)
			self:SetJavelinState(true)
			return
		end
		if not self.Legend:IsPointInRange(javelin.Position, 8) then
			self.CooldownHeavy:Use(0)
			return
		end
		
		self:FireRemote("FacePartCalled", self.Legend.Player, javelin, 0.25)
		self.Legend:AnimationPlay("JavelinPull", 0)
		
		self:SetJavelinState(true)
		
		if self.Victim and self.Victim.Active then
			self:GetService("DamageService"):Damage{
				Source = self.Legend,
				Target = self.Victim,
				Amount = self:GetDamage() * self.PullDamage,
				Weapon = self,
				Type = "Piercing",
			}
			
			self:HitEffects(self.Victim)
		end
		
		self.Victim = nil
	end

	return true
end

function WeaponJavelin:RemoveImpaledJavelin()
	if self.ImpaledJavelin then
		self.ImpaledJavelin:Destroy()
		self.ImpaledJavelin = nil
	end
end

function WeaponJavelin:AddParts()
	local javelin = self.Assets.Javelin:Clone()
	javelin.Parent = self.Legend.Model
	javelin.Motor.Part0 = self.Legend.Model.RightHand
	javelin.Motor.Part1 = javelin
	self.Javelin = javelin
end

function WeaponJavelin:ClearParts()
	self:ClearPartsHelper(self.Javelin)
end

function WeaponJavelin:Equip()
	self:Unsheath()
	
	if self.Legend.WeaponJavelinState ~= nil then
		self:SetJavelinState(self.Legend.WeaponJavelinState)
	else
		self:SetJavelinState(true)
	end
	
	local victim = self.Legend.WeaponJavelinVictim
	if (victim ~= nil) and victim.Active then
		self.Victim = victim
	end
	
	local impaledJavelin = self.Legend.WeaponJavelinImpaledJavelin
	if impaledJavelin then
		self.ImpaledJavelin = impaledJavelin
	end
end

function WeaponJavelin:Unequip()
	self:ClearParts()
	
	self.Legend.WeaponJavelinState = self.JavelinState
	self.Legend.WeaponJavelinVictim = self.Victim
	self.Legend.WeaponJavelinImpaledJavelin = self.ImpaledJavelin
end

function WeaponJavelin:Sheath()
	if not self.JavelinState then return end
	
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Javelin.Motor, self.Legend.Model.UpperTorso,
		CFrame.new(0, 0, 1),
		CFrame.Angles(0, 0, math.pi / 4),
		CFrame.Angles(0, math.pi / 2, 0)
	)

	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponJavelin:Unsheath()
	if not self.JavelinState then return end
	
	self:ClearParts()
	self:AddParts()
	
	self.Legend:SetRunAnimation("SingleWeapon")
end

return WeaponJavelin