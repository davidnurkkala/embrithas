local FactionData = require(game.ReplicatedStorage.FactionData)
local TalentData = require(game.ReplicatedStorage.TalentData)

local Super = require(script.Parent)
local Legend = Super:Extend()

Legend.Instances = {}

function Legend.GetLegendFromPart(part)
	for _, instance in pairs(Legend.Instances) do
		if part:IsDescendantOf(instance.Model) then
			return instance
		end
	end
	return nil
end

function Legend.GetLegendFromPlayer(player)
	for _, instance in pairs(Legend.Instances) do
		if instance.Player == player then
			return instance
		end
	end
	return nil
end

function Legend.DoesPlayerHaveLegend(player)
	return Legend.GetLegendFromPlayer(player) ~= nil
end

function Legend.GetMaxHealthFromLevel(level)
	local averageConstitution = level * Legend:GetService("StatService"):GetAverageStatInvestment()
	
	return 100 + (averageConstitution * 2.5) + level * 2
end



Legend.SprintSpeed = 0

function Legend:OnCreated()
	Super.OnCreated(self)
	
	self.AimPosition = Vector3.new()
	
	self.CelebrationCooldown = self:CreateNew"Cooldown"{Time = 5}

	self.AbilityEquipped = self:CreateNew"Signal"()
	self.WeaponEquipped = self:CreateNew"Signal"()
	self.WeaponUsed = self:CreateNew"Signal"()
	self.DefeatedEnemy = self:CreateNew"Signal"()
	
	self.MaxMana = self:CreateNew"Stat"{Base = 100}
	self.Mana = self.MaxMana:Get()
	self.ManaRegenCooldown = self:CreateNew"Cooldown"{Time = 5}
	self.ManaRegen = self:CreateNew"Stat"{Base = 1 / 15}
	
	self.SprintSpeedMax = self:CreateNew"Stat"{Base = 14}
	self.Speed.Base = 18
	
	self.Strength = self:CreateNew"Stat"{Base = 0}
	self.Agility = self:CreateNew"Stat"{Base = 0}
	self.Constitution = self:CreateNew"Stat"{Base = 0}
	self.Perseverance = self:CreateNew"Stat"{Base = 0}
	self.Dominance = self:CreateNew"Stat"{Base = 0}
	self.Compassion = self:CreateNew"Stat"{Base = 0}
	
	self.SheathingSpeed = self:CreateNew"Stat"{Base = 1}
	
	self.Abilities = {}
	self.AbilityActivated = self:CreateNew"Signal"()
	
	self.Trinkets = {}
	
	self.Talents = {}
	
	self.WeaponState = {
		Light = false,
		Heavy = false,
	}
	
	table.insert(Legend.Instances, self)
	
	self:SetUpStatusGui()
	self:InitData()
	self:InitInventory()
	self:InitHitbox()
	
	self:EquipWeapon(self.Inventory.Weapons[self.Inventory.EquippedWeaponIndex])
	
	for slotNumber, index in pairs(self.Inventory.EquippedAbilityIndices) do
		self:EquipAbility(slotNumber, self.Inventory.Abilities[index])
	end
	
	for slotNumber, index in pairs(self.Inventory.EquippedTrinketIndices) do
		self:EquipTrinket(slotNumber, self.Inventory.Trinkets[index])
	end
	
	for _, talentId in pairs(self.Data.EquippedTalents) do
		self:EquipTalent(talentId)
	end
	
	for stat, value in pairs(self.Data.Stats) do
		self[stat].Base = value
	end
	
	self.WeaponsSheathed = false
	self.InCombat = true
	self.InCombatCooldown = self:CreateNew"Cooldown"{Time = 0.5}
	self:InitSprintTrail()
	self:InitLantern()
	self:InitMisc()
	self:SpawnProtection()
	
	-- update and set up stats that might need changes
	self:UpdateStats()
	self.Mana = self.MaxMana:Get()
	self.Health = self.MaxHealth:Get()
	
	-- spawn sheathed
	self:SetWeaponsSheathed(true)
	
	-- make sure we connect these last to make sure everything else is initialized
	self:AddConnection(self:ConnectRemote("AbilityActivated", self.OnAbilityActivated, true))
	self:AddConnection(self:ConnectRemote("WeaponStateChanged", self.OnWeaponStateChanged, true))
	self:AddConnection(self:ConnectRemote("AimPositionUpdated", self.OnAimPositionUpdated, true))
	self:AddConnection(self:ConnectRemote("WeaponsSheathed", self.OnWeaponsSheathed, true))
