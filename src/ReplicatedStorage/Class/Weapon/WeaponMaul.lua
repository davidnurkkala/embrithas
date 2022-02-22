local Super = require(script.Parent)
local WeaponMaul = Super:Extend()

WeaponMaul.Range = 10
WeaponMaul.BaseRadius = 14
WeaponMaul.AttackHeavyDamageMultiplier = 2
WeaponMaul.DisplayName = "Maul"
WeaponMaul.DescriptionLight = "Smash enemies."
WeaponMaul.DescriptionHeavy = function(self)
	return string.format("Slam the ground, sending out a damaging %d foot shockwave.", self:GetRadius())
end

WeaponMaul.CooldownLightTime = 0.8
WeaponMaul.CooldownHeavyTime = 2

function WeaponMaul:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
	
	self.Radius = self:CreateNew"Stat"{Base = self.BaseRadius}
end

function WeaponMaul:GetEnemies()
	return self:GetService("TargetingService"):GetEnemies()
end

function WeaponMaul:GetTargets(position)
	local here = position
	local range = self.Radius:Get()
	
	local targets = {}
	local enemies = self:GetEnemies()
	for _, enemy in pairs(enemies) do
		local delta = (enemy:GetPosition() - here)
		local distance = math.sqrt(delta.X ^ 2 + delta.Z ^ 2)
		if distance <= range then
			table.insert(targets, enemy)
		end
	end
	
	return targets
end

function WeaponMaul:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:UseMinimum(self.CooldownLight.Time)

	self:AttackSound()
	self.Legend:AnimationPlay("MaulAttackLight"..self.AttackNumber, 0)
	self.AttackNumber = (self.AttackNumber + 1) % 2

	local didAttack = false

	self.Targeting:TargetCone(self.Targeting:GetEnemies(), {
		CFrame = self.Legend:GetAimCFrame(),
		Angle = 110,
		Range = 14,
		Callback = function(enemy)
			self:HitEnemy(enemy, 1)

			didAttack = true
		end
	})

	if didAttack then
		self.Attacked:Fire()
	end

	return true
end

function WeaponMaul:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	self.CooldownHeavy:Use()
	self.CooldownLight:Use()
	
	self:AttackSound()
	self.Legend:AnimationPlay("MaulAttackHeavy", 0)
	self.Legend:SoundPlayByObject(self.Assets.Sounds.Hit:IsA("Sound") and self.Assets.Sounds.Hit or self:Choose(self.Assets.Sounds.Hit:GetChildren()))
	
	local radius = self.Radius:Get()
	local damageMultiplier = self.AttackHeavyDamageMultiplier
	local position = self.Legend:GetFootPosition() + (self.Legend:GetAimCFrame().LookVector * 8)
	
	self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
		Position = position,
		Range = radius,
		Callback = function(enemy)
			self:HitEnemy(enemy, damageMultiplier, false)
		end
	})
	
	self:GetService("EffectsService"):RequestEffectAll("Shockwave", {
		Duration = 0.25,
		CFrame = CFrame.new(position),
		EndSize = Vector3.new(radius * 2, 1, radius * 2),
		PartArgs = {
			Color = Color3.new(1, 1, 1)
		},
	})

	return true
end

function WeaponMaul:GetRadius()
	local strengthBonus = (self:GetStatValue("Strength") ^ 0.375) / 2
	return self.BaseRadius + strengthBonus
end

function WeaponMaul:OnUpdated(dt)
	self.Radius.Base = self:GetRadius()
	
	if self.CustomOnUpdated then
		self:CustomOnUpdated(dt)
	end
end

function WeaponMaul:HitEnemy(enemy, damageMultiplier, sound)
	self:GetService"DamageService":Damage{
		Source = self.Legend,
		Target = enemy,
		Amount = self:GetDamage() * damageMultiplier,
		Weapon = self,
		Type = "Bludgeoning",
	}
	
	self:HitEffects(enemy, sound)
end

function WeaponMaul:AddParts()
	local maul = self.Assets.Maul:Clone()
	maul.Parent = self.Legend.Model
	maul.Weld.Part0 = self.Legend.Model.RightHand
	maul.Weld.Part1 = maul
	self.Maul = maul
end

function WeaponMaul:ClearParts()
	self:ClearPartsHelper(self.Maul)
end

function WeaponMaul:Equip()
	self:Unsheath()
end

function WeaponMaul:Unequip()
	self:ClearParts()
end

function WeaponMaul:Sheath()
	self:ClearParts()
	self:AddParts()

	self:RebaseWeld(self.Maul.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0, 0, 1),
		CFrame.Angles(0, 0, math.pi / 4),
		CFrame.Angles(0, math.pi / 2, 0)
	)

	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponMaul:Unsheath()
	self:ClearParts()
	self:AddParts()
	
	self.Legend:SetRunAnimation("SingleWeapon")
end

return WeaponMaul