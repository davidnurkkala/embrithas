local Super = require(script.Parent)
local WeaponLongsword = Super:Extend()

WeaponLongsword.Range = 10
WeaponLongsword.DisplayName = "Longsword"
WeaponLongsword.DescriptionLight = "Slash enemies."
WeaponLongsword.DescriptionHeavy = "Riposte, briefly negating incoming damage and damaging attackers."

WeaponLongsword.CooldownLightTime = 0.4
WeaponLongsword.CooldownHeavyTime = 8

function WeaponLongsword:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
	
	self.Riposting = false
	self.RiposteCooldowns = {}
end

function WeaponLongsword:GetDamage()
	return Super.GetDamage(self) * 0.95
end

function WeaponLongsword:SetRiposting(state)
	if self.Riposting == state then return end

	self.Riposting = state
end

function WeaponLongsword:OnWillTakeDamage(damage)
	if not self.Riposting then return end
	if damage.Unblockable then return end

	local source = damage.Source
	if not source then return end
	if self.RiposteCooldowns[source] then return end

	self.RiposteCooldowns[source] = true
	delay(0.1, function()
		self.RiposteCooldowns[source] = false
	end)

	local distanceSq = self.Legend:DistanceToSquared(source:GetPosition())
	local rangeSq = 14 ^ 2
	
	if distanceSq <= rangeSq then
		self:GetService"DamageService":Damage{
			Source = self.Legend,
			Target = source,
			Amount = self:GetDamage(),
			Weapon = self,
			Type = "Piercing",
		}
		self:HitEffects(source)
	end

	self.Legend:SoundPlayByObject(self:Choose(self.Assets.Sounds.Riposte:GetChildren()))

	damage.Amount = 0
end

function WeaponLongsword:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end

	self.CooldownHeavy:Use()
	self.CooldownLight:Use()

	local speed = 0.4
	local duration = 0.5 / speed

	self.Legend:SoundPlay("AdrenalineRush")
	self.Legend:AnimationPlay("LongswordAttackHeavy", 0, nil, speed)

	self:SetRiposting(true)
	delay(duration, function()
		self:SetRiposting(false)
	end)

	return true
end

function WeaponLongsword:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:UseMinimum(self.CooldownLight.Time)

	self:AttackSound()
	self.Legend:AnimationPlay("SwordShieldAttackLight"..self.AttackNumber, 0)
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
	end

	return true
end

function WeaponLongsword:AddParts()
	local sword = self.Assets.Sword:Clone()
	sword.Parent = self.Legend.Model
	sword.Weld.Part0 = self.Legend.Model.RightHand
	sword.Weld.Part1 = sword
	self.Sword = sword
end

function WeaponLongsword:ClearParts()
	self:ClearPartsHelper(self.Sword)
end

function WeaponLongsword:Equip()
	self:Unsheath()
end

function WeaponLongsword:Unequip()
	self:ClearParts()
end

function WeaponLongsword:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Sword.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0, 0, 1),
		CFrame.Angles(0, 0, math.pi / 4),
		CFrame.Angles(0, math.pi / 2, 0)
	)

	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponLongsword:Unsheath()
	self:ClearParts()
	self:AddParts()
	
	self.Legend:SetRunAnimation("SingleWeapon")
end

return WeaponLongsword