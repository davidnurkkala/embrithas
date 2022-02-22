local Super = require(script.Parent)
local WeaponSabers = Super:Extend()

WeaponSabers.PrimaryStatName = "Agility"

WeaponSabers.Range = 10
WeaponSabers.DisplayName = "Dual Sabers"
WeaponSabers.DescriptionLight = "Slash enemies. Use both swords every third strike to deal double damage."
WeaponSabers.DescriptionHeavy = "ALL SABERS HAVE UNIQUE HEAVY ATTACKS. IF YOU ARE SEEING THIS, DAVIDII FORGOT TO WRITE ONE FOR THIS SABER."

WeaponSabers.CooldownLightTime = 0.4
WeaponSabers.CooldownHeavyTime = 1

WeaponSabers.DamageType = "Slashing"

function WeaponSabers:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
end

function WeaponSabers:HitEnemy(enemy, damage)
	self:GetService"DamageService":Damage{
		Source = self.Legend,
		Target = enemy,
		Amount = damage,
		Weapon = self,
		Type = self.DamageType,
	}
	
	self:HitEffects(enemy)
end

function WeaponSabers:GetFlurryAnimation(number)
	return "SaberAttackLight"..number, 0, nil, 2.5
end

function WeaponSabers:SetTrailsEnabled(enabled)
	self.Left.Trail.Enabled = enabled
	self.Right.Trail.Enabled = enabled
end

function WeaponSabers:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:UseMinimum(self.CooldownLight.Time)
	
	self:AttackSound()
	self.Legend:AnimationPlay("SaberAttackLight"..self.AttackNumber, 0)
	
	local damage = self:GetDamage()
	local isDualHit = (self.AttackNumber == 2)
	if isDualHit then
		damage *= 2
	end
	
	self.AttackNumber = (self.AttackNumber + 1) % 3
	
	local didAttack = false
	local function callback(enemy)
		if isDualHit then
			if self.OnDualHitEnemy then
				self:OnDualHitEnemy(enemy)
			end
		end

		self:HitEnemy(enemy, damage)

		didAttack = true
	end
	
	self.Targeting:TargetCone(self.Targeting:GetEnemies(), {
		CFrame = self.Legend:GetAimCFrame(),
		Angle = 90,
		Range = 12,
		Callback = callback,
	})
	
	if didAttack then
		self.Attacked:Fire()
	end

	return true
end

function WeaponSabers:AddParts()
	local right = self.Assets.SaberRight:Clone()
	right.Parent = self.Legend.Model
	right.Weld.Part0 = self.Legend.Model.RightHand
	right.Weld.Part1 = right
	self.Right = right

	local left = self.Assets.SaberLeft:Clone()
	left.Parent = self.Legend.Model
	left.Weld.Part0 = self.Legend.Model.LeftHand
	left.Weld.Part1 = left
	self.Left = left
end

function WeaponSabers:ClearParts()
	self:ClearPartsHelper(self.Right, self.Left)
end

function WeaponSabers:Equip()
	self:Unsheath()
	
	if self.OnEquip then
		self:OnEquip()
	end
end

function WeaponSabers:Unequip()
	self:ClearParts()
	
	if self.OnUnequip then
		self:OnUnequip()
	end
end

function WeaponSabers:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Left.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0, -0.5, 0.75),
		CFrame.Angles(0, 0, math.pi / 4),
		CFrame.Angles(0, math.pi / 2, 0)
	)

	self:RebaseWeld(self.Right.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0, -0.5, 0.75),
		CFrame.Angles(0, 0, math.pi * 3 / 4),
		CFrame.Angles(0, math.pi / 2, 0),
		CFrame.Angles(0, 0, math.pi)
	)
	
	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponSabers:Unsheath()
	self:ClearParts()
	self:AddParts()
	
	self.Legend:SetRunAnimation("DualWield")
end

return WeaponSabers