local Super = require(script.Parent)
local WeaponSwordAndShield = Super:Extend()

WeaponSwordAndShield.Range = 10
WeaponSwordAndShield.DisplayName = "Sword & Shield"
WeaponSwordAndShield.DescriptionLight = "Slash enemies."
WeaponSwordAndShield.DescriptionHeavy = "Ram through enemies with shield."
WeaponSwordAndShield.DescriptionPassive = function(self)
	return string.format("Block up to %d damage. Restore block after a short cooldown by striking enemies.", self:GetBlockFromLevel())
end

WeaponSwordAndShield.BlockPerHit = 0.1
WeaponSwordAndShield.BlockPerEnemy = WeaponSwordAndShield.BlockPerHit * 5

WeaponSwordAndShield.CooldownLightTime = 0.4
WeaponSwordAndShield.CooldownHeavyTime = 5

function WeaponSwordAndShield:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
	
	self.BlockMax = self:GetBlockFromLevel()
	
	self.Block = math.min(self.BlockMax, self.Legend.WeaponSwordAndShieldBlock or self.BlockMax)
	
	self.BlockCooldown = self:CreateNew"Cooldown"{Time = 3}
	self.BlockCooldown:Use()
	
	self.BlockSoundCooldown = self:CreateNew"Cooldown"{Time = 1}
end

function WeaponSwordAndShield:GetBlockFromLevel()
	local block = 10 + (self:GetLevel() * 1.5) + (self:GetStatValue("Strength") * 0.5)
	
	if self:HasModifier("Sturdy") then
		block *= 1.25
	end
	
	return block
end

function WeaponSwordAndShield:GetDescription(level, itemData)
	return string.format("%s\n🛡️ %4.1f", Super.GetDescription(self, level, itemData, false), self:GetBlockFromLevel(level, itemData)).."\n"..self:GetMechanicsDescription(itemData)
end

function WeaponSwordAndShield:OnWillTakeDamage(damage)
	if damage.Unblockable then return end
	
	if self.OnWillBlockDamage then
		self:OnWillBlockDamage(damage)
	end
	
	local block = math.min(damage.Amount, self.Block)
	
	damage.Amount = damage.Amount - block
	self.Block = self.Block - block
	
	-- play sound but only once in a while
	if self.BlockSoundCooldown:IsReady() then
		self.BlockSoundCooldown:Use()
		self.Legend:SoundPlayByObject(self.Assets.Sounds.Block)
	end
	
	self.BlockCooldown:Use()
end

function WeaponSwordAndShield:UpdateBlock()
	local blockMax = self:GetBlockFromLevel()
	if self.BlockMax == blockMax then return end

	local ratio = self.Block / self.BlockMax
	self.BlockMax = blockMax
	self.Block = self.BlockMax * ratio
end

function WeaponSwordAndShield:OnUpdated(dt)
	if self.CustomOnUpdated then
		self:CustomOnUpdated(dt)
	end
	
	self:UpdateBlock()

	self:FireRemote("BlockUpdated", self.Legend.Player, {Type = "Update", Ratio = math.min(1, self.Block / self.BlockMax), Block = self.Block, BlockMax = self.BlockMax})
end

function WeaponSwordAndShield:AttackHeavy()
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
	self.Legend:AnimationPlay("SwordShieldAttackHeavy")
	self.Legend:SoundPlay("AdrenalineRush")
	
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
					Type = "Bludgeoning",
				}
				
				enemy:SoundPlayByObject(self.Assets.Sounds.Bash)
				self:HitEffects(enemy, false)
			end)
		end
	})
	
	self:GetService("EffectsService"):RequestEffectAll("ForceWave", {
		Duration = 0.25,
		Root = self.Legend.Root,
		CFrame = self.Legend:GetAimCFrame(),
		StartSize = Vector3.new(4, 4, 8),
		EndSize = Vector3.new(5, 5, 10),
		PartArgs = {
			Color = Color3.new(1, 1, 1),
			Transparency = 0.5,
		}
	})
	
	local stopEthereality = self.Legend:StartTemporaryEthereality()
	
	delay(duration, function()
		stopEthereality()
		
		mover:Destroy()
		self.Legend.Root.Velocity = Vector3.new()
		self.Legend:AnimationStop("SwordShieldAttackHeavy")
	end)

	return true
end

function WeaponSwordAndShield:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:UseMinimum(self.CooldownLight.Time)
	
	self:AttackSound()
	self.Legend:AnimationPlay("SwordShieldAttackLight"..self.AttackNumber, 0)
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

			local ratio = damage.Amount / enemy.MaxHealth:Get()
			local blockRestored = math.max(self.BlockPerHit, self.BlockPerEnemy * ratio) * self.BlockMax
			if self.BlockCooldown:IsReady() then
				self.Block = math.min(self.BlockMax, self.Block + blockRestored)
			end

			self:HitEffects(enemy)
			
			didAttack = true
		end
	})
	
	if didAttack then
		self.Attacked:Fire()
	end
	
	return true
end

function WeaponSwordAndShield:ClearParts()
	self:ClearPartsHelper(self.Sword, self.Shield)
end

function WeaponSwordAndShield:AddParts()
	local sword = self.Assets.Sword:Clone()
	sword.Parent = self.Legend.Model
	sword.Weld.Part0 = self.Legend.Model.RightHand
	sword.Weld.Part1 = sword
	self.Sword = sword

	local shield = self.Assets.Shield:Clone()
	shield.Parent = self.Legend.Model
	shield.Weld.Part0 = self.Legend.Model.LeftHand
	shield.Weld.Part1 = shield
	self.Shield = shield
end

function WeaponSwordAndShield:Equip()
	self:Unsheath()
	
	self:FireRemote("BlockUpdated", self.Legend.Player, {Type = "Show"})
end

function WeaponSwordAndShield:Unequip()
	self.Legend.WeaponSwordAndShieldBlock = self.Block
	
	self:ClearParts()
	
	self:FireRemote("BlockUpdated", self.Legend.Player, {Type = "Hide"})
end

function WeaponSwordAndShield:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Sword.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0, 0, 1),
		CFrame.Angles(0, 0, math.pi / 4),
		CFrame.Angles(0, math.pi / 2, 0)
	)
	
	self:RebaseWeld(self.Shield.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0, 0, 1.5),
		CFrame.Angles(0, 0, -math.pi / 2),
		CFrame.Angles(0, math.pi / 2, 0)
	)
	
	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponSwordAndShield:Unsheath()
	self:ClearParts()
	self:AddParts()

	self.Legend:SetRunAnimation("SwordShield")
end

return WeaponSwordAndShield