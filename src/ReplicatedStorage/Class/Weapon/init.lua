local RunService = game:GetService("RunService")

local Super = require(script.Parent)
local Weapon = Super:Extend()

Weapon.CooldownLightTime = 0.5
Weapon.CooldownHeavyTime = 4

Weapon.SheathAble = true

Weapon.PrimaryStatName = "Strength"

function Weapon:OnCreated()
	if self.Data.Args then
		for key, val in pairs(self.Data.Args) do
			self[key] = val
		end
	end
	
	self.CooldownLight = self:CreateNew"Cooldown"{Time = self.CooldownLightTime}
	self.CooldownHeavy = self:CreateNew"Cooldown"{Time = self.CooldownHeavyTime}
	
	self.Assets = self.Storage.Weapons:FindFirstChild(self.Data.AssetsName)
	
	self.Attacked = self:CreateNew"Signal"()
	self.DealtDamage = self:CreateNew"Signal"()
	self.WillTakeDamage = self:CreateNew"Signal"()
	self.Damaged = self:CreateNew"Signal"()
	self.Equipped = self:CreateNew"Signal"()
	self.Unequipped = self:CreateNew"Signal"()
	
	self.Targeting = self:GetService("TargetingService")
	
	self:InitModifiers()
	
	assert(self.Assets)
	assert(self.Legend)
end

function Weapon:GetDamagePerSecond()
	-- get our level
	local level
	if RunService:IsClient() then
		level = self:GetService("GuiClient").Level
	elseif RunService:IsServer() then
		level = self.Legend.Level
	end

	-- get our stat value
	local statValue = self:GetPrimaryStatValue()

	-- calculate our power
	local dps = self:GetService("StatService"):GetPower(level, statValue)

	-- apply bonuses based on rarity
	local bonus = 1
	if self.Data.Rarity == "Rare" then
		bonus = 1.1
	elseif self.Data.Rarity == "Mythic" then
		bonus = 1.25
	elseif self.Data.Rarity == "Heroic" then
		bonus = 1.5
	elseif self.Data.Rarity == "Legendary" then
		bonus = 2
	end
	dps *= bonus

	-- apply modifiers
	if self:HasModifier("Sharp") or self:HasModifier("Heavy") then
		dps *= 1.15
	end

	-- apply upgrades
	if self.Data.Upgrades then
		dps *= 1 + (self.Data.Upgrades * 0.02)
	end

	-- all done
	return dps
end

function Weapon:GetDamage()
	-- find out how many attacks we can do per second on average
	local attacksPerSecond = self:GetAttacksPerSecond()

	-- try to deal power damage per second
	local damage = self:GetDamagePerSecond() / attacksPerSecond
	
	-- damage
	return damage
end

function Weapon:GetAttacksPerSecond()
	return 1 / self.CooldownLightTime
end

function Weapon:HasModifier(modifierId)
	if self.Data.Modifiers then
		return table.find(self.Data.Modifiers, modifierId) ~= nil
	end
	return false
end