end

function Legend:OnAimPositionUpdated(player, position)
	if player ~= self.Player then return end
	
	self.AimPosition = position
end

function Legend:OnWeaponsSheathed(player)
	if player ~= self.Player then return end
	if self.WeaponsSheathed then return end
	
	if not self:Channel(1.5 / self.SheathingSpeed:Get(), "Sheathing weapons", "Sheathing") then return end
	
	self:SetWeaponsSheathed(true)
end

function Legend:SetWeaponsSheathed(state)
	if self.Weapon and (not self.Weapon.SheathAble) then
		state = false
	end
	
	if self.WeaponsSheathed == state then return end
	
	self.WeaponsSheathed = state
	if self.Weapon then
		if state then
			self.Weapon:Sheath()
		else
			self.Weapon:Unsheath()
		end
	end
end

function Legend:StartTemporaryEthereality()
	if self.CollisionGroup == "PlayerEthereal" then
		return function() end
	else
		self:SetCollisionGroup("PlayerEthereal")
		return function()
			self:SetCollisionGroup("Player")
		end
	end
end

function Legend:GetAimCFrame()
	local here = self:GetPosition()
	local there = self.AimPosition
	local delta = (there - here) * Vector3.new(1, 0, 1)
	return CFrame.new(here, here + delta)
end

function Legend:SpawnProtection()
	local ff = Instance.new("ForceField")
	ff.Parent = self.Model
	
	self.Invulnerable = self.Invulnerable + 1
	delay(5, function()
		ff:Destroy()
		
		self.Invulnerable = self.Invulnerable - 1
	end)
end

function Legend:InitMisc()
	local chest = Instance.new("Attachment")
	chest.Name = "ChestAttachment"
	chest.Orientation = Vector3.new(0, -90, 0)
	chest.Parent = self.Model.UpperTorso
end

function Legend:DoCelebration()
	if not self.CelebrationCooldown:IsReady() then return end
	self.CelebrationCooldown:Use()
	
	self.Data = self:GetService("DataService"):GetPlayerData(self.Player)
	local productData = require(self.Storage.ProductData)
	
	local animationId = self.Data.Cosmetics.CelebrationAnimation
	local emoteId = self.Data.Cosmetics.CelebrationEmote
	
	local animationData = productData.CelebrationAnimation[animationId]
	if not animationData then return end
	
	local emoteData = productData.CelebrationEmote[emoteId]
	if not emoteData then return end
	
	if animationData.AnimationName then
		self:AnimationPlay(animationData.AnimationName)
	end
	
	if emoteData.Image ~= "" then
		local billboard = self.Storage.UI.CelebrationBillboard:Clone()
		billboard.Emote.Image = emoteData.Image
		
		billboard.Bubble.ImageTransparency = 1
		billboard.Emote.ImageTransparency = 1
		billboard.Adornee = self.Root
		billboard.Parent = self.Root
		
		self:TweenNetwork{
			Object = billboard.Bubble,
			Goals = {ImageTransparency = 0},
			Duration = 0.5,
			Style = Enum.EasingStyle.Linear,
		}
		self:TweenNetwork{
			Object = billboard.Emote,
			Goals = {ImageTransparency = 0},
			Duration = 0.5,
			Style = Enum.EasingStyle.Linear,
		}
		
		delay(3, function()
			self:TweenNetwork{
				Object = billboard.Bubble,
				Goals = {ImageTransparency = 1},
				Duration = 0.5,
				Style = Enum.EasingStyle.Linear,
			}
			self:TweenNetwork{
				Object = billboard.Emote,
				Goals = {ImageTransparency = 1},
				Duration = 0.5,
				Style = Enum.EasingStyle.Linear,
			}
			wait(0.5)
			billboard:Destroy()
		end)
	end
end

