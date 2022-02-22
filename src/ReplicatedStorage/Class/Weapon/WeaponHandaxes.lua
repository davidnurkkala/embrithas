local Super = require(script.Parent)
local WeaponHandaxes = Super:Extend()

local EffectsService = Super:GetService("EffectsService")

WeaponHandaxes.Range = 10
WeaponHandaxes.PickupRangeSq = 6 ^ 2
WeaponHandaxes.DisplayName = "Dual Handaxes"
WeaponHandaxes.DescriptionLight = "Chop enemies. Chop faster with both axes."
WeaponHandaxes.DescriptionHeavy = "Throw left axe at the targeted enemy. Restore left axe by picking it up or slaying an enemy."

WeaponHandaxes.CooldownLightTime = 0.5
WeaponHandaxes.CooldownHeavyTime = 1

WeaponHandaxes.ThrowOffset = CFrame.new()
WeaponHandaxes.ThrowAble = true

WeaponHandaxes.AttackHeavyRange = 32

WeaponHandaxes.DamageType = "Slashing"

function WeaponHandaxes:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
end

function WeaponHandaxes:SetThrowAble(state)
	if state == self.ThrowAble then return end
	
	self.ThrowAble = state
	self.AxeLeft.Transparency = state and 0 or 1
end

function WeaponHandaxes:SetPickupLocation(position)
	self.PickupPosition = position
	
	if position == nil then
		if self.PickupEffectId then
			EffectsService:CancelEffect(self.PickupEffectId)
			self.PickupEffectId = nil
		end
	else
		self.PickupEffectId = EffectsService:RequestEffect(self.Legend.Player, "HandaxeDrop", {
			Axe = self.Assets.AxeLeft,
			Position = position,
		})
	end
end

function WeaponHandaxes:PickUpAxe()
	self:SetPickupLocation(nil)
	self:SetThrowAble(true)
	self.Legend:SoundPlayByObject(self.Assets.Sounds.Pickup)
end

function WeaponHandaxes:OnDealtDamage(damage)
	if damage.Target.Health <= 0 then
		if not self.ThrowAble then
			self:PickUpAxe()
		end
	end
	
	if self.CustomOnDealtDamage then
		self:CustomOnDealtDamage(damage)
	end
end

function WeaponHandaxes:GetFlurryAnimation(number)
	return "HandaxeDualAttackLight"..number, 0, nil, 2.5
end

function WeaponHandaxes:SetTrailsEnabled(enabled)
	self.AxeLeft.Trail.Enabled = enabled
	self.AxeRight.Trail.Enabled = enabled
end

function WeaponHandaxes:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	
	local cooldownTime = self.CooldownLight.Time
	local animationName = "HandaxeSingleAttackLight"
	
	if self.ThrowAble then
		cooldownTime *= 0.75
		animationName = "HandaxeDualAttackLight"
	end
	
	self.CooldownLight:Use(cooldownTime)
	self.CooldownHeavy:UseMinimum(cooldownTime)

	self:AttackSound()
	self.Legend:AnimationPlay(animationName..self.AttackNumber, 0)
	self.AttackNumber = (self.AttackNumber + 1) % 2

	local didAttack = false

	self.Targeting:TargetCone(self.Targeting:GetEnemies(), {
		CFrame = self.Legend:GetAimCFrame(),
		Angle = 110,
		Range = 10,
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

function WeaponHandaxes:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	if not self.ThrowAble then return end

	local position = self.Targeting:GetClampedAimPosition(self.Legend, self.AttackHeavyRange)
	local didAttack = false

	self.Targeting:TargetCircleNearest(self.Targeting:GetEnemies(), {
		Position = position,
		Range = 8,
		Callback = function(enemy)
			if not self.Legend:CanSeePoint(enemy:GetPosition()) then return end
			
			didAttack = true
			
			self.Legend:AnimationPlay("HandaxeThrow", 0)

			local duration = 0.3

			EffectsService:RequestEffectAll("HandaxeThrow", {
				Axe = self.Assets.AxeLeft,
				StartPosition = self.AxeLeft.Position,
				Target = enemy.Root,
				Duration = duration,
				Offset = self.ThrowOffset,
			})

			self:SetThrowAble(false)

			delay(duration, function()
				self:GetService"DamageService":Damage{
					Source = self.Legend,
					Target = enemy,
					Amount = self:GetDamage() * 2,
					Weapon = self,
					Type = "Slashing",
				}
				self:HitEffects(enemy)

				if self:IsEquipped() and (not self.ThrowAble) then
					self:SetPickupLocation(enemy:GetFootPosition())
				end

				if self.OnThrownAxeHitEnemy then
					self:OnThrownAxeHitEnemy(enemy)
				end
			end)
		end,
	})

	if didAttack then
		self.CooldownHeavy:Use()
		self.CooldownLight:Use()
		
		self.Attacked:Fire()
	end

	return true
end

function WeaponHandaxes:OnUpdated(dt)
	if self.PickupPosition then
		local delta = self.Legend:GetPosition() - self.PickupPosition
		local distanceSq = delta.X ^ 2 + delta.Z ^ 2
		if distanceSq < self.PickupRangeSq then
			self:PickUpAxe()
		end
	end
end

function WeaponHandaxes:AddParts()
	local axeRight = self.Assets.AxeRight:Clone()
	axeRight.Parent = self.Legend.Model
	axeRight.Weld.Part0 = self.Legend.Model.RightHand
	axeRight.Weld.Part1 = axeRight
	self.AxeRight = axeRight

	local axeLeft = self.Assets.AxeLeft:Clone()
	axeLeft.Parent = self.Legend.Model
	axeLeft.Weld.Part0 = self.Legend.Model.LeftHand
	axeLeft.Weld.Part1 = axeLeft
	self.AxeLeft = axeLeft
end

function WeaponHandaxes:ClearParts()
	self:ClearPartsHelper(self.AxeRight, self.AxeLeft)
end

function WeaponHandaxes:Equip()
	self:Unsheath()
	
	if self.Legend.WeaponHandaxeThrowAble ~= nil then
		self:SetThrowAble(self.Legend.WeaponHandaxeThrowAble)
	else
		self:SetThrowAble(true)
	end
end

function WeaponHandaxes:Unequip()
	self:ClearParts()
	
	self.Legend.WeaponHandaxeThrowAble = self.ThrowAble
	
	self:SetPickupLocation(nil)
end

function WeaponHandaxes:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.AxeLeft.Weld, self.Legend.Model.LowerTorso,
		CFrame.new(1, 0, 0),
		CFrame.Angles(-math.pi * 3 / 4, 0, 0)
	)

	self:RebaseWeld(self.AxeRight.Weld, self.Legend.Model.LowerTorso,
		CFrame.new(-1, 0, 0),
		CFrame.Angles(-math.pi * 3 / 4, 0, 0)
	)

	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponHandaxes:Unsheath()
	self:ClearParts()
	self:AddParts()
	
	self.Legend:SetRunAnimation("DualWield")
end

return WeaponHandaxes