local Super = require(script.Parent)
local Enemy = Super:Extend()

local EffectsService = Enemy:GetClass"EffectsService"

Enemy.Instances = {}

function Enemy.GetEnemyFromPart(part)
	for _, instance in pairs(Enemy.Instances) do
		if part:IsDescendantOf(instance.Model) then
			return instance
		end
	end
	return nil
end

Enemy.Modifiers = require(Super.Storage.EnemyModifiers)



Enemy.InjurySoundLast = 0
Enemy.InjurySoundTime = 0.75
Enemy.Damage = 10
Enemy.Level = 0
Enemy.Tags = {}

Enemy.StuckResetTimer = 0

Enemy.AttackSpeed = 1
Enemy.RestSpeed = 1

function Enemy:OnCreated()
	self:SetUpModel()
	
	Super.OnCreated(self)
	self.Speed.Base = 20
	
	self:InitHitbox()
	
	table.insert(Enemy.Instances, self)
	
	self:SetCollisionGroup("Enemy")
	if not self.Root.Anchored then
		self.Root:SetNetworkOwner(nil)
	end
	
	self.Telegraphs = {}
	
	self:SetUpStatusGui()
end

function Enemy:HasTag(tag)
	return table.find(self.Tags, tag) ~= nil
end

function Enemy:HasModifier(modifierName)
	if not self.CurrentModifiers then return false end
	return table.find(self.CurrentModifiers, modifierName) ~= nil
end

function Enemy:InaccuracyDelta(min, max)
	if max == nil then
		max = min
		min = 0
	end
	local radius = self:RandomFloat(min, max)
	local theta = math.pi * 2 * math.random()
	return Vector3.new(math.cos(theta) * radius, 0, math.sin(theta) * radius)
end

function Enemy:AddModifier(modifierName)
	if not self.CurrentModifiers then
		self.CurrentModifiers = {}
	end
	
	local modifier
	for _, m in pairs(Enemy.Modifiers) do
		if m.Name == modifierName then
			modifier = m
			break
		end
	end
	if not modifier then
		warn("Tried to add a modifier that doesn't exist: "..modifierName)
		return
	end
	
	table.insert(self.CurrentModifiers, modifierName)

	if modifier.Type == "Status" then
		local args = {
			Infinite = true,
		}
		for key, val in pairs(modifier.Args) do
			args[key] = val
		end

		if modifier.RandomDelay then
			delay(math.random(), function()
				self:AddStatus("Status", args)
			end)
		else
			self:AddStatus("Status", args)
		end
	elseif modifier.Type == "Custom" then
		modifier.Callback(self)
	end

	self.Name = modifierName.." "..self.Name
end

function Enemy:SetUpModel()
	if not self.Name then
		self.Name = self.EnemyData.Name
	end
	
	local model = self.Model or self.EnemyData.Model:Clone()
	model.Name = self.Name
	model:SetPrimaryPartCFrame(self.StartCFrame)
	model.Parent = workspace.Enemies
	self.Model = model
end

function Enemy:SetUpStatusGui()
	if self.IsBoss then
		self.StatusGui = self:CreateNew"BossStatusGui"{
			Enemy = self,
		}
	else
		local statusGui = self.Storage.UI.StatusGui:Clone()
		statusGui.HealthFrame.Bar.BackgroundColor3 = Color3.new(0.75, 0, 0)
		statusGui.Adornee = self.Root
		statusGui.Parent = self.Model
		
		self.StatusGui = statusGui
	end
end

function Enemy:SetHidden(state)
	if self.Hidden == nil then
		self.Hidden = false
	end
	
	if state == self.Hidden then return end
	self.Hidden = state
	
	if state then
		self.Untargetable = self.Untargetable + 1
	else
		self.Untargetable = self.Untargetable - 1
	end
	
	if state then
		self.HiddenTransparenciesByPart = {}
		for _, desc in pairs(self.Model:GetDescendants()) do
			if desc:IsA("BasePart") then
				self.HiddenTransparenciesByPart[desc] = desc.Transparency
				desc.Transparency = 1
			elseif desc:IsA("ParticleEmitter") then
				self.HiddenTransparenciesByPart[desc] = desc.Enabled
				desc.Enabled = false
			end
		end
		self.StatusGui.Enabled = false
		self:SetCollisionGroup("Invisible")
	else
		for part, transparency in pairs(self.HiddenTransparenciesByPart) do
			if part:IsA("BasePart") then
				part.Transparency = transparency
			elseif part:IsA("ParticleEmitter") then
				part.Enabled = transparency
			end
		end
		self.StatusGui.Enabled = true
		self:SetCollisionGroup("Enemy")
	end
