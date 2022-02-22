local Super = require(script.Parent)
local WeaponAxeAndBuckler = Super:Extend()

WeaponAxeAndBuckler.Range = 10
WeaponAxeAndBuckler.DisplayName = "Axe & Buckler"
WeaponAxeAndBuckler.DescriptionLight = "Chop enemies."
WeaponAxeAndBuckler.DescriptionHeavy = "Throw buckler to deal damage. Cannot parry while buckler is in flight."
WeaponAxeAndBuckler.DescriptionPassive = function(self)
	return string.format("Parry up to %d hits, blocking all damage. Restore parries by slaying enemies.", self:GetParriesMax())
end

WeaponAxeAndBuckler.BaseParriesMax = 2

WeaponAxeAndBuckler.CooldownLightTime = 0.6
WeaponAxeAndBuckler.CooldownHeavyTime = 2

WeaponAxeAndBuckler.BucklerAvailable = true

WeaponAxeAndBuckler.ParryCooldownStatusType = "WeaponAxeAndBucklerParryCooldown"

function WeaponAxeAndBuckler:OnCreated()
	self.Parried = self:CreateNew"Event"()
	
	Super.OnCreated(self)
	
	self.AttackNumber = 0
	
	self:SetParriesMax(self:GetParriesMax())
	self.Parries = math.min(self.ParriesMax, self.Legend.WeaponAxeAndBucklerParries or self.ParriesMax)
end

function WeaponAxeAndBuckler:GetParriesMax()
	local bonusParries = (self:GetStatValue("Agility") ^ 0.66) / 20
	if self:HasModifier("Sturdy") then
		bonusParries += 1
	end
	return self.BaseParriesMax + bonusParries
end

function WeaponAxeAndBuckler:OnWillTakeDamage(damage)
	if damage.Unblockable then return end
	if not self.BucklerAvailable then return end
	if self.Legend:HasStatusType(self.ParryCooldownStatusType) then return end
	
	if self.Parries > 0 then
		self:ChangeParries(-1)
		damage.Amount = 0
		
		self.Legend:SoundPlayByObject(self.Assets.Sounds.Parry)
		
		if self.OnParried then
			self:OnParried(damage)
		end
		
		self.Legend:AddStatus("Status", {
			Time = 3,
			Type = self.ParryCooldownStatusType,
			
			ImagePlaceholder = "PARRY\nCD",
		})
	end
end

function WeaponAxeAndBuckler:ReplicateParries()
	self:FireRemote("AmmoUpdated", self.Legend.Player, {
		Type = "Update",
		Ammo = self.Parries,
		AmmoMax = self.ParriesMax,
		AmmoType = "Parries",
		AmmoImage = "rbxassetid://5052452382",
	})
end

function WeaponAxeAndBuckler:ChangeParries(delta)
	self.Parries = math.clamp(self.Parries + delta, 0, self.ParriesMax)
	self:ReplicateParries()
end

function WeaponAxeAndBuckler:SetParriesMax(parriesMax)
	if self.ParriesMax == parriesMax then return end
	
	self.ParriesMax = parriesMax
	self.Parries = math.clamp(self.Parries or 0, 0, self.ParriesMax)
	self:ReplicateParries()
end

function WeaponAxeAndBuckler:OnDealtDamage(damage)
	if self.CustomOnDealtDamage then
		self:CustomOnDealtDamage(damage)
	end
	
	if (self.Parries < self.ParriesMax) and (damage.Target.Health <= 0) then
		self:ChangeParries(1)
	end
end

function WeaponAxeAndBuckler:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:UseMinimum(self.CooldownLight.Time)

	self:AttackSound()
	self.Legend:AnimationPlay("AxeAttackLight"..self.AttackNumber, 0)
	self.AttackNumber = (self.AttackNumber + 1) % 2

	local didAttack = false

	self.Targeting:TargetCone(self.Targeting:GetEnemies(), {
		CFrame = self.Legend:GetAimCFrame(),
		Angle = 110,
		Range = 13,
		Callback = function(enemy)
			local damage = self:GetService"DamageService":Damage{
				Source = self.Legend,
				Target = enemy,
				Amount = self:GetDamage(),
				Weapon = self,
				Type = "Slashing",
			}

			self:HitEffects(enemy)

			didAttack = true
		end
	})

	if didAttack then
		self.Attacked:Fire()
	end

	return true
end

