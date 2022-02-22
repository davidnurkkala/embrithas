local Super = require(script.Parent)
local WeaponClaws = Super:Extend()

WeaponClaws.Range = 10
WeaponClaws.DisplayName = "Claws"
WeaponClaws.DescriptionLight = "Claw enemies, building adrenaline."
WeaponClaws.DescriptionHeavy = "Sacrifice 35% of current health to instantly fill your adrenaline."
WeaponClaws.DescriptionPassive = [[Upon filling adrenaline bar, enter "Adrenaline Rush." During Adrenaline Rush, attack, move faster, and heal 5 health per successful attack.]]

WeaponClaws.CooldownLightTime = 0.5
WeaponClaws.CooldownHeavyTime = 1
WeaponClaws.AdrenalineFallRate = 4
WeaponClaws.AdrenalineAttackSpeed = 2
WeaponClaws.AdrenalineMovementSpeed = 1 / 3

WeaponClaws.DamageType = "Bludgeoning"

function WeaponClaws:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
	self.Adrenaline = 0
	
	self.AdrenalineFalloffCooldown = self:CreateNew"Cooldown"{Time = 1}
end

function WeaponClaws:IsAdrenalineActive()
	local status = self.Legend:GetStatusByType("ClawsAdrenaline")
	return (status ~= nil), status
end

function WeaponClaws:StartAdrenaline()
	local dSpeed = self.AdrenalineMovementSpeed
	self.Legend:AddStatus("Status", {
		Time = 6,
		Type = "ClawsAdrenaline",
		
		Category = "Good",
	ImagePlaceholder = "ADRNL\nRUSH",
		
		OnStarted = function()
			self.Legend.Speed.Percent += dSpeed
		end,
		OnEnded = function()
			self.Legend.Speed.Percent -= dSpeed
		end,
	})
	
	self.Legend:SoundPlayByObject(self.Storage.Sounds.AdrenalineRush)
	
	self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
		Position = self.Legend:GetPosition(),
		Color = Color3.fromRGB(190, 94, 26),
		Radius = 8,
		Duration = 0.25,
	})
end

function WeaponClaws:OnUpdated(dt)
	if self.AdrenalineFalloffCooldown:IsReady() then
		self.Adrenaline = math.max(0, self.Adrenaline - self.AdrenalineFallRate * dt)
	end
	
	local adrenalineActive, adrenalineStatus = self:IsAdrenalineActive()
	if adrenalineActive then
		self.Adrenaline = 100 * (1 - adrenalineStatus:GetProgress())
	end

	self:FireRemote("AdrenalineUpdated", self.Legend.Player, {Type = "Update", Ratio = math.min(1, self.Adrenaline / 100)})
end

function WeaponClaws:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	if self:IsAdrenalineActive() then return end
	
	self.CooldownHeavy:Use()
	self:StartAdrenaline()
	
	self.Legend.Health = math.ceil(self.Legend.Health * 0.65)
	
	return true
end

function WeaponClaws:GetFlurryAnimation(number)
	return "ClawsAttackLight"..number, 0, nil, 2.5
end

function WeaponClaws:SetTrailsEnabled(enabled)
	self.ClawLeft.Trail.Enabled = enabled
	self.ClawRight.Trail.Enabled = enabled
end

function WeaponClaws:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	
	local isAdrenalineActive = self:IsAdrenalineActive()
	
	local t = self.CooldownLight.Time
	if isAdrenalineActive then
		t /= self.AdrenalineAttackSpeed
	end
	
	self.CooldownLight:Use(t)
	self.CooldownHeavy:UseMinimum(t)

	self:AttackSound()
	
	self.Legend:AnimationStop("ClawsAttackLight"..self.AttackNumber, 0)
	self.AttackNumber = (self.AttackNumber + 1) % 2
	self.Legend:AnimationPlay("ClawsAttackLight"..self.AttackNumber, 0)

	local didAttack = false

	self.Targeting:TargetMelee(self.Targeting:GetEnemies(), {
		CFrame = self.Legend:GetAimCFrame(),
		Width = 8,
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
		
		if not isAdrenalineActive then
			local amount = 12
			if self:HasModifier("Enraging") then
				amount = 18
			end
			self.Adrenaline = math.min(self.Adrenaline + amount, 100)
			self.AdrenalineFalloffCooldown:Use()
			
			if self.Adrenaline >= 100 then
				self:StartAdrenaline()
			end
		else
			self:GetService("DamageService"):Heal{
				Source = self.Legend,
				Target = self.Legend,
				Amount = 5,
			}
		end
	end
	
	return true
end

function WeaponClaws:AddParts()
	local right = self.Assets.ClawRight:Clone()
	right.Parent = self.Legend.Model
	right.Weld.Part0 = self.Legend.Model.RightHand
	right.Weld.Part1 = right
	self.ClawRight = right

	local left = self.Assets.ClawLeft:Clone()
	left.Parent = self.Legend.Model
	left.Weld.Part0 = self.Legend.Model.LeftHand
	left.Weld.Part1 = left
	self.ClawLeft = left
end

function WeaponClaws:ClearParts()
	self:ClearPartsHelper(self.ClawRight, self.ClawLeft)
end

function WeaponClaws:Equip()
	self:Unsheath()
	
	self:FireRemote("AdrenalineUpdated", self.Legend.Player, {Type = "Show"})
end

function WeaponClaws:Unequip()
	self:ClearParts()
	
	self:FireRemote("AdrenalineUpdated", self.Legend.Player, {Type = "Hide"})
end

function WeaponClaws:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.ClawLeft.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0, -0.5, 1),
		CFrame.Angles(0, 0, math.pi / 4),
		CFrame.Angles(0, math.pi / 2, 0)
	)
	
	self:RebaseWeld(self.ClawRight.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0, -0.5, 1.25),
		CFrame.Angles(0, 0, -math.pi / 4),
		CFrame.Angles(0, -math.pi / 2, 0)
	)
	
	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponClaws:Unsheath()
	self:ClearParts()
	self:AddParts()
	
	self.Legend:SetRunAnimation("DualWield")
end

return WeaponClaws