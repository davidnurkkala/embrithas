local Super = require(script.Parent)
local WeaponBattleaxe = Super:Extend()

WeaponBattleaxe.Range = 10

WeaponBattleaxe.CleaveAngle = math.rad(60)
WeaponBattleaxe.DisplayName = "Battleaxe"
WeaponBattleaxe.DescriptionLight = "Cleave enemies."
WeaponBattleaxe.DescriptionHeavy = "Charge to the targeted enemy, dealing massive damage."

WeaponBattleaxe.CooldownLightTime = 0.8
WeaponBattleaxe.CooldownHeavyTime = 6

-- Kixitt was here 12/15/2020
function WeaponBattleaxe:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
end

function WeaponBattleaxe:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:UseMinimum(self.CooldownLight.Time)

	self:AttackSound()
	self.Legend:AnimationPlay("BattleaxeAttackLight"..self.AttackNumber, 0)
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
	end

	return true
end

function WeaponBattleaxe:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	
	local target
	
	self.Targeting:TargetMeleeNearest(self.Targeting:GetEnemies(), {
		CFrame = self.Legend:GetAimCFrame(),
		Width = 8,
		Length = 64,
		Callback = function(enemy)
			target = enemy
		end
	})
	
	if not target then return end
	if not self.Legend:CanSeePoint(target:GetPosition()) then return end
	
	self.CooldownHeavy:Use()
	self.CooldownLight:Use()

	local root = self.Legend.Root

	local here = root.Position
	local there = target:GetPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)

	local cframe = CFrame.new(here, here + delta)
	root.CFrame = cframe

	local desiredDistance = 10
	local distance = delta.Magnitude
	local direction = delta / distance
	local deltaDistance = distance - desiredDistance
	delta = direction * deltaDistance
	cframe = cframe + delta

	local speed = 128
	local duration = deltaDistance / speed

	self:GetService("EffectsService"):RequestEffectAll("Tween", {
		Object = root,
		Goals = {CFrame = cframe},
		Duration = duration,
		Style = Enum.EasingStyle.Linear,
	})
	
	self:GetService("EffectsService"):RequestEffectAll("ForceWave", {
		Duration = duration,
		Root = self.Legend.Root,
		CFrame = cframe,
		StartSize = Vector3.new(4, 4, 8),
		EndSize = Vector3.new(5, 5, 10),
		PartArgs = {
			Color = Color3.new(1, 1, 1),
			Transparency = 0.5,
		}
	})

	self.Legend:SoundPlayByObject(self.Storage.Sounds.AdrenalineRush)

	self.Legend:AnimationPlay("BattleaxeCharge", 0)

	local trail = self.Axe.Trail
	trail.Enabled = true

	delay(duration, function()
		self.Legend:AnimationStop("BattleaxeCharge", 0)
		self.Legend:AnimationPlay("BattleaxeChargeAttack")

		local damage = self:GetService"DamageService":Damage{
			Source = self.Legend,
			Target = target,
			Amount = self:GetDamage() * 4,
			Weapon = self,
			Type = "Slashing",
		}

		self:HitEffects(target, false)
		target:SoundPlayByObject(self.Assets.Sounds.ChargeHit)

		if self.OnLeapAttacked then
			self:OnLeapAttacked(target)
		end
		
		self.Attacked:Fire()

		wait(0.1)
		trail.Enabled = false
	end)
	
	self.LeapCharge = 0
	
	return true
end

function WeaponBattleaxe:AddParts()
	local axe = self.Assets.Battleaxe:Clone()
	axe.Parent = self.Legend.Model
	axe.Weld.Part0 = self.Legend.Model.RightHand
	axe.Weld.Part1 = axe
	self.Axe = axe
end

function WeaponBattleaxe:ClearParts()
	self:ClearPartsHelper(self.Axe)
end

function WeaponBattleaxe:Equip()
	self:Unsheath()
end

function WeaponBattleaxe:Unequip()
	self:ClearParts()
end

function WeaponBattleaxe:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Axe.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0, 0, 1),
		CFrame.Angles(0, 0, math.pi / 4),
		CFrame.Angles(0, math.pi / 2, 0)
	)
	
	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponBattleaxe:Unsheath()
	self:ClearParts()
	self:AddParts()
	
	self.Legend:SetRunAnimation("SingleWeapon")
end

return WeaponBattleaxe