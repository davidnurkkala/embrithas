local Super = require(script.Parent)
local WeaponRapier = Super:Extend()

WeaponRapier.PrimaryStatName = "Agility"

WeaponRapier.Range = 10
WeaponRapier.Radius = 3
WeaponRapier.WiggleRoom = 0.5
WeaponRapier.DisplayName = "Rapier"
WeaponRapier.DescriptionLight = "Hold to charge an attack. Stab multiple times depending on charge duration. Aim to release at half charge for a short cooldown."
WeaponRapier.DescriptionHeavy = "Riposte, briefly negating incoming damage and damaging attackers."

WeaponRapier.CooldownLightTime = 2
WeaponRapier.CooldownHeavyTime = 8

function WeaponRapier:OnCreated()
	Super.OnCreated(self)
	
	self.Riposting = false
	self.RiposteCooldowns = {}
end

function WeaponRapier:SetRiposting(state)
	if self.Riposting == state then return end
	
	self.Riposting = state
end

function WeaponRapier:OnWillTakeDamage(damage)
	if not self.Riposting then return end
	if damage.Unblockable then return end
	
	local source = damage.Source
	if not source then return end
	if self.RiposteCooldowns[source] then return end
	
	self.RiposteCooldowns[source] = true
	delay(0.1, function()
		self.RiposteCooldowns[source] = false
	end)
	
	local here = self.Legend:GetPosition()
	local there = source:GetPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	
	local length = 12
	local width = 4
	local cframe = CFrame.new(here, here + delta) * CFrame.new(0, 0, -length / 2)
	
	self.Legend:SoundPlayByObject(self:Choose(self.Assets.Sounds.Riposte:GetChildren()))
	self:Attack(cframe, length, width)
	
	damage.Amount = 0
end

function WeaponRapier:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	
	self.CooldownHeavy:Use()
	self.CooldownLight:Use()
	
	local speed = 0.4
	local duration = 0.5 / speed
	
	self.Legend:SoundPlay("AdrenalineRush")
	self.Legend:AnimationPlay("RapierAttackHeavy", 0, nil, speed)
	
	self:SetRiposting(true)
	delay(duration, function()
		self:SetRiposting(false)
	end)

	return true
end

function WeaponRapier:Attack(cframe, length, width)
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
	
	return didAttack
end

-- Chris_8602 was here 2/5/2021
function WeaponRapier:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	
	self.CooldownLight:Use(4)
	
	print(self.CooldownHeavy:GetRemaining())
	self.CooldownHeavy:UseMinimum(1.5)
	
	self.Legend:AnimationPlay("RapierCharge", 0)
	
	local chargeTime = 0
	local chargeTimeMax = 1
	
	local didAttack = false
	
	local function stab()
		local length = 14
		local width = 4
		local cframe = self.Legend:GetAimCFrame() * CFrame.new(0, 0, -length / 2)

		self:AttackSound()
		
		if self:Attack(cframe, length, width) and (not didAttack) then
			didAttack = true
			self.Attacked:Fire()
		end
		
		self.Legend:AnimationPlay("RapierStab", 0)
	end
	
	local function feedback(args)
		self:GetService("EffectsService"):RequestEffect(self.Legend.Player, "TextFeedback", {
			Duration = 0.5,
			TextArgs = args,
		})
	end
	
	local function resolve()
		if not self:IsEquipped() then return end
		
		self.Legend:AnimationStop("RapierCharge", 0)
		
		local ratio = (chargeTime / chargeTimeMax)
		
		local stabDelay = 0.1
		local stabCount = math.min(math.ceil(ratio * 5), 5)
		
		local cooldown
		if ratio < 0.4 then
			cooldown = 2.5
			feedback{Text = "Early...", TextColor3 = Color3.new(0.6, 0.6, 0.6)}
		elseif ratio < 0.6 then
			cooldown = 1.5
			feedback{Text = "P e r f e c t !", TextColor3 = Color3.new(1, 1, 0.42)}
		else
			cooldown = 4.5
			feedback{Text = "Late...", TextColor3 = Color3.new(1, 0.35, 0.35)}
		end

		for stabNumber = 0, (stabCount - 1) do
			delay(stabDelay * stabNumber, stab)
		end
		
		self.CooldownLight:Use(cooldown)
	end
	
	self:CreateNew"Timeline"{
		Time = chargeTimeMax,
		OnTicked = function(t, dt)
			chargeTime += dt
			
			local shouldStop = (not self:IsEquipped()) or (not self.Legend.WeaponState.Light)
			if shouldStop then
				t:Stop()
			end
		end,
		OnEnded = function()
			resolve()
		end
	}:Start()

	return true
end

function WeaponRapier:AddParts()
	local rapier = self.Assets.Rapier:Clone()
	rapier.Parent = self.Legend.Model
	rapier.Weld.Part0 = self.Legend.Model.RightHand
	rapier.Weld.Part1 = rapier
	self.Rapier = rapier
end

function WeaponRapier:ClearParts()
	self:ClearPartsHelper(self.Rapier)
end

function WeaponRapier:Equip()
	self:Unsheath()
end

function WeaponRapier:Unequip()
	self.Rapier:Destroy()
	
	self:SetRiposting(false)
end

function WeaponRapier:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Rapier.Weld, self.Legend.Model.LowerTorso,
		CFrame.new(-1, 0, 0),
		CFrame.Angles(-math.pi * 3 / 4, 0, 0),
		CFrame.new(0, 0, -self:GetWeaponLength(self.Rapier) / 2 + 2)
	)
	
	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponRapier:Unsheath()
	self:ClearParts()
	self:AddParts()

	self.Legend:SetRunAnimation("SingleWeapon")
end

return WeaponRapier