function Legend:InitLantern()
	self.Data = self:GetService("DataService"):GetPlayerData(self.Player)
	
	if self.Lantern then
		self.Lantern:Destroy()
		self.Lantern = nil
	end
	
	local lantern
	
	local id = self.Data.Cosmetics.Lantern
	local lanternProducts = require(self.Storage.ProductData).Lantern
	local lanternProduct = lanternProducts[id]
	if not lanternProduct then
		warn("Tried to use lantern with id "..id.." but failed.")
		
		lantern = self.Storage.Models.Lanterns.LanternDefault:Clone()
	else
		lantern = self.Storage.Models.Lanterns[lanternProduct.AssetName]:Clone()
	end
	
	lantern.Parent = self.Model
	
	local partName = "LowerTorso"
	if lantern:FindFirstChild("PartName") then
		partName = lantern.PartName.Value
	end
	lantern.Root.Weld.Part0 = self.Model[partName]
	
	self.Lantern = lantern
end

function Legend:InitHitbox()
	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Shape = Enum.PartType.Cylinder
	hitbox.Size = Vector3.new(6, 3, 3)
	hitbox.Massless = true
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.TopSurface = Enum.SurfaceType.Smooth
	hitbox.BottomSurface = Enum.SurfaceType.Smooth
	
	local weld = Instance.new("Weld")
	weld.Part0 = self.Root
	weld.Part1 = hitbox
	weld.C0 = CFrame.Angles(0, 0, math.pi / 2)
	weld.Parent = hitbox
	
	hitbox.Parent = self.Model
	self.Hitbox = hitbox
end

function Legend:InitSprintTrail()
	local top = Instance.new("Attachment")
	top.Name = "SprintTrailTop"
	top.Position = Vector3.new(0, 0, 0)
	top.Parent = self.Root
	
	local bot = Instance.new("Attachment")
	bot.Name = "SprintTrailBottom"
	bot.Position = Vector3.new(0, -1, 0)
	bot.Parent = self.Root
	
	local trail = Instance.new("Trail")
	trail.Name = "SprintTrail"
	trail.Enabled = false
	trail.FaceCamera = true
	trail.Transparency = NumberSequence.new(0.5, 1)
	trail.Lifetime = 0.5
	trail.Attachment0 = top
	trail.Attachment1 = bot
	trail.Parent = self.Root
	
	self.SprintTrail = trail
end

function Legend:InitData()
	self.Data = self:GetService("DataService"):GetPlayerData(self.Player)
	self.Level = self.Data.Level
end

function Legend:InitInventory()
	self.Inventory = self.Data.Inventory
end

function Legend:SetUpStatusGui()
	local statusGui = self.Storage.UI.StatusGui:Clone()
	statusGui.Adornee = self.Root
	statusGui.PlayerToHideFrom = self.Player
	statusGui.Parent = self.Model
	
	self.StatusGui = statusGui
end

function Legend:OnWillUseMana(manaUse, isCheck)
	for _, status in pairs(self.Statuses) do
		if status.OnWillUseMana then
			status:OnWillUseMana(manaUse, isCheck)
		end
	end
end

function Legend:CanUseMana(amount)
	-- not a big fan of this solution but it works
	local manaUse = {Amount = amount}
	self:OnWillUseMana(manaUse, true)
	amount = manaUse.Amount
	
	return self.Mana >= amount
end

function Legend:UseMana(amount)
	if not self:CanUseMana(amount) then return end
	
	local manaUse = {Amount = amount}
	self:OnWillUseMana(manaUse, false)
	amount = manaUse.Amount
	
	self.Mana -= amount
	
	if self.Weapon.OnManaUsed then
		self.Weapon:OnManaUsed(amount)
	end
	
	for _, talent in pairs(self.Talents) do
		if talent.OnManaUsed then
			talent:OnManaUsed(amount)
		end
	end
	
	self.ManaRegenCooldown:Use()
	
	return amount
end

function Legend:AddMana(amount)
	self.Mana = math.min(self.Mana + amount, self.MaxMana:Get())
end

function Legend:IsStatusGuiValid()
	if not self.StatusGui then return false end
	if not self.StatusGui:FindFirstChild("NameLabel") then return false end
	if not self.StatusGui:FindFirstChild("HealthFrame") then return false end
	if not self.StatusGui.HealthFrame:FindFirstChild("Bar") then return false end
	return true
end