function WeaponAxeAndBuckler:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	self.CooldownHeavy:Use()
	self.CooldownLight:Use()
	
	self.Legend:AnimationPlay("AxeAttackHeavy")
	self:AttackSound()
	
	local model = Instance.new("Model")
	
	local cframe = self.Legend:GetAimCFrame()
	local speed = 64
	local velocity = (cframe.LookVector * Vector3.new(1, 0, 1)).Unit * speed
	
	local model = Instance.new("Model")
	model.Name = "ThrownBuckler"
	
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = Vector3.new()
	p.Transparency = 1
	p.CanCollide = false
	p.CFrame = cframe
	p.Parent = model
	
	local left = Instance.new("Attachment")
	left.Position = Vector3.new(0, -0.5, 0)
	left.Parent = p
	
	local right = Instance.new("Attachment")
	right.Position = Vector3.new(0, 0.5, 0)
	right.Parent = p
	
	local trail = self.Assets.Axe.Trail:Clone()
	trail.Attachment0 = left
	trail.Attachment1 = right
	trail.Enabled = true
	trail.Parent = p
	
	local buckler = self.Assets.Buckler:Clone()
	buckler.Weld.Part1 = buckler
	buckler.Weld.Part0 = p
	buckler.Parent = model
	
	local cleanup = self.Storage.Scripts.EmptyCleanupScript:Clone()
	cleanup.Name = "CleanupScript"
	cleanup.Parent = model
	
	model.PrimaryPart = p
	model.Parent = workspace.Effects
	
	self:SetBucklerHidden(true)
	
	local projectile = self:CreateNew"Projectile"{
		Model = model,
		CFrame = cframe,
		Velocity = velocity,
		FaceTowardsVelocity = true,
		Range = 64,
		
		GetOffset = function(p)
			return CFrame.Angles(0, 0, -math.pi / 2)
		end,
		
		ShouldIgnoreFunc = function(part)
			if game:GetService("CollectionService"):HasTag(part, "InvisibleWall") then return true end
		end,
		OnHitPart = function(projectile, part)
			if not part:IsDescendantOf(workspace:FindFirstChild("Dungeon")) then return end

			projectile:Deactivate()
			return true
		end,
		OnTicked = function(projectile, dt)
			local targets = self.Targeting:TargetWideProjectile(self.Targeting:GetEnemies(), {
				Projectile = projectile,
				Width = 6,
			})
			local enemy = targets[1]
			if enemy then
				self:GetService"DamageService":Damage{
					Source = self.Legend,
					Target = enemy,
					Amount = self:GetDamage() * 1.5,
					Weapon = self,
					Type = "Bludgeoning",
				}

				self:HitEffects(enemy, false)
				
				projectile:Deactivate()
			end
		end,
		
		-- A11Noob was here 12/11/2020
		OnEnded = function(p)
			local model = p.Model
			model.Parent = self.Storage.Temp
			game:GetService("Debris"):AddItem(model, 10)
			
			local position = model:GetPrimaryPartCFrame().Position
			local duration = 0.5
			
			self:GetService("EffectsService"):RequestEffectAll("LobProjectile", {
				Model = model,
				Start = position,
				Finish = self.Legend.Model.LeftHand,
				Height = 16,
				Duration = duration,
				FadeDuration = 0,
			})
			self:GetService("EffectsService"):RequestEffectAll("Sound", {
				Position = position,
				Sound = self.Assets.Sounds.Bash,
			})
			
			delay(duration, function()
				self:SetBucklerHidden(false)
			end)
		end,
	}
	self:GetWorld():AddObject(projectile)
	
	return true
end

function WeaponAxeAndBuckler:SetBucklerHidden(state)
	if state then
		self.BucklerAvailable = false
		self.Buckler.Transparency = 1
	else
		self.BucklerAvailable = true
		self.Buckler.Transparency = 0
	end
end

function WeaponAxeAndBuckler:OnUpdated()
	self:SetParriesMax(self:GetParriesMax())
end

function WeaponAxeAndBuckler:ClearParts()
	self:ClearPartsHelper(self.Axe, self.Buckler)
end

function WeaponAxeAndBuckler:AddParts()
	local axe = self.Assets.Axe:Clone()
	axe.Parent = self.Legend.Model
	axe.Weld.Part0 = self.Legend.Model.RightHand
	axe.Weld.Part1 = axe
	self.Axe = axe

	local buckler = self.Assets.Buckler:Clone()
	buckler.Parent = self.Legend.Model
	buckler.Weld.Part0 = self.Legend.Model.LeftHand
	buckler.Weld.Part1 = buckler
	self.Buckler = buckler
end

function WeaponAxeAndBuckler:Equip()
	self:Unsheath()
	
	self:FireRemote("AmmoUpdated", self.Legend.Player, {Type = "Show"})
	self:ChangeParries(0)
end

function WeaponAxeAndBuckler:Unequip()
	self:ClearParts()
	
	self.Legend.WeaponAxeAndBucklerParries = self.Parries

	self:FireRemote("AmmoUpdated", self.Legend.Player, {Type = "Hide"})
end

function WeaponAxeAndBuckler:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Axe.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0, 0, 1),
		CFrame.Angles(0, 0, math.pi / 4),
		CFrame.Angles(0, math.pi / 2, 0)
	)
	
	self:RebaseWeld(self.Buckler.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0, 0, 1.5),
		CFrame.Angles(0, 0, -math.pi / 2),
		CFrame.Angles(0, math.pi / 2, 0)
	)
	
	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponAxeAndBuckler:Unsheath()
	self:ClearParts()
	self:AddParts()

	self.Legend:SetRunAnimation("SwordShield")
end

return WeaponAxeAndBuckler