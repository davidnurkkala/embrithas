local Super = require(script.Parent)
local Character = Super:Extend()

Character.Untargetable = 0
Character.Invulnerable = 0

function Character:OnCreated()
	self.StatusAdded = self:CreateNew"Signal"()
	
	Super.OnCreated(self)
	
	self.Statuses = {}
	
	local Stat = self:GetClass"Stat"
	
	self.MaxHealth = Stat:Create()
	self.Health = self.MaxHealth:Get()

	self.Armor = Stat:Create{Base = 0}
	self.Power = Stat:Create{Base = 0}
	
	self:InitResistances()
	
	self.HealingPower = Stat:Create{Base = 0}
	
	assert(self.Model)
	self.Root = self.Model.PrimaryPart
	
	self.Died = self:CreateNew"Event"()
end

function Character:InitResistances()
	local Stat = self:GetClass"Stat"
	
	local resistances = {
		Slashing = Stat:Create{Base = 0},
		Piercing = Stat:Create{Base = 0},
		Bludgeoning = Stat:Create{Base = 0},
		Heat = Stat:Create{Base = 0},
		Cold = Stat:Create{Base = 0},
		Internal = Stat:Create{Base = 0},
		Disintegration = Stat:Create{Base = 0},
		Psychic = Stat:Create{Base = 0},
		Electrical  = Stat:Create{Base = 0},
		
		Physical = Stat:Create{Base = 0},
		Magical = Stat:Create{Base = 0},
	}
	
	if self.Resistances then
		for name, value in pairs(self.Resistances) do
			resistances[name].Base = value
		end
	end
	
	self.Resistances = resistances
end

function Character:GetHealthRatio()
	return self.Health / self.MaxHealth:Get()
end

function Character:IsAlive()
	return self.Health > 0
end

function Character:UpdateStatuses(dt)
	for index = #self.Statuses, 1, -1 do
		local status = self.Statuses[index]
		if not status then
			continue
		end
		
		if status.Active then
			status:OnUpdated(dt)
		end
		
		if (not status.Active) or (status.Deactivating) then
			self:RemoveStatusByIndex(index)
		end
	end
end

function Character:GetStatusByType(statusType)
	for _, status in pairs(self.Statuses) do
		if (status.Type == statusType) and (status.Active) then
			return status
		end
	end
	return nil
end

function Character:HasStatusType(statusType)
	return self:GetStatusByType(statusType) ~= nil
end

function Character:IsStunned()
	return self:HasStatusType("Stunned")
end

function Character:GetShieldAmount()
	local total = 0
	for _, status in pairs(self.Statuses) do
		if status.IsShield then
			total += status.Amount
		end
	end
	return total
end

function Character:AddStatus(statusType, args)
	args.Character = self
	local status = self:CreateNew(statusType)(args)
	table.insert(self.Statuses, status)
	self.StatusAdded:Fire(status)
	return status
end

function Character:RemoveStatusByIndex(index)
	local status = self.Statuses[index]
	
	status.Active = false
	table.remove(self.Statuses, index)

	status:OnDestroyed()
	status.Destroyed:Fire()
end

function Character:RemoveStatus(status)
	local index = table.find(self.Statuses, status)
	if not index then return end
	
	self:RemoveStatusByIndex(index)
end

function Character:OnStatusAdded(status)
	
end

function Character:IsDead()
	return self.Health <= 0
end

function Character:OnUpdated(dt)
	-- status effects
	self:UpdateStatuses(dt)
	
	--death check
	if self:IsDead() then
		self:OnDied()
	end
end

function Character:OnDied()
	self.Active = false
	self.Died:Fire()
end

function Character:OnDestroyed()
	self.Model:Destroy()
end

function Character:GetFootPosition(positionOverride)
	local ray = Ray.new(positionOverride or self:GetPosition(), Vector3.new(0, -512, 0))
	local part, point = self:Raycast(ray)
	return point
end

function Character:GetFootCFrameTo(there)
	local here = self:GetFootPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	return CFrame.new(here, here + delta)
end

function Character:GetCFrameTo(there)
	local here = self:GetPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	return CFrame.new(here, here + delta)
end

function Character:GetPosition()
	if self.Model and self.Model.PrimaryPart then
		return self.Model.PrimaryPart.Position
	else
		return Vector3.new()
	end
end

function Character:GetVelocity()
	if self.Model and self.Model.PrimaryPart then
		return self.Model.PrimaryPart.Velocity
	else
		return Vector3.new()
	end
end

function Character:GetFlatVelocity()
	return self:GetVelocity() * Vector3.new(1, 0, 1)
end

function Character:DistanceTo(point)
	return (point - self:GetPosition()).magnitude
end

function Character:DistanceToSquared(point)
	local delta = point - self:GetPosition()
	
	return delta.X ^ 2 + delta.Y ^ 2 + delta.Z ^ 2
end

function Character:IsPointInRange(point, range)
	range = range ^ 2
	local delta = (point - self:GetPosition())
	local distSq = delta.X ^ 2 + delta.Y ^ 2 + delta.Z ^ 2
	return distSq <= range
end

function Character:SetCollisionGroup(groupName)
	local physicsService = game:GetService("PhysicsService")
	for _, object in pairs(self.Model:GetDescendants()) do
		if object:IsA("BasePart") then
			physicsService:SetPartCollisionGroup(object, groupName)
		end
	end
end

function Character:Raycast(ray)
	local run = self:GetService("GameService").CurrentRun
	local dungeon = run.Dungeon.Model
	
	local ignoreList = {}
	for _, child in pairs(workspace:GetChildren()) do
		if child ~= dungeon then
			table.insert(ignoreList, child)
		end
	end
	
	return Super.Raycast(self, ray, ignoreList, function(part)
		if (not part.CanCollide) then
			return true
		end
		
		if game:GetService("CollectionService"):HasTag(part, "InvisibleWall") then
			return true
		end
		
		return false
	end)
end

function Character:DoesPointHaveFloor(point, dy)
	local part = self:Raycast(Ray.new(point + Vector3.new(0, dy or 0, 0), Vector3.new(0, -32, 0)))
	return part ~= nil
end

function Character:CanSeePoint(point)
	local delta = point - self:GetPosition()
	local ray = Ray.new(self:GetPosition(), delta)
	local _, rayEnd = self:Raycast(ray)
	
	return rayEnd:FuzzyEq(point)
end

function Character:CanSee(character)
	return self:CanSeePoint(character:GetPosition())
end

function Character:SoundPlay(soundName)
	local sound = self.Storage.Sounds:FindFirstChild(soundName)
	if sound then
		return self:SoundPlayByObject(sound)
	end
end

function Character:SoundPlayByObject(sound)
	sound = sound:Clone()
	
	if sound:FindFirstChild("Offset") then
		sound.TimePosition = sound.Offset.Value
	end
	
	sound.Parent = self.Root
	sound:Play()
	game:GetService("Debris"):AddItem(sound, sound.TimeLength / sound.PlaybackSpeed)
	
	return sound
end

function Character:OnDamaged(damage)
	for _, status in pairs(self.Statuses) do
		if status.OnDamaged then
			status:OnDamaged(damage)
		end
	end
end

return Character