function Legend:UpdateStatusGui()
	if not self:IsStatusGuiValid() then return end
	
	-- name may change when we update
	self.StatusGui.NameLabel.Text = self.Name or self.Model.Name
	
	local shieldAmount = self:GetShieldAmount()
	local totalBarAmount = math.max(self.Health + shieldAmount, self.MaxHealth:Get())
	
	-- update health
	local healthScalar = self.Health / totalBarAmount
	self.StatusGui.HealthFrame.Bar.Size = UDim2.new(healthScalar, 0, 1, 0)
	
	-- update shield
	local shieldScalar = shieldAmount / totalBarAmount
	self.StatusGui.HealthFrame.ShieldBar.Position = UDim2.new(healthScalar, 0, 1, 0)
	self.StatusGui.HealthFrame.ShieldBar.Size = UDim2.new(shieldScalar, 0, 1, 0)
end

function Legend:OnDied()
	self:Ragdoll()
	game:GetService("Debris"):AddItem(self.Model)
	
	self.StatusGui:Destroy()
	
	self:Deactivate()
	
	self.Died:Fire()
end

function Legend:OnDestroyed()
	for index, legend in pairs(Legend.Instances) do
		if legend == self then
			table.remove(Legend.Instances, index)
			break
		end
	end
	
	if self.Weapon then
		self.Weapon:Unequip()
		self.Weapon.Unequipped:Fire()
		self.Weapon = nil
	end
	
	if self:IsAlive() then
		self.Model:Destroy()
	else
		self:SetCollisionGroup("Debris")
		
		local tag = Instance.new("BoolValue")
		tag.Name = "IsDead"
		tag.Value = true
		tag.Parent = self.Model
	end
	
	self:CleanConnections()
end

function Legend:UpdateStatus()
	local run = self:GetService("GameService").CurrentRun
	local points = run.Points
	local pointsRequired = run:GetPointsRequiredForExtraLife()
	local lives = run.LivesRemaining
	
	local abilitiesUseMana = false
	for slotNumber, ability in pairs(self.Abilities) do
		if ability.UsesMana then
			abilitiesUseMana = true
			break
		end
	end
	
	local channel = self:GetChannel()
	local channelInfo = {}
	if channel then
		channelInfo = {
			Name = channel.Name,
			Duration = channel.Time,
			DurationMax = channel.MaxTime,
			Active = true,
		}
	else
		channelInfo = {
			Name = "",
			Duration = 1,
			DurationMax = 1,
			Active = false,
		}
	end
	
	self:FireRemote("StatusUpdated", self.Player, {
		Health = self.Health,
		MaxHealth = self.MaxHealth:Get(),
		Shield = self:GetShieldAmount(),
		Mana = self.Mana,
		MaxMana = self.MaxMana:Get(),
		ManaVisible = self.Weapon.UsesMana or abilitiesUseMana,
		ManaRegenCooldown = self.ManaRegenCooldown:GetRatio(),
		Points = points,
		PointsRequired = pointsRequired,
		Lives = lives,
		Level = self.Level,
		Experience = self.Data.Experience,
		ExperienceRequired = self:GetService("LevelService"):GetRequiredExperienceAtLevel(self.Data.Level),
		Channel = channelInfo,
		Statuses = self:GetStatusesReplicationData(),
	})
end

function Legend:GetStatusesReplicationData()
	local replicationData = {}
	
	for _, status in pairs(self.Statuses) do
		if status.ReplicationDisabled then
			continue
		end
		
		if not status.ReplicationGuid then
			status.ReplicationGuid = self:GenerateGuid()
		end
		
		local data = {
			Image = status.Image,
			ImagePlaceholder = status.ImagePlaceholder,
			Ratio = 1 - status:GetProgress(),
			Stacks = status.Stacks,
			ExtraInfo = status.ExtraInfo,
			Category = status.Category,
		}
		
		replicationData[status.ReplicationGuid] = data
	end
	
	return replicationData
end

