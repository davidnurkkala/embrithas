local Super = require(script.Parent)
local WeaponSpear = Super:Extend()

WeaponSpear.PrimaryStatName = "Agility"

WeaponSpear.Range = 12
WeaponSpear.DisplayName = "Spear"
WeaponSpear.DescriptionLight = "Stab distant enemies."
WeaponSpear.DescriptionHeavy = [[Toggle "Phalanx Stance." While in Phalanx Stance, move slowly but attack very rapidly.]]

WeaponSpear.CooldownLightTime = 1.2
WeaponSpear.CooldownHeavyTime = 1

WeaponSpear.StanceFactor = 0.5

function WeaponSpear:OnCreated()
	Super.OnCreated(self)
	
	self.StanceActive = false
end

function WeaponSpear:GetDamage()
	return Super.GetDamage(self) * 0.8
end

function WeaponSpear:ToggleStance(state)
	if state == self.StanceActive then return end
	
	self.StanceActive = state
	
	if state then
		self.Legend:AnimationPlay("SpearPhalanxStance", 0)
		self.Legend:SoundPlay("AdrenalineRush")
		
		self:GetService("EffectsService"):RequestEffectAll("Shockwave", {
			Duration = 0.25,
			CFrame = CFrame.new(self.Legend:GetFootPosition()),
			StartSize = Vector3.new(16, 1, 16),
			EndSize = Vector3.new(0, 8, 0),
			PartArgs = {
				Color = Color3.new(1, 1, 1)
			},
		})
		
		local amount = -0.6
		self.StanceStatus = self.Legend:AddStatus("Status", {
			Type = "SpearStanceSlow",
			Infinite = true,
			
			Category = "Good",
			ImagePlaceholder = "PHLNX\nSTANCE",
			
			OnStarted = function(status)
				status.Character.Speed.Percent += amount
			end,
			OnTicked = function()
				local sprintStatus = self.Legend:GetStatusByType("Sprinting")
				if sprintStatus then
					sprintStatus:Stop()
				end

				for _, ability in pairs(self.Legend.Abilities) do
					if ability:IsType("Movement") then
						ability.Cooldown:UseMinimum(0.1)
					end
				end
			end,
			OnEnded = function(status)
				status.Character.Speed.Percent -= amount
			end
		})
	else
		self.Legend:AnimationStop("SpearPhalanxStance")
		
		self:GetService("EffectsService"):RequestEffectAll("Shockwave", {
			Duration = 0.25,
			CFrame = CFrame.new(self.Legend:GetFootPosition()),
			EndSize = Vector3.new(16, 1, 16),
			StartSize = Vector3.new(0, 8, 0),
			PartArgs = {
				Color = Color3.new(1, 1, 1)
			},
		})
		
		self.StanceStatus:Stop()
		self.StanceStatus = nil
	end
end

function WeaponSpear:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	self.CooldownHeavy:Use()
	
	self:ToggleStance(not self.StanceActive)

	return true
end

function WeaponSpear:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	
	local t = self.CooldownLight.Time
	local factor = self.StanceFactor
	
	-- some trinkets can improve this
	for _, trinket in pairs(self.Legend.Trinkets) do
		factor -= (trinket.WeaponSpearPhalanxStanceFactorBonus or 0)
	end
	
	if self.StanceActive then
		t *= factor
	end
	
	self.CooldownLight:Use(t)
	self.CooldownHeavy:UseMinimum(t)

	self:AttackSound()
	self.Legend:AnimationPlay("SpearAttackLight", 0)
	
	local length = 24
	local width = 6
	local cframe = self.Legend:GetAimCFrame() * CFrame.new(0, 0, -length / 2)
	
	self:GetService("EffectsService"):RequestEffectAll("Pierce", {
		CFrame = cframe,
		Tilt = 4,
		Length = length,
		Width = width - 2,
		Duration = 0.1,
	})
	
	local didAttack = false

	self.Targeting:TargetSquare(self.Targeting:GetEnemies(), {
		CFrame = cframe,
		Length = length,
		Width = width,
		Callback = function(enemy)
			self:GetService"DamageService":Damage{
				Source = self.Legend,
				Target = enemy,
				Amount = self:GetDamage(),
				Weapon = self,
				Type = "Piercing",
			}

			self:HitEffects(enemy)
			
			didAttack = true
		end,
	})
	
	if didAttack then
		self.Attacked:Fire()
		
		-- custom events
		if self.OnAttacked then
			self:OnAttacked(cframe)
		end
	end

	return true
end

function WeaponSpear:AddParts()
	local spear = self.Assets.Spear:Clone()
	spear.Parent = self.Legend.Model
	spear.Weld.Part0 = self.Legend.Model.RightHand
	spear.Weld.Part1 = spear
	self.Spear = spear
end

function WeaponSpear:ClearParts()
	self:ClearPartsHelper(self.Spear)
end

function WeaponSpear:Equip()
	self:Unsheath()
end

function WeaponSpear:Unequip()
	self:ClearParts()
	
	self:ToggleStance(false)
end

function WeaponSpear:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Spear.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0.5, 0, 1),
		CFrame.new(0, self:GetWeaponLength(self.Spear) * 0.1, 0),
		CFrame.Angles(0, 0, -math.pi / 2),
		CFrame.Angles(0, math.pi / 2, 0)
	)
	
	self.Legend:SetRunAnimation("NoWeapons")
	
	self:ToggleStance(false)
end

function WeaponSpear:Unsheath()
	self:ClearParts()
	self:AddParts()

	self.Legend:SetRunAnimation("SingleWeapon")
end

return WeaponSpear