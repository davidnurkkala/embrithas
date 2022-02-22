local Super = require(script.Parent)
local WeaponSaberAndPistol = Super:Extend()

WeaponSaberAndPistol.PrimaryStatName = "Agility"

WeaponSaberAndPistol.Range = 10
WeaponSaberAndPistol.RangedRange = 32
WeaponSaberAndPistol.DisplayName = "Saber & Pistol"
WeaponSaberAndPistol.DescriptionLight = "Slash enemies."
WeaponSaberAndPistol.DescriptionHeavy = "Shoot a piercing bullet."

WeaponSaberAndPistol.CooldownLightTime = 0.5
WeaponSaberAndPistol.CooldownHeavyTime = 2

function WeaponSaberAndPistol:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
	
	self.LoadingStage = 0
	self:UpdateLoadingStage()
end

function WeaponSaberAndPistol:UpdateLoadingStage()
	self:FireRemote("PistolSaberUpdated", self.Legend.Player, {Type = "Update", Stage = self.LoadingStage})
end

function WeaponSaberAndPistol:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:UseMinimum(self.CooldownLight.Time)

	self:AttackSound()
	self.Legend:AnimationPlay("SingleSaberAttackLight"..self.AttackNumber, 0)
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
		
		self.LoadingStage = math.min(self.LoadingStage + 1, 3)
		self:UpdateLoadingStage()
	end

	return true
end

function WeaponSaberAndPistol:AttackHeavy()
	if self.LoadingStage ~= 3 then return end
	
	if not self.CooldownHeavy:IsReady() then return end
	self.CooldownHeavy:Use()
	self.CooldownLight:Use()
	
	self.LoadingStage = 0
	self:UpdateLoadingStage()
	
	local length = 32
	
	local cframe = self.Legend:GetAimCFrame() * CFrame.new(0, 0, -length / 2)
	
	self.Legend:AnimationPlay("PistolShoot", 0)

	self:GetService("EffectsService"):RequestEffectAll("Pierce", {
		CFrame = cframe,
		Tilt = 8,
		Length = length,
		Width = 1,
		Duration = 0.1,
	})

	local damageBonus = 2
	if self:HasModifier("Magnum") then
		damageBonus *= 4/3
	end
	
	local didAttack = false

	local targets = self:GetService("TargetingService"):GetEnemies()
	local width = 3
	self.Targeting:TargetSquare(self.Targeting:GetEnemies(), {
		CFrame = cframe,
		Length = length,
		Width = width,
		Callback = function(enemy)
			self:GetService"DamageService":Damage{
				Source = self.Legend,
				Target = enemy,
				Amount = self:GetDamage() * damageBonus,
				Weapon = self,
				Type = "Piercing",
			}

			self:HitEffects(enemy, false)
			
			didAttack = true
		end
	})
	
	self.Legend:SoundPlayByObject(self:Choose(self.Assets.Sounds.Shot:GetChildren()))
	
	if didAttack then
		self.Attacked:Fire()
	end

	return true
end

function WeaponSaberAndPistol:AddParts()
	local sword = self.Assets.Sword:Clone()
	sword.Parent = self.Legend.Model
	sword.Weld.Part0 = self.Legend.Model.RightHand
	sword.Weld.Part1 = sword
	self.Sword = sword

	local pistol = self.Assets.Pistol:Clone()
	pistol.Parent = self.Legend.Model
	pistol.Weld.Part0 = self.Legend.Model.LeftHand
	pistol.Weld.Part1 = pistol
	self.Pistol = pistol
end

function WeaponSaberAndPistol:ClearParts()
	self:ClearPartsHelper(self.Sword, self.Pistol)
end

function WeaponSaberAndPistol:Equip()
	self:Unsheath()
end

function WeaponSaberAndPistol:Unequip()
	self:ClearParts()
	
	self:FireRemote("PistolSaberUpdated", self.Legend.Player, {Type = "Hide"})
end

function WeaponSaberAndPistol:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Pistol.Weld, self.Legend.Model.LowerTorso,
		CFrame.new(1, 0, 0),
		CFrame.Angles(-math.pi / 4, math.pi, 0)
	)
	
	self:RebaseWeld(self.Sword.Weld, self.Legend.Model.LowerTorso,
		CFrame.new(-1, 0, 0),
		CFrame.Angles(-math.pi * 3 / 4, 0, 0),
		CFrame.new(0, 0, -self:GetWeaponLength(self.Sword) / 2 + 2)
	)
	
	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponSaberAndPistol:Unsheath()
	self:ClearParts()
	self:AddParts()
	
	self.Legend:SetRunAnimation("SwordShield")
end

return WeaponSaberAndPistol