end

function Enemy:UpdateStatusGui()
	if self.IsBoss then
		self.StatusGui:OnUpdated()
	else
		-- name may change when we update
		self.StatusGui.NameLabel.Text = (self.Name or self.Model.Name).." Lv."..self.Level
		
		local shieldAmount = self:GetShieldAmount()
		local totalBarAmount = math.max(self.Health + shieldAmount, self.MaxHealth:Get())

		-- update health
		local healthScalar = self.Health / totalBarAmount
		self.StatusGui.HealthFrame.Bar.Size = UDim2.new(healthScalar, 0, 1, 0)

		-- update shield
		local shieldScalar = shieldAmount / totalBarAmount
		self.StatusGui.HealthFrame.ShieldBar.Position = UDim2.new(healthScalar, 0, 0, 0)
		self.StatusGui.HealthFrame.ShieldBar.Size = UDim2.new(shieldScalar, 0, 1, 0)
	end
end

function Enemy:OnUpdated(dt)
	if not self.Model.Parent then
		self:Deactivate()
	end
	
	if self:GetPosition().Y < -100 then
		self.Root.CFrame = self.StartCFrame
		for _, desc in pairs(self.Model:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Velocity = Vector3.new(0, 0, 0)
			end
		end
	end
	
	self:UpdateStatusGui()
	
	Super.OnUpdated(self, dt)
end

function Enemy:GetSounds()
	if self.Sounds then
		return self.Sounds
	
	elseif self.EnemyData then
		return self.EnemyData:FindFirstChild("Sounds")
	end
end

function Enemy:SoundPlay(soundName)
	local sounds = self:GetSounds()
	if not sounds then return end
	
	local sound = sounds:FindFirstChild(soundName)
	if sound then
		if sound.ClassName == "Folder" then
			self:SoundPlayByObject(self:Choose(sound:GetChildren()))
		else
			self:SoundPlayByObject(sound)
		end
	else
		Super.SoundPlay(self, soundName)
	end
end

function Enemy:OnDied()
	self:SetCollisionGroup("Debris")
	
	if self.CustomOnDied then
		self:CustomOnDied()
	else
		self:SoundPlay("Death")
		self:Ragdoll()
		delay(2, function()
			self:FadeAway(1)
		end)
	end
	
	self.StatusGui:Destroy()
	self:Deactivate()
	self.Died:Fire()
end

function Enemy:FadeAway(duration)
	self:GetService("EffectsService"):RequestEffectAll("FadeModel", {
		Model = self.Model,
		Duration = duration
	})
	game:GetService("Debris"):AddItem(self.Model, duration)
end

function Enemy:OnDestroyed()
	self:CancelTelegraphs()
	
	for index, enemy in pairs(Enemy.Instances) do
		if enemy == self then
			table.remove(Enemy.Instances, index)
			break
		end
	end
	
	for _, status in pairs(self.Statuses) do
		status:Stop()
	end
	self:UpdateStatuses(0)
	
	if self:IsAlive() then
		self.Model:Destroy()
	end

	if self.CustomOnDestroyed then
		self:CustomOnDestroyed()
	end
end

function Enemy:CancelTelegraphs()
	self:ForEachWorldObject(self.Telegraphs, function(telegraph)
		telegraph:Cancel()
	end)
end

function Enemy:TelegraphDirectional(args)
	local duration = args.Duration
	local cframe = args.CFrame
	local length = args.Length
	local width = args.Width
	local callback = args.Callback
	local onTicked = args.OnTicked
	
	local telegraph = self:CreateNew"Timeline"{
		Time = duration,
		Cancel = function(t)
			t.Active = false
			t.OnEnded = function() end
			EffectsService:CancelEffect(t.EffectId)
		end,
		OnStarted = function(t)
			t.EffectId = EffectsService:RequestEffectAll("TelegraphDirectional", {
				CFrame = cframe,
				Length = length,
				Width = width,
				Duration = duration,
			})
		end,
		OnTicked = onTicked,
		UpdateCFrame = function(t, cframe)
			EffectsService:ChangeEffect(t.EffectId, {CFrame = cframe})
		end,
		OnEnded = function(t)
			callback()
		end,
	}
	table.insert(self.Telegraphs, telegraph)
	telegraph:Start()
end

function Enemy:AttackSquare(args)
	local offset
	if args.AttachmentType == "Translate" then
		offset = CFrame.new(self.Root.Position):ToObjectSpace(args.CFrame)
	end
	
	local telegraph = self:CreateNew"Timeline"{
		Time = args.Duration,
		Cancel = function(t)
			t.Active = false
			t.OnEnded = function() end
			EffectsService:CancelEffect(t.EffectId)
		end,
		OnStarted = function(t)
			local effectCFrame = args.CFrame
			if args.AttachmentType == "Translate" then
				effectCFrame = offset
			end
			
			t.EffectId = EffectsService:RequestEffectAll("TelegraphSquare", {
				CFrame = effectCFrame,
				Length = args.Length,
				Width = args.Width,
				Duration = args.Duration,
				Color = args.Color,
				Effect = args.Effect,
				
				Root = self.Root,
				AttachmentType = args.AttachmentType,
			})
		end,
		OnEnded = function()
			local cframe = args.CFrame
			if args.AttachmentType == "Translate" then
				cframe = CFrame.new(self.Root.Position):ToWorldSpace(offset)
			end
			
			local targets = self:GetService("TargetingService"):GetMortals()
			for _, target in pairs(targets) do
				local delta = cframe:PointToObjectSpace(target:GetPosition())
				local inWidth = math.abs(delta.X) <= (args.Width / 2)
				local inLength = math.abs(delta.Z) <= (args.Length / 2)
				if inWidth and inLength then
					args.OnHit(target)
				end
			end
			
			if args.OnEnded then
				args.OnEnded()
			end
			
			EffectsService:RequestEffectAll("Sound", {
				Sound = args.Sound or (self.EnemyData.Sounds.Hit),
				Position = cframe.Position,
			})
		end,
	}
	table.insert(self.Telegraphs, telegraph)
	telegraph:Start()
end

function Enemy:AttackActiveCircle(args)
	local function startActiveCircle()
		local function cleanUp()
			if args.OnCleanedUp then
				args.OnCleanedUp()
			end
		end
		
		local telegraph = self:CreateNew"Timeline"{
			Position = args.Position,
			Radius = args.Radius,
			
			Infinite = args.Infinite,
			Time = args.Duration,
			
			Interval = args.Interval,
			Cancel = function(t)
				t.Active = false
				t.OnEnded = function() cleanUp() end
				EffectsService:CancelEffect(t.EffectId)
			end,
			OnStarted = function(t)
				t.EffectId = EffectsService:RequestEffectAll("ActiveCircle", {
					Position = args.Position,
					Radius = args.Radius,
					Duration = args.Duration,
					Infinite = args.Infinite,
				})
				if args.OnStarted then
					args.OnStarted()
				end
			end,
			OnTicked = function(t, dt)
				if args.OnTicked then
					args.OnTicked(t, dt)
				end
				
				local targets = self:GetService("TargetingService"):GetMortals()
				for _, target in pairs(targets) do
					if target:IsPointInRange(t.Position, t.Radius) then
						args.OnHit(target, dt)
					end
				end
			end,
			OnEnded = function(t)
				if args.OnEnded then
					args.OnEnded()
				end
				cleanUp()
			end,
			
			SetPosition = function(t, position)
				t.Position = position
				EffectsService:ChangeEffect(t.EffectId, {Position = position})
			end,
		}
		table.insert(self.Telegraphs, telegraph)
		telegraph:Start()
	end
	
	if args.Delay then
		local telegraph = self:CreateNew"Timeline"{
			Time = args.Delay,
			Cancel = function(t)
				t.Active = false
				t.OnEnded = function() end
				EffectsService:CancelEffect(t.EffectId)
			end,
			OnStarted = function(t)
				t.EffectId = EffectsService:RequestEffectAll("TelegraphCircle", {
					Position = args.Position,
					Radius = args.Radius,
					Duration = args.Delay,
					Effect = args.Effect,
				})
			end,
			OnEnded = function()
				startActiveCircle()
			end,
		}
		table.insert(self.Telegraphs, telegraph)
		telegraph:Start()
	else
		startActiveCircle()
	end
end

function Enemy:Channel(duration, onTicked, callback)
	local telegraph = self:CreateNew"Timeline"{
		Time = duration,
		Cancel = function(t)
			t.Active = false
			t.OnEnded = function() end
		end,
		OnTicked = onTicked,
		OnEnded = function()
			callback()
		end
	}
	table.insert(self.Telegraphs, telegraph)
	telegraph:Start()
end

function Enemy:Sustain(duration, onTicked, onEnded)
	local telegraph = self:CreateNew"Timeline"{
		Time = duration,
		Cancel = function(t)
			t.Active = false
		end,
		OnTicked = onTicked,
		OnEnded = onEnded,
	}
	table.insert(self.Telegraphs, telegraph)
	telegraph:Start()
end

function Enemy:AttackCircle(args)
	local telegraph = self:CreateNew"Timeline"{
		Time = args.Duration,
		Cancel = function(t)
			t.Active = false
			t.OnEnded = function() end
			EffectsService:CancelEffect(t.EffectId)
		end,
		OnStarted = function(t)
			t.EffectId = EffectsService:RequestEffectAll("TelegraphCircle", {
				Position = args.Position,
				Radius = args.Radius,
				Duration = args.Duration,
				Color = args.Color,
				Effect = args.Effect,
			})
		end,
		OnEnded = function()
			local targets = self:GetService("TargetingService"):GetMortals()
			for _, target in pairs(targets) do
				local delta = target:GetPosition() - args.Position
				local distance = math.sqrt(delta.X ^ 2 + delta.Z ^ 2)
				if distance <= math.max(1, args.Radius - 1) then
					args.OnHit(target)
				end
			end
			
			EffectsService:RequestEffectAll("Sound", {
				Sound = args.Sound or (self.EnemyData.Sounds.Hit),
				Position = args.Position,
			})
			
			if args.OnEnded then
				args.OnEnded()
			end
		end,
	}
	table.insert(self.Telegraphs, telegraph)
	telegraph:Start()
end

function Enemy:GetNearestWoundedEnemy(range)
	local enemies = Enemy.Instances
	
	local nearest
	local bestDistanceSq = range ^ 2
	
	local EnemyHealer = self:GetClass("EnemyHealer")
	
	for _, enemy in pairs(enemies) do
		if (not enemy:IsA(EnemyHealer)) and (enemy.Health < enemy.MaxHealth:Get()) then
			local position = enemy:GetPosition()
			local distanceSq = self:DistanceToSquared(position)
			local canSee = self:CanSeePoint(position)
			if (distanceSq < bestDistanceSq) and canSee then
				nearest = enemy
				bestDistanceSq = distanceSq
			end
		end
	end
	
	return nearest
end

function Enemy:GetFurthestTarget(range, filterFunc, visionRequired)
	if visionRequired == nil then visionRequired = true end
	
	local targets = self:GetService("TargetingService"):GetMortals()
	
	if filterFunc then
		for index = #targets, 1, -1 do
			if not filterFunc(targets[index]) then
				table.remove(targets, index)
			end
		end
	end
	
	local furthest
	local bestDistance = 0
	local rangeSq = range ^ 2
	
	for _, target in pairs(targets) do
		local distance = target:DistanceToSquared(self:GetPosition())
		local canSee = self:CanSeePoint(target:GetPosition()) or (not visionRequired)
		if (distance < rangeSq) and (distance > bestDistance) then
			furthest = target
			bestDistance = distance
		end
	end
	
	return furthest
end

function Enemy:GetNearestTarget(range, filterFunc, visionRequired, position)
	if visionRequired == nil then visionRequired = true end
	
	local targets = self:GetService("TargetingService"):GetMortals()
	
	if filterFunc then
		for index = #targets, 1, -1 do
			local target = targets[index]
			if not filterFunc(target) then
				table.remove(targets, index)
			end
		end
	end
	
	local nearest
	local bestDistance = range ^ 2
	
	for _, target in pairs(targets) do
		local distance = target:DistanceToSquared(position or self:GetPosition())
		local canSee = self:CanSeePoint(target:GetPosition()) or (not visionRequired)
		if (distance < bestDistance) and canSee then
			nearest = target
			bestDistance = distance
		end
	end
	
	return nearest
end

function Enemy:TryInjurySound()
	if self.Health <= 0 then return end
	
	local now = tick()
	if now - self.InjurySoundLast < self.InjurySoundTime then return end
	self.InjurySoundLast = now
	
	self:SoundPlay("Injury")
end

function Enemy:OnDamaged(damage)
	Super.OnDamaged(self, damage)
	
	self:TryInjurySound()
	
	if self.Active and (self.Health <= 0) then
		self:GetService("LogService"):AddEvent{Type = "enemyDied", Enemy = self, Killer = damage.Source}
	end
end

function Enemy:OnWillTakeDamage(damage)
	for _, status in pairs(self.Statuses) do
		if status.OnWillTakeDamage then
			status:OnWillTakeDamage(damage)
		end
	end
end

-- called during waiting states
function Enemy:StuckCheck(dt)
	self.StuckResetTimer = self.StuckResetTimer + dt
	if self.StuckResetTimer > 10 then
		self.Root.CFrame = self.StartCFrame
		self:StuckReset()
	end
end
function Enemy:StuckReset()
	self.StuckResetTimer = 0
end

function Enemy:PushMortalsAway(position, radius, speed)
	local mortals = self:GetService("TargetingService"):GetMortals()
	
	for _, legend in pairs(mortals) do
		local here = position
		local there = legend:GetPosition()
		local delta = (there - here) * Vector3.new(1, 0, 1)
		local distance = delta.Magnitude
		if distance < radius then
			local push = radius - distance
			
			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(1, 1, 1) * 1e5
			bv.Velocity = delta.Unit * speed
			bv.Parent = legend.Root
			game:GetService("Debris"):AddItem(bv, push / speed)
		end
	end
end

function Enemy:DamageFunc(multiplier, damageType, tags)
	return function(character)
		self:GetService("DamageService"):Damage{
			Source = self,
			Target = character,
			Amount = self.Damage * (multiplier or 1),
			Type = damageType,
			Tags = tags,
		}
	end
end

function Enemy:GetAmbushPosition(target, duration, radius)
	local targetPosition = target:GetFootPosition() + target:GetFlatVelocity() * duration
	if not self:DoesPointHaveFloor(targetPosition, 2) then
		targetPosition = target:GetFootPosition()
	end
	
	local position do
		self:Attempt(8, function()
			local theta = math.pi * 2 * math.random()
			local dx = math.cos(theta) * radius
			local dz = math.sin(theta) * radius
			position = Vector3.new(
				targetPosition.X + dx,
				self:GetPosition().Y,
				targetPosition.Z + dz
			)
			return self:DoesPointHaveFloor(position)
		end)
	end
	
	if not position then
		position = targetPosition
	end
	
	return position, targetPosition
end

function Enemy:ApplyFrostyToLegend(legend, stunDamage)
	if legend:HasStatusType("FrostyImmunity") then return end
	
	local status = legend:GetStatusByType("Frosty")
	if status then
		if status.Stacks >= 5 then
			status:Stop()
			
			legend:AddStatus("StatusStunned", {
				Time = 1,
			})
			
			legend:AddStatus("Status", {
				Type = "FrostyImmunity",
				Time = 5,
				
				ImagePlaceholder = "FRSTY\nCD",
			})
			
			self:GetService("DamageService"):Damage{
				Source = self,
				Target = legend,
				Amount = stunDamage,
				Type = "Cold",
				IsFrostyExplosion = true,
				Weapon = self,
			}
			
			legend:SoundPlayByObject(self.Storage.Sounds.IceShatter)
			
			self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
				Position = legend:GetPosition(),
				Color = Color3.fromRGB(114, 154, 171),
				Radius = 8,
				Duration = 0.25,
			})
		else
			status:AddStack()
		end
	else
		legend:AddStatus("StatusFrosty", {
			Time = 5,
		})
	end
end

return Enemy