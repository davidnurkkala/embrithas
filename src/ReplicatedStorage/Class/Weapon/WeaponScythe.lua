local Super = require(script.Parent)
local WeaponScythe = Super:Extend()

WeaponScythe.PrimaryStatName = "Agility"

WeaponScythe.Range = 10
WeaponScythe.Width = 16
WeaponScythe.Length = 4
WeaponScythe.ZoneDistance = 8
WeaponScythe.ZoneGenerosity = 2
WeaponScythe.DisplayName = "Scythe"
WeaponScythe.DescriptionLight = "Slash enemies. Will miss targets that are too close."
WeaponScythe.DescriptionHeavy = "Briefly slow down to charge and unleash a brutal spin attack."

WeaponScythe.CooldownLightTime = 1
WeaponScythe.CooldownHeavyTime = 4

WeaponScythe.AttackLightRangeInner = 2.5
WeaponScythe.AttackLightRangeOuter = 9.5

WeaponScythe.DamageMultiplier = 2

function WeaponScythe:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
end

function WeaponScythe:GetDamage(...)
	return Super.GetDamage(self, ...) * self.DamageMultiplier
end

function WeaponScythe:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:UseMinimum(self.CooldownLight.Time)

	self:AttackSound()
	self.Legend:AnimationPlay("ScytheAttackLight", 0)

	local range = self.AttackLightRangeOuter
	local rangeInnerSq = self.AttackLightRangeInner ^ 2
	
	local didAttack = false

	self.Targeting:TargetCone(self.Targeting:GetEnemies(), {
		CFrame = self.Legend:GetAimCFrame(),
		Range = range,
		Angle = 110,
		Callback = function(enemy, data)
			if data.DistanceSq < rangeInnerSq then return end
			
			self:GetService("DamageService"):Damage{
				Source = self.Legend,
				Target = enemy,
				Amount = self:GetDamage(),
				Weapon = self,
				Type = "Slashing",
			}
			
			self:HitEffects(enemy)
			
			didAttack = true
		end,
	})
	
	if didAttack then
		self.Attacked:Fire()
		
		if self.OnHitSuccess then
			self:OnHitSuccess()
		end
	else
		if self.OnHitFailure then
			self:OnHitFailure()
		end
	end

	return true
end

function WeaponScythe:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	self.CooldownHeavy:Use()
	self.CooldownLight:Use()
	
	local pause = 0.4
	
	self:ChangeLegendSpeed(-0.9, pause, {
		ImagePlaceholder = "SCY\nCHRG",
	})
	self.Legend:AnimationPlay("ScytheAttackHeavy", 0, nil, 0.5 / pause)
	
	delay(pause, function()
		self:AttackSound()
		
		local didAttack = false
		
		self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
			Position = self.Legend:GetPosition(),
			Range = self.AttackLightRangeOuter,
			Callback = function(enemy)
				self:GetService("DamageService"):Damage{
					Source = self.Legend,
					Target = enemy,
					Amount = self:GetDamage() * self.DamageMultiplier,
					Weapon = self,
					Type = "Slashing",
				}

				self:HitEffects(enemy)

				didAttack = true
			end
		})
		
		if didAttack then
			self.Attacked:Fire()

			if self.OnHitSuccess then
				self:OnHitSuccess()
			end
		else
			if self.OnHitFailure then
				self:OnHitFailure()
			end
		end
	end)

	return true
end

function WeaponScythe:AddParts()
	local scythe = self.Assets.Scythe:Clone()
	scythe.Parent = self.Legend.Model
	scythe.Weld.Part0 = self.Legend.Model.RightHand
	scythe.Weld.Part1 = scythe
	self.Scythe = scythe
end

function WeaponScythe:ClearParts()
	self:ClearPartsHelper(self.Scythe)
end

function WeaponScythe:Equip()
	self:Unsheath()
end

function WeaponScythe:Unequip()
	self:ClearParts()
end

function WeaponScythe:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Scythe.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0, 0, 1),
		CFrame.Angles(0, 0, math.pi / 4),
		CFrame.Angles(0, math.pi / 2, 0)
	)

	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponScythe:Unsheath()
	self:ClearParts()
	self:AddParts()
	
	self.Legend:SetRunAnimation("SingleWeapon")
end

return WeaponScythe