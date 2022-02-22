local Super = require(script.Parent)
local WeaponGreatsword = Super:Extend()

WeaponGreatsword.Range = 10
WeaponGreatsword.DisplayName = "Legendary Greatsword"
WeaponGreatsword.RageFallRate = 2.5
WeaponGreatsword.DescriptionLight = "Slash enemies. Every third attack, spin, unleashing a wave of light to damage enemies."
WeaponGreatsword.DescriptionHeavy = "Leap to the targeted location, unleashing a wave of light on impact. If this kills an enemy, immediately reset its cooldown. While in midair, you are untargetable."

WeaponGreatsword.CooldownLightTime = 0.8
WeaponGreatsword.CooldownHeavyTime = 5

WeaponGreatsword.StatusType = "WeaponFiaraSwordMidair"

function WeaponGreatsword:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
end

function WeaponGreatsword:LightWave(position, resetHeavyOnKill)
	local position = position or self.Legend:GetFootPosition()
	local radius = 16
	
	local effectsService = self:GetService("EffectsService")
	local partArgs = {
		Material = Enum.Material.Neon,
		BrickColor = BrickColor.new("Gold"),
	}
	effectsService:RequestEffectAll("Shockwave", {
		CFrame = CFrame.new(position),
		StartSize = Vector3.new(),
		EndSize = Vector3.new(2.2, 0.4, 2.2) * radius,
		Duration = 0.25,
		PartArgs = partArgs
	})
	effectsService:RequestEffectAll("AirBlast", {
		Position = position,
		Radius = radius,
		Duration = 0.25,
		PartArgs = partArgs,
	})
	
	self.Legend:SoundPlayByObject(self.Storage.Sounds.LightWave)
	
	self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
		Position = position,
		Range = radius,
		Callback = function(enemy)
			self:GetService"DamageService":Damage{
				Source = self.Legend,
				Target = enemy,
				Amount = self:GetDamage() * 2,
				Weapon = self,
				Type = "Disintegration",
				Tags = {"Magical"},
			}
			
			if resetHeavyOnKill and enemy:IsDead() then
				self.CooldownHeavy:Use(0.5)
			end
		end,
	})
end

function WeaponGreatsword:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:UseMinimum(0.5)
	
	self:AttackSound()
	
	if self.AttackNumber == 2 then
		self.Legend:AnimationPlay("GreatswordSpin", 0, nil, 2)
		
		self:LightWave()
	else
		self.Legend:AnimationPlay("GreatswordAttackLight"..self.AttackNumber, 0)
		
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
	end
	self.AttackNumber = (self.AttackNumber + 1) % 3

	return true
end

function WeaponGreatsword:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	if self.Legend:HasStatusType(self.StatusType) then return end
	
	self.CooldownHeavy:Use()
	self.CooldownLight:UseMinimum(0.5)
	
	local position = self.Targeting:GetClampedAimPosition(self.Legend, 64)
	self.Legend:FaceTowards(position)
	
	local delta = (position - self.Legend.Root.Position) * Vector3.new(1, 0, 1)
	local cframe = self.Legend.Root.CFrame + delta
	
	local duration = 0.5
	
	self:FireRemote("FaceDirectionCalled", self.Legend.Player, delta.Unit, duration)
	
	self:GetService("EffectsService"):RequestEffect(self.Legend.Player, "Leap", {
		Root = self.Legend.Root,
		Duration = duration,
		Finish = cframe,
		Height = 32
	})
	
	self.Legend:AddStatus("Status", {
		Time = duration,
		Type = self.StatusType,
		
		ReplicationDisabled = true,
	})
	
	self.Legend.Untargetable += 1
	delay(duration, function()
		self.Legend.Untargetable -= 1
		self:LightWave(self.Legend:GetFootPosition(position), true)
		self.Legend.Root.CFrame = cframe
	end)
	
	self.Legend:AnimationPlay("GreatswordFlip", 0, nil, 1 / duration)
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
end

function WeaponGreatsword:Unequip()
	self:ClearParts()
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