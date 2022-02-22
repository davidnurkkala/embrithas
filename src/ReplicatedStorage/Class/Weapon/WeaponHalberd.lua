local Super = require(script.Parent)
local WeaponHalberd = Super:Extend()

WeaponHalberd.Range = 12
WeaponHalberd.Width = 16
WeaponHalberd.Length = 4
WeaponHalberd.ZoneDistance = 10
WeaponHalberd.ZoneGenerosity = 2
WeaponHalberd.DisplayName = "Halberd"
WeaponHalberd.DescriptionLight = "Stab enemies."
WeaponHalberd.DescriptionHeavy = "Slash with blade, dealing extra damage. Will miss targets that are too close."

WeaponHalberd.CooldownLightTime = 1
WeaponHalberd.CooldownHeavyTime = 1

WeaponHalberd.AttackHeavyRangeInner = 5
WeaponHalberd.AttackHeavyRangeOuter = 12

function WeaponHalberd:OnCreated()
	Super.OnCreated(self)
end

function WeaponHalberd:HitEnemy(enemy, damageMultiplier, damageType)
	self:GetService"DamageService":Damage{
		Source = self.Legend,
		Target = enemy,
		Amount = self:GetDamage() * damageMultiplier,
		Weapon = self,
		Type = damageType,
	}
	
	self:HitEffects(enemy)
end

function WeaponHalberd:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:Use()
	
	self:AttackSound()
	self.Legend:AnimationPlay("HalberdAttackLight", 0)
	
	local didAttack = false
	
	self.Targeting:TargetMelee(self.Targeting:GetEnemies(), {
		CFrame = self.Legend:GetAimCFrame(),
		Length = 20,
		Width = 6,
		Callback = function(enemy)
			self:HitEnemy(enemy, 1, "Piercing")
			
			didAttack = true
		end,
	})
	
	if didAttack then
		self.Attacked:Fire()
	end

	return true
end

function WeaponHalberd:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	self.CooldownHeavy:Use()
	self.CooldownLight:Use()
	
	self:AttackSound()
	self.Legend:AnimationPlay("HalberdAttackHeavy", 0)
	
	local range = self.AttackHeavyRangeOuter
	local rangeInnerSq = self.AttackHeavyRangeInner ^ 2
	
	local didAttack = false
	
	self.Targeting:TargetCone(self.Targeting:GetEnemies(), {
		CFrame = self.Legend:GetAimCFrame(),
		Range = range,
		Angle = 110,
		Callback = function(enemy, data)
			if data.DistanceSq < rangeInnerSq then return end
			
			self:HitEnemy(enemy, 2, "Slashing")
			
			didAttack = true
		end,
	})
	
	if didAttack then
		self.Attacked:Fire()
	end

	return true
end


function WeaponHalberd:AddParts()
	local halberd = self.Assets.Halberd:Clone()
	halberd.Parent = self.Legend.Model
	halberd.Weld.Part0 = self.Legend.Model.RightHand
	halberd.Weld.Part1 = halberd
	self.Halberd = halberd
end

function WeaponHalberd:ClearParts()
	self:ClearPartsHelper(self.Halberd)
end

function WeaponHalberd:Equip()
	self:Unsheath()
end

function WeaponHalberd:Unequip()
	self:ClearParts()
end

function WeaponHalberd:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Halberd.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0.5, 0, 1),
		CFrame.new(0, self:GetWeaponLength(self.Halberd) * 0.1, 0),
		CFrame.Angles(0, 0, -math.pi / 2),
		CFrame.Angles(0, math.pi / 2, 0)
	)
	
	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponHalberd:Unsheath()
	self:ClearParts()
	self:AddParts()
	
	self.Legend:SetRunAnimation("SingleWeapon")
end

return WeaponHalberd