function Weapon:InitModifiers()
	-- mystic modifier applies to all weapons
	if self:HasModifier("Mystic") then
		self.UsesMana = true
		
		self.Attacked:Connect(function()
			local manaRestored = 7.5 * self.CooldownLight:GetLastTime()
			self.Legend.Mana = math.min(self.Legend.Mana + manaRestored, self.Legend.MaxMana:Get())
		end)
	end
	
	-- perfected modifier
	if self:HasModifier("Perfected") then
		local max = 0.5
		
		self.Attacked:Connect(function()
			if not self:IsEquipped() then return end
			
			local change = 0.1 * self.CooldownLight:GetLastTime()
			
			local status = self.Legend:GetStatusByType("PerfectedBonus")
			if not status then
				status = self.Legend:AddStatus("Status", {
					Type = "PerfectedBonus",
					Infinite = true,
					Interval = 1,
					
					Category = "Good",
					ImagePlaceholder = "PERF",
					
					Power = 0,
					
					AddPower = function(status, amount)
						self.Legend.Power.Flat -= status.Power
						status.Power = math.min(status.Power + change, max)
						self.Legend.Power.Flat += status.Power
						
						status.ExtraInfo = string.format("%d%%", status.Power * 100)
					end,
					
					OnDamaged = function(status)
						status:Stop()
					end,
					
					OnEnded = function(status)
						self.Legend.Power.Flat -= status.Power
					end,
				})
			end
			status:AddPower(change)
		end)
	end
	
	-- vampiric modifier
	if self:HasModifier("Vampiric") then
		local function update(ratio)
			self:FireRemote("VampiricUpdated", self.Legend.Player, {Type = "Update", Ratio = ratio})
		end
		
		self.Equipped:Connect(function()
			self:FireRemote("VampiricUpdated", self.Legend.Player, {Type = "Show"})
			
			if not self.Legend:HasStatusType("VampiricHealing") then
				update(0)
			end
		end)
		
		self.Unequipped:Connect(function()
			if not self.Legend:HasStatusType("VampiricHealing") then
				self:FireRemote("VampiricUpdated", self.Legend.Player, {Type = "Hide"})
			end
		end)
		
		self.DealtDamage:Connect(function(damage)
			if damage.Weapon ~= self then return end
			
			local damageService = self:GetService("DamageService") 
			
			local status = self.Legend:GetStatusByType("VampiricHealing")
			if not status then
				status = self.Legend:AddStatus("Status", {
					Type = "VampiricHealing",
					Infinite = true,
					Healing = 0,
					Interval = 1,
					
					ReplicationDisabled = true,
					
					OnTicked = function(status, dt)
						local maxHealth = status.Character.MaxHealth:Get()
						
						update(status.Healing / maxHealth)
						
						local maxHealing = maxHealth * 0.01 * dt
						local healing = math.min(status.Healing, maxHealing)
						status.Healing -= healing
						damageService:Heal{
							Source = self.Legend,
							Target = self.Legend,
							Amount = healing
						}
						
						if status.Healing <= 0 then
							status:Stop()
						end
					end,
					
					OnEnded = function()
						update(0)
						
						if not self.Legend.Weapon:HasModifier("Vampiric") then
							self:FireRemote("VampiricUpdated", self.Legend.Player, {Type = "Hide"})
						end
					end,
				})
			end
			
			status.Healing += damage.Amount * 0.05
			update(status.Healing / self.Legend.MaxHealth:Get())
		end)
	end
	
	-- ethereal modifier
	if self:HasModifier("Ethereal") then
		self.Equipped:Connect(function()
			self.Legend:SetCollisionGroup("PlayerEthereal")
		end)
		self.Unequipped:Connect(function()
			self.Legend:SetCollisionGroup("Player")
		end)
	end
	
	-- stat modifiers
	local function statModifierHelper(modifier, statName)
		if self:HasModifier(modifier) then
			local amount = 50
			self.Equipped:Connect(function()
				self.Legend[statName].Flat += amount
			end)
			self.Unequipped:Connect(function()
				self.Legend[statName].Flat -= amount
			end)
		end
	end
	statModifierHelper("Fierce", "Strength")
	statModifierHelper("Agile", "Agility")
	statModifierHelper("Vital", "Constitution")
	statModifierHelper("Spiritual", "Perseverance")
	statModifierHelper("Willful", "Dominance")
	statModifierHelper("Empathetic", "Compassion")
end

function Weapon:RangedWeaponSlow()
	local legend = self.Legend
	
	local status = legend:GetStatusByType("RangedWeaponSlow")
	if status then
		status:Restart()
	else
		legend:AddStatus("Status", {
			Time = 1,
			Type = "RangedWeaponSlow",
			
			ImagePlaceholder = "RNGD\nSLOW",
			
			OnStarted = function()
				legend.Speed.Percent -= 0.4
			end,
			OnEnded = function()
				legend.Speed.Percent += 0.4
			end,
		})
	end
end

function Weapon:ChangeLegendSpeed(amount, duration, overrides)
	local legend = self.Legend
	
	local args = {
		Time = duration,
		Type = "WeaponSpeedChange",
		
		OnStarted = function()
			legend.Speed.Percent += amount
		end,
		OnEnded = function()
			legend.Speed.Percent -= amount
		end
	}
	
	for key, val in pairs(overrides) do
		args[key] = val
	end
	
	legend:AddStatus("Status", args)
end

function Weapon:GetPrimaryStatValue()
	return self:GetStatValue(self.PrimaryStatName)
end

function Weapon:GetLevel()
	if RunService:IsServer() then
		return self.Legend.Level
	else
		return self:GetService("GuiClient").Level
	end
end

function Weapon:GetStatValue(statName)
	if RunService:IsServer() then
		return self.Legend[statName]:Get()

	elseif RunService:IsClient() then
		return self:GetService("CharacterScreenClient"):GetStatValue(statName)
	end
end

function Weapon:CreateGenericProjectile(args)
	return self:GetClass("Projectile").CreateGenericProjectile(args)
end

function Weapon:GetMechanicsDescription()
	local descriptionLight = self.DescriptionLight
	local descriptionHeavy = self.DescriptionHeavy
	local descriptionPassive = self.DescriptionPassive
	
	if typeof(descriptionLight) == "function" then
		descriptionLight = descriptionLight(self)
	end
	if typeof(descriptionHeavy) == "function" then
		descriptionHeavy = descriptionHeavy(self)
	end
	if typeof(descriptionPassive) == "function" then
		descriptionPassive = descriptionPassive(self)
	end
	
	if descriptionPassive then
		descriptionPassive = "\n⚙️ "..descriptionPassive
	else
		descriptionPassive = ""
	end
	
	return string.format("💠 %s\n🔷 %s%s", descriptionLight, descriptionHeavy, descriptionPassive)
