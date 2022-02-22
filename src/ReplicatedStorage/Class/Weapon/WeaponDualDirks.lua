local Super = require(script.Parent)
local WeaponDualDirks = Super:Extend()

WeaponDualDirks.PrimaryStatName = "Agility"

WeaponDualDirks.Range = 10
WeaponDualDirks.DisplayName = "Dual Dirks"
WeaponDualDirks.DescriptionLight = "Stab enemies. Consecutive attacks are quicker."
WeaponDualDirks.DescriptionHeavy = "Briefly increase movement speed."

WeaponDualDirks.CooldownLightTime = 1
WeaponDualDirks.CooldownLightTimeMin = 0.25

WeaponDualDirks.ReductionAttackRequirement = 10
WeaponDualDirks.ReductionAttackCount = 0

WeaponDualDirks.CooldownHeavyTime = 2

WeaponDualDirks.DamageType = "Piercing"

function WeaponDualDirks:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
	
	self.ReductionCooldown = self:CreateNew"Cooldown"{Time = 5}
end

function WeaponDualDirks:GetDamage()
	return Super.GetDamage(self) * 3/4
end

function WeaponDualDirks:OnUpdated(dt)
	if self.ReductionCooldown:IsReady() then
		self.ReductionAttackCount = 0
	end
end

function WeaponDualDirks:GetCooldownLightTime()
	local weight = self.ReductionAttackCount / self.ReductionAttackRequirement
	return self:Lerp(self.CooldownLightTime, self.CooldownLightTimeMin, weight)
end

function WeaponDualDirks:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	
	self.CooldownHeavy:Use()
	
	local duration = 1
	self.CooldownLight:UseMinimum(0.25)
	self:ChangeLegendSpeed(1, duration, {
		Category = "Good",
		ImagePlaceholder = "DIRK\nSPD",
	})
	
	self.Legend:SoundPlay("AdrenalineRush")
	self:GetService("EffectsService"):RequestEffectAll("Shockwave", {
		Duration = 0.15,
		CFrame = CFrame.new(self.Legend:GetFootPosition()),
		EndSize = Vector3.new(16, 1, 16),
		StartSize = Vector3.new(0, 1, 0),
		PartArgs = {
			Color = Color3.new(1, 1, 1)
		},
	})

	return true
end

function WeaponDualDirks:GetFlurryAnimation(number)
	return "DirksAttack"..number, 0
end

function WeaponDualDirks:SetTrailsEnabled()
	-- haven't got any
end

function WeaponDualDirks:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	
	local t = self:GetCooldownLightTime()
	self.CooldownLight:Use(t)
	
	self:AttackSound()
	self.Legend:AnimationStop("DirksAttack"..self.AttackNumber, 0)
	self.AttackNumber = (self.AttackNumber + 1) % 2
	self.Legend:AnimationPlay("DirksAttack"..self.AttackNumber, 0)

	local didAttack = false

	self.Targeting:TargetMelee(self.Targeting:GetEnemies(), {
		CFrame = self.Legend:GetAimCFrame(),
		Width = 10,
		Length = 10,
		Callback = function(enemy)
			local damage = self:GetService"DamageService":Damage{
				Source = self.Legend,
				Target = enemy,
				Amount = self:GetDamage(),
				Weapon = self,
				Type = self.DamageType,
			}

			self:HitEffects(enemy)

			didAttack = true
		end
	})

	if didAttack then
		self.Attacked:Fire()
		
		self.ReductionAttackCount = math.min(self.ReductionAttackCount + 1, self.ReductionAttackRequirement)
		self.ReductionCooldown:Use()
	end

	return true
end

function WeaponDualDirks:AddParts()
	local left = self.Assets.DirkLeft:Clone()
	left.Parent = self.Legend.Model
	left.Weld.Part0 = self.Legend.Model.RightHand
	left.Weld.Part1 = left
	self.DirkLeft = left

	local right = self.Assets.DirkRight:Clone()
	right.Parent = self.Legend.Model
	right.Weld.Part0 = self.Legend.Model.LeftHand
	right.Weld.Part1 = right
	self.DirkRight = right
end

function WeaponDualDirks:ClearParts()
	self:ClearPartsHelper(self.DirkLeft, self.DirkRight)
end

function WeaponDualDirks:Equip()
	self:Unsheath()
end

function WeaponDualDirks:Unequip()
	self:ClearParts()
end

function WeaponDualDirks:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.DirkLeft.Weld, self.Legend.Model.LowerTorso,
		CFrame.new(1, 0, 0),
		CFrame.Angles(-math.pi * 3 / 4, 0, 0)
	)
	
	self:RebaseWeld(self.DirkRight.Weld, self.Legend.Model.LowerTorso,
		CFrame.new(-1, 0, 0),
		CFrame.Angles(-math.pi * 3 / 4, 0, 0)
	)
	
	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponDualDirks:Unsheath()
	self:ClearParts()
	self:AddParts()
	
	self.Legend:SetRunAnimation("DualWield")
end

return WeaponDualDirks