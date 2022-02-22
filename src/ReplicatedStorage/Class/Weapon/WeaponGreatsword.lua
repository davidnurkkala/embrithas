local Super = require(script.Parent)
local WeaponGreatsword = Super:Extend()

WeaponGreatsword.Range = 10
WeaponGreatsword.DisplayName = "Greatsword"
WeaponGreatsword.RageFallRate = 2.5
WeaponGreatsword.DescriptionLight = "Slash enemies, producing rage."
WeaponGreatsword.DescriptionHeavy = "Consume rage to perform a spin attack."

WeaponGreatsword.CooldownLightTime = 1.2
WeaponGreatsword.CooldownHeavyTime = 0.4

WeaponGreatsword.AttackHeavyCostRage = 35
WeaponGreatsword.AttackHeavyDamageMultiplier = 1

function WeaponGreatsword:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
	self.Rage = 0
end

function WeaponGreatsword:OnUpdated(dt)
	self:FireRemote("RageUpdated", self.Legend.Player, {Type = "Update", Ratio = math.min(1, self.Rage / 100)})
	self.Rage = math.max(0, self.Rage - self.RageFallRate * dt)
end

-- tothetix was here 12/15/2020
-- A11Noob was here 12/15/2020
function WeaponGreatsword:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:UseMinimum(0.5)
	
	self:AttackSound()
	self.Legend:AnimationPlay("GreatswordAttackLight"..self.AttackNumber, 0)
	self.AttackNumber = (self.AttackNumber + 1) % 2
	
	local didAttack = false

	self.Targeting:TargetCone(self.Targeting:GetEnemies(), {
		CFrame = self.Legend:GetAimCFrame(),
		Angle = 110,
		Range = 14,
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
		
		local amount = 40
		if self:HasModifier("Enraging") then
			amount = 55
		end
		self.Rage = math.min(120, self.Rage + amount)
	end

	return true
end

function WeaponGreatsword:AttackHeavy()
	if self.Rage < self.AttackHeavyCostRage then return end
	if not self.CooldownHeavy:IsReady() then return end
	self.CooldownHeavy:Use()
	self.CooldownLight:UseMinimum(0.5)
	
	self.Rage -= self.AttackHeavyCostRage
	
	self:AttackSound()
	self.Legend:AnimationPlay("GreatswordSpin", 0, nil, 2)
	
	if self.OnSpinAttack then
		self:OnSpinAttack()
	end
	
	local didAttack = false

	self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
		Position = self.Legend:GetAimCFrame().Position,
		Range = 16,
		Callback = function(enemy)
			local damage = self:GetService"DamageService":Damage{
				Source = self.Legend,
				Target = enemy,
				Amount = self:GetDamage() * self.AttackHeavyDamageMultiplier,
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

function WeaponGreatsword:AddParts()
	local sword = self.Assets.Greatsword:Clone()
	sword.Parent = self.Legend.Model
	sword.Weld.Part0 = self.Legend.Model.RightHand
	sword.Weld.Part1 = sword
	self.Sword = sword
end

function WeaponGreatsword:ClearParts()
	self:ClearPartsHelper(self.Sword)
end

function WeaponGreatsword:Equip()
	self:Unsheath()
	
	self:FireRemote("RageUpdated", self.Legend.Player, {Type = "Show"})
end

function WeaponGreatsword:Unequip()
	self:ClearParts()
	
	self:FireRemote("RageUpdated", self.Legend.Player, {Type = "Hide"})
end

function WeaponGreatsword:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Sword.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0, 0, 1),
		CFrame.Angles(0, 0, math.pi / 4),
		CFrame.Angles(0, math.pi / 2, 0)
	)

	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponGreatsword:Unsheath()
	self:ClearParts()
	self:AddParts()
	
	self.Legend:SetRunAnimation("SingleWeapon")
end

return WeaponGreatsword