end

function Weapon:GetDescription(level, itemData, includeMechanics)
	if includeMechanics == nil then
		includeMechanics = true
	end
	
	local desc = string.format("%s\n\n⚔️ %4.1f", itemData.Description, self:GetDamage())
	
	if includeMechanics then
		desc = desc.."\n"..self:GetMechanicsDescription()
	end
	
	return desc
end

function Weapon:Equip()
	error("Base weapon Equip called.")
end

function Weapon:Unequip()
	error("Base weapon Unequip called.")
end

function Weapon:Sheath()
	-- does nothing
end

function Weapon:Unsheath()
	-- does nothing
end

function Weapon:RebaseWeld(weld, newPart0, ...)
	weld.Part0 = newPart0
	
	local cframes = {...}
	local cframe = CFrame.new()
	for _, nextCFrame in pairs(cframes) do
		cframe *= nextCFrame
	end
	local c0 = weld.C0
	c0 -= c0.Position
	weld.C0 = cframe * c0
end

function Weapon:GetWeaponLength(part)
	return math.max(part.Size.X, part.Size.Y, part.Size.Z)
end

function Weapon:ClearPartsHelper(...)
	local parts = {...}
	for _, part in pairs(parts) do
		part:Destroy()
	end
end
function Weapon:ClearParts()
	error("Base weapon ClearParts called.")
end

function Weapon:GetEnemyInRange(range)
	local enemies = self:GetService("TargetingService"):GetEnemies()
	for _, enemy in pairs(enemies) do
		if self.Legend:IsPointInRange(enemy:GetPosition(), range) then
			if self.Legend:CanSeePoint(enemy:GetPosition()) then
				return enemy
			end
		end
	end
	return nil
end

function Weapon:GetNearestEnemyInRange(range)
	local enemies = self:GetService("TargetingService"):GetEnemies()
	local best = nil
	local bestDistanceSq = range ^ 2
	for _, enemy in pairs(enemies) do
		local distanceSq = self.Legend:DistanceToSquared(enemy:GetPosition())
		if distanceSq <= bestDistanceSq then
			if self.Legend:CanSeePoint(enemy:GetPosition()) then
				best = enemy
				bestDistanceSq = distanceSq
			end
		end
	end
	return best, math.sqrt(bestDistanceSq)
end

function Weapon:GetPowerHelper(statName)
	return self:GetService("StatService"):GetPower(self:GetLevel(), self:GetStatValue(statName))
end

function Weapon:IsEquipped()
	return self.Legend and self.Legend.Weapon == self
end

function Weapon:IsStandingStill()
	local currentPosition = self.Legend:GetPosition()
	
	local isStandingStill = false
	if self.StandingStillLastPosition then
		isStandingStill = currentPosition:FuzzyEq(self.StandingStillLastPosition)
	end
	self.StandingStillLastPosition = currentPosition
	
	return isStandingStill
end

function Weapon:AttackSound()
	local sound = self.Assets.Sounds:FindFirstChild("Attack")
	if not sound then return end
	
	if sound:IsA("Folder") then
		sound = self:Choose(sound:GetChildren())
	end
	
	self.Legend:SoundPlayByObject(sound)
end

function Weapon:HitEffects(character, useHitSound)
	if useHitSound == nil then useHitSound = true end
	
	-- sound
	if useHitSound then
		local sound = self.Assets.Sounds:FindFirstChild("Hit")
		if sound:IsA("Folder") then
			local sounds = sound:GetChildren()
			sound = sounds[math.random(1, #sounds)]
		end
	
		character:SoundPlayByObject(sound)
	end
	
	-- particles
	local id = 1
	local data = self:GetService("DataService"):GetPlayerData(self.Legend.Player)
	if data then
		id = data.Cosmetics.HitEffect
	end
	local product = require(self.Storage.ProductData).HitEffect[id]
	
	local emitter = self.Storage.Emitters.HitEffects[product.AssetName]:Clone()
	emitter.Parent = character.Root
	
	local duration = 0.125
	if emitter:FindFirstChild("Duration") then
		duration = emitter.Duration.Value
	end
	
	delay(duration, function()
		emitter.Enabled = false
		game:GetService("Debris"):AddItem(emitter, emitter.Lifetime.Max)
	end)
end

function Weapon:OnUpdated(dt)
	-- do nothing
end

function Weapon:AttackLight()
	
end

function Weapon:AttackHeavy()
	
end

return Weapon