function Legend:FallOutPrevention()
	if self:GetPosition().Y > -100 then return end
	
	local run = self:GetService("GameService").CurrentRun
	if not run then return end
	
	self.Root.CFrame = CFrame.new(run.Dungeon.StartRoom:GetSpawn(false) + Vector3.new(0, 4, 0))
	
	for _, desc in pairs(self.Model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Velocity = Vector3.new(0, 0, 0)
		end
	end
end

function Legend:ModSprintSpeed(amount)
	self.Speed:ModFlat(-self.SprintSpeed)
	self.SprintSpeed = math.clamp(self.SprintSpeed + amount, 0, self.SprintSpeedMax:Get())
	self.Speed:ModFlat(self.SprintSpeed)
end

function Legend:UpdateInCombat(dt)
	if self.InCombatCooldown:IsReady() then
		if self.InCombat then
			self.InCombat = false
			
			if self.Data.Options and self.Data.Options.AutoMap then
				self:FireRemote("MapToggled", self.Player, true)
			end
		end
	else
		if not self.InCombat then
			self:SetWeaponsSheathed(false)
			
			self.InCombat = true
			
			if self.Data.Options and self.Data.Options.AutoMap then
				self:FireRemote("MapToggled", self.Player, false)
			end
		end
	end
	
	-- gradually increase or decrease sprint speed depending on combat status
	local dSprintSpeed = self.SprintSpeedMax:Get() * 6 * dt
	if self.WeaponsSheathed then
		self:ModSprintSpeed(dSprintSpeed)
	else
		self:ModSprintSpeed(-dSprintSpeed)
	end
	
	-- trail appears if we're sprinting at all
	self.SprintTrail.Enabled = (self.SprintSpeed > 0)
end

local Lighting = game:GetService("Lighting")
function Legend:UpdateLantern()
	if not self.Lantern then return end
	local root = self.Lantern:FindFirstChild("Root")
	if not root then return end
	local light = root:FindFirstChild("Light")
	if not light then return end
	
	if Lighting.Brightness > 0.3 then
		light.Enabled = false
	else
		light.Enabled = true
	end
end

function Legend:UpdateStats()
	-- update stats themselves
	local healthRatio = self.Health / self.MaxHealth:Get()
	self.MaxHealth.Base = 100 + (self.Constitution:Get() * 2.5) + self.Level * 2
	self.Health = self.MaxHealth:Get() * healthRatio
	
	local manaRatio = self.Mana / self.MaxMana:Get()
	self.MaxMana.Base = 100 + math.ceil(self.Perseverance:Get() * 1)
	self.Mana = self.MaxMana:Get() * manaRatio
	
	-- replicate stats
	local playerStats = {
		Strength = 0,
		Agility = 0,
		Constitution = 0,
		Perseverance = 0,
		Dominance = 0,
		Compassion = 0,
	}
	
	for statName, _ in pairs(playerStats) do
		playerStats[statName] = self[statName]:Get()
	end
	
	local playerBaseStats = {
		Strength = 0,
		Agility = 0,
		Constitution = 0,
		Perseverance = 0,
		Dominance = 0,
		Compassion = 0,
	}
	
	for statName, _ in pairs(playerStats) do
		playerBaseStats[statName] = self[statName].Base
	end
	
	local pointsRemaining = self:GetService("StatService"):GetRemainingStatPoints(self.Player)
	
	self:FireRemote("StatsUpdated", self.Player, playerStats, playerBaseStats, pointsRemaining)
end

function Legend:OnUpdated(dt)
	if not (self.Player and self.Player.Parent) then
		self:Deactivate()
		return
	end
	
	self:UpdateAbility()
	
	if self.Weapon then
		self.Weapon:OnUpdated(dt)
		
		local didAttack = false
		local attackType = ""
		
		if not self:HasStatusType("Stunned") then
			if self.WeaponState.Light then
				self:SetWeaponsSheathed(false)
				if self.Weapon:AttackLight() then
					didAttack = true
					attackType = "Light"
				end
			end
			if self.WeaponState.Heavy then
				self:SetWeaponsSheathed(false)
				if self.Weapon:AttackHeavy() then
					didAttack = true
					attackType = "Heavy"
				end
			end
		end
		
		if didAttack then
			self.InCombatCooldown:Use()
			
			self.WeaponUsed:Fire(self.Weapon, attackType)
		end
	end
	
	for _, talent in pairs(self.Talents) do
		if talent.OnUpdated then
			talent:OnUpdated(dt)
		end
	end
	
	if self.ManaRegenCooldown:IsReady() then
		local maxMana = self.MaxMana:Get()
		local regenPerSecond = maxMana * self.ManaRegen:Get()
		self.Mana = math.min(self.Mana + regenPerSecond * dt, maxMana)
	end
	
	self:UpdateInCombat(dt)
	
	self:UpdateStatusGui()
	self:UpdateStatus()
	self:UpdateStats()
	self:UpdateLantern()
	
	self:FallOutPrevention()
	
	-- speed should scale with agility slightly
	self.Speed.Base = 18 + math.min(4, self:Lerp(0, 4, self.Agility:Get() / 100))
	
	-- health and mana should not exceed their maximums
	self.Health = math.min(self.Health, self.MaxHealth:Get())
	self.Mana = math.min(self.Mana, self.MaxMana:Get())
	
	Super.OnUpdated(self, dt)
end

function Legend:UpdateAbility()
	local update = {}
	
	for index, ability in pairs(self.Abilities) do
		update[index] = {
			Class = ability.Data.Class,
			Image = ability.Data.Image,
			CooldownTime = ability.Cooldown:GetLastTime(),
			Level = self.Level,
			CooldownRemaining = ability.Cooldown:GetRemaining(),
			CooldownActive = not ability.Cooldown:IsReady(),
		}
	end
	
	local cooldown
		
	cooldown = self.Weapon.CooldownLight
	update.WeaponLight = {
		CooldownTime = cooldown:GetLastTime(),
		CooldownRemaining = cooldown:GetRemaining(),
		CooldownActive = not cooldown:IsReady()
	}
	
	cooldown = self.Weapon.CooldownHeavy
	update.WeaponHeavy = {
		CooldownTime = cooldown:GetLastTime(),
		CooldownRemaining = cooldown:GetRemaining(),
		CooldownActive = not cooldown:IsReady()
	}
	
	self:FireRemote("AbilityInfoUpdated", self.Player, update)
end

function Legend:SetRunAnimation(animName)
	local walk = self.Storage.Animations:FindFirstChild("Walk"..animName, true)
	local run = self.Storage.Animations:FindFirstChild("Run"..animName, true)
	
	self.Model.Animate.Walk.AnimationId = walk.AnimationId
	self.Model.Animate.Run.AnimationId = run.AnimationId
end

function Legend:EquipWeapon(slotData)
	local weaponData = self:GetService("WeaponService"):GetWeaponData(slotData)
	
	local data = {}
	for key, val in pairs(weaponData) do
		data[key] = val
	end
	
	self:EquipWeaponByObject(self:CreateNew(weaponData.Class){
		Legend = self,
		Data = data,
	})
end

function Legend:EquipWeaponByObject(weapon)
	local preventAbilityUseTag = self.Player:FindFirstChild("PreventAbilityUse")
	if preventAbilityUseTag then
		preventAbilityUseTag:Destroy()
	end
	
	if self.Weapon then
		self.Weapon:Unequip()
		self.Weapon.Unequipped:Fire()
		self.Weapon = nil
	end

	self.Weapon = weapon
	self.Weapon:Equip()
	self.Weapon.Equipped:Fire()
	self.Weapon.CooldownLight:Use()
	self.Weapon.CooldownHeavy:Use()
	
	if weapon.PreventAbilityUse then
		preventAbilityUseTag = Instance.new("BoolValue")
		preventAbilityUseTag.Name = "PreventAbilityUse"
		preventAbilityUseTag.Value = true
		preventAbilityUseTag.Parent = self.Player
	end
	
	if not weapon.SheathAble then
		self:SetWeaponsSheathed(false)
	end
	
	if self.WeaponsSheathed then
		weapon:Sheath()
	end

	self.WeaponEquipped:Fire(self.Weapon)
	
	return self.Weapon
end

function Legend:EquipAbility(slotNumber, slotData)
	if not slotData then
		self:EquipAbilityByObject(slotNumber, nil)
		
	else
		local abilityData = self:GetService("AbilityService"):GetAbilityData(slotData.Id, slotData.Level)
		for key, val in pairs(slotData) do
			abilityData[key] = val
		end
		
		self:EquipAbilityByObject(slotNumber, self:CreateNew(abilityData.Class){
			Legend = self,
			Data = abilityData,
		})
	end
end

function Legend:EquipAbilityByObject(slotNumber, ability)
	local remaining = 0
	
	local oldAbility = self.Abilities[slotNumber]
	if oldAbility then
		remaining = oldAbility.Cooldown:GetRemaining()
		oldAbility:Unequip()
		
		self.Abilities[slotNumber] = nil
	end
	
	if not ability then return end
	
	self.Abilities[slotNumber] = ability
	ability.Cooldown:Use(remaining)
	ability:Equip()

	self.AbilityEquipped:Fire(slotNumber, ability)
end

function Legend:EquipTrinket(slotNumber, slotData)
	local trinketData = self:GetService("ItemService"):GetItemData("Trinkets", slotData)

	self:EquipTrinketByObject(slotNumber, self:CreateNew("Trinket"){
		Legend = self,
		Data = trinketData,
	})
end

function Legend:IsTalentEquipped(talentId)
	for _, talent in pairs(self.Talents) do
		if talent.Id == talentId then
			return true
		end
	end
	return false
end

function Legend:EquipTalent(talentId)
	local args = {
		Legend = self,
	}
	for key, val in pairs(TalentData[talentId]) do
		args[key] = val
	end 
	
	local talent = self:CreateNew"Talent"(args)
	table.insert(self.Talents, talent)
	talent:OnEquipped()
end

function Legend:UnequipTalent(talentId)
	for index, talent in pairs(self.Talents) do
		if talent.Id == talentId then
			talent:OnUnequipped()
			table.remove(self.Talents, index)
			break
		end
	end
end

function Legend:EquipTrinketByObject(slotNumber, trinket)
	local oldTrinket = self.Trinkets[slotNumber]
	if oldTrinket then
		oldTrinket:Unequip()
		self.Trinkets[slotNumber] = nil
	end
	
	if not trinket then return end
	
	self.Trinkets[slotNumber] = trinket
	trinket:Equip()
end

function Legend:OnAbilityActivated(player, slotNumber)
	if player ~= self.Player then return end
	if not self.Active then return end
	if self.Weapon.PreventAbilityUse then return end
	local ability = self.Abilities[slotNumber]
	if not ability then return end
	if not ability.Cooldown:IsReady() then return end
	
	if ability.OnActivatedServer then
		if not ability:OnActivatedServer() then
			return
		end
	end
	
	ability.Cooldown:Use()
	self.AbilityActivated:Fire(ability)
	
	-- global cooldown
	for _, otherAbility in pairs(self.Abilities) do
		if otherAbility ~= ability then
			if otherAbility:HasSameType(ability) then
				otherAbility.Cooldown:UseMinimum(0.75)
			else
				otherAbility.Cooldown:UseMinimum(0.25)
			end
		end
	end
end

function Legend:OnWeaponStateChanged(player, attackType, state)
	if player ~= self.Player then return end
	if not (attackType == "Light" or attackType == "Heavy") then return end
	if state ~= true then state = false end
	
	self.WeaponState[attackType] = state
end

function Legend:OnWillTakeDamage(damage)
	if self.Weapon then
		self.Weapon.WillTakeDamage:Fire(damage)
		
		if self.Weapon.OnWillTakeDamage then
			self.Weapon:OnWillTakeDamage(damage)
		end
	end
	
	for _, talent in pairs(self.Talents) do
		if talent.OnWillTakeDamage then
			talent:OnWillTakeDamage(damage)
		end
	end
	
	for _, status in pairs(self.Statuses) do
		if status.OnWillTakeDamage then
			status:OnWillTakeDamage(damage)
		end
	end
end

function Legend:OnDealtDamage(damage)
	if self.Weapon then
		self.Weapon.DealtDamage:Fire(damage)
		
		if self.Weapon.OnDealtDamage then
			self.Weapon:OnDealtDamage(damage)
		end
	end
	
	for _, talent in pairs(self.Talents) do
		if talent.OnDealtDamage then
			talent:OnDealtDamage(damage)
		end
	end
	
	local target = damage.Target
	local isEnemy = target:IsA(self:GetClass("Enemy"))
	local isDead = target.Health <= 0
	local hasGivenReward = target.HasGivenKillReward
	if isEnemy and isDead and (not hasGivenReward) then
		target.HasGivenKillReward = true
		
		-- points towards extra life
		local points = 5
		self:GetRun():AddPoints(points)
		self:GetService("LogService"):AddEvent{Type = "pointsAcquired", Player = self.Player, Amount = points}
		
		-- experience
		self:GetService("LevelService"):OnEnemyDefeated(target)
		
		-- kill effect
		local id = self.Data.Cosmetics.KillEffect
		local killEffectProducts = require(self.Storage.ProductData).KillEffect
		local killEffectProduct = killEffectProducts[id]
		if not killEffectProduct then
			warn("Tried to use kill effect with id "..id.." but failed.")
		else
			self:DoKillEffect(target, killEffectProduct.InternalName)
		end
		
		-- event
		self.DefeatedEnemy:Fire(target)
	end
end

function Legend:OnLeveledUp()
	self.Level = self.Data.Level
	
	self:GetService("EffectsService"):RequestEffectAll("LevelUp", {Root = self.Root, Player = self.Player})
end

function Legend:DoKillEffect(target, internalName)
	if internalName == "Ghost" then
		self:GetService("EffectsService"):RequestEffectAll("KillEffectGhost", {
			Position = target:GetPosition(),
		})
	end
end

function Legend:OnWillDealDamage(damage)
	if self.Weapon and self.Weapon.OnWillDealDamage then
		self.Weapon:OnWillDealDamage(damage)
	end
	
	for _, status in pairs(self.Statuses) do
		if status.OnWillDealDamage then
			status:OnWillDealDamage(damage)
		end
	end
	
	for _, talent in pairs(self.Talents) do
		if talent.OnWillDealDamage then
			talent:OnWillDealDamage(damage)
		end
	end
end

function Legend:OnDamaged(damage)
	Super.OnDamaged(self, damage)
	
	if damage.Source and damage.Source:IsA(self:GetClass("Enemy")) then
		self.InCombatCooldown:Use()
	end
	
	if self.Weapon then
		self.Weapon.Damaged:Fire(damage)
	end
	
	for _, talent in pairs(self.Talents) do
		if talent.OnDamaged then
			talent:OnDamaged(damage)
		end
	end
	
	if self.Active and (self.Health <= 0) and (not self.HasSentDeathMessage) then
		self.HasSentDeathMessage = true
		self:GetService("EffectsService"):RequestEffectAll("ChatMessage", {
			Text = string.format("%s was slain by %s!", self.Player.Name, damage.Source.Name or damage.Source.Model.Name),
			Color = Color3.new(1, 0.7, 0.7),
		})
		self:GetService("LogService"):AddEvent{Type = "legendDied", Killer = damage.Source, Legend = self}
	end
end

function Legend:OnWillHeal(heal)
	for _, talent in pairs(self.Talents) do
		if talent.OnWillHeal then
			talent:OnWillHeal(heal)
		end
	end
end

function Legend:OnHealed(heal)
	for _, talent in pairs(self.Talents) do
		if talent.OnHealed then
			talent:OnHealed(heal)
		end
	end
end

function Legend:KickDownDoor(door)
	local id = self.Data.Cosmetics.DoorkickAnimation
	local doorkickAnimationProducts = require(self.Storage.ProductData).DoorkickAnimation
	local doorkickAnimationProduct = doorkickAnimationProducts[id]
	if not doorkickAnimationProduct then
		warn("Tried to use doorkick animation with id "..id.." but failed.")
		
		self:AnimationPlay("LegendKick", 0, 1, 3)
	else
		self:AnimationPlay(doorkickAnimationProduct.AnimationName, 0, 1, 3)
	end
end

function Legend:Channel(duration, name, channelType, channelArgs)
	if self:IsChanneling() then
		return false
	end

	local event = Instance.new("BindableEvent")
	
	local args = {
		Time = duration,
		ChannelType = channelType or "Normal",
		Name = name,
		Event = event,
	}
	
	if channelArgs then
		for key, val in pairs(channelArgs) do
			args[key] = val
		end
	end

	self:AddStatus("StatusChanneling", args)

	return event.Event:Wait()
end

function Legend:GetChannel()
	return self:GetStatusByType("Channeling")
end

function Legend:IsChanneling()
	return self:GetChannel() ~= nil
end

return Legend