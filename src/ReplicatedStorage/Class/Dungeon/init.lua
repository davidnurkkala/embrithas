local Super = require(script.Parent)
local Dungeon = Super:Extend()

Dungeon.ChestsEnabled = true
Dungeon.GoldEnabled = false

Dungeon.ChestChance = 1 / 6

function Dungeon:OnCreated()
	self.Active = true
	self.HasStarted = false
	self.Completed = self:CreateNew"Event"()
	self.Started = self:CreateNew"Event"()
	
	self.KickedDownDoorPositions = {}
end

function Dungeon:Start()
	if self.HasStarted then return end
	self.HasStarted = true
	self.Started:Fire()
end

function Dungeon:GetRespawnPosition(deathPosition)
	if (deathPosition == nil) or (#self.KickedDownDoorPositions == 0) then
		return self.StartRoom:GetSpawn(false) + Vector3.new(0, 4, 0)
	else
		local bestPosition
		local bestDistance = math.huge
		for _, position in pairs(self.KickedDownDoorPositions) do
			local delta = position - deathPosition
			local distanceSq = delta.X ^ 2 + delta.Z ^ 2
			if distanceSq < bestDistance then
				bestDistance = distanceSq
				bestPosition = position
			end
		end
		
		return bestPosition
	end
end

function Dungeon:OnDoorKickedDown(door)
	table.insert(self.KickedDownDoorPositions, door.CFrame.Position)
	
	self:FireRemoteAll("DoorKickedDown", door.CFrame.Position)
end

function Dungeon:GetSpawnLocationsOnCircle(position, radius)
	position = Vector3.new(position.X, 0, position.Z)
	local scanHeight = 16
	
	local circumference = 2 * radius * math.pi
	local count = circumference / 2
	local thetaStep = math.pi * 2 / count

	local ignoreList = {}
	for _, child in pairs(workspace:GetChildren()) do
		if child ~= self.Model then
			table.insert(ignoreList, child)
		end
	end

	local locations = {}
	
	for step = 0, count - 1 do
		local theta = thetaStep * step
		local dx = math.cos(theta) * radius
		local dz = math.sin(theta) * radius
		local dy = scanHeight
		local p = position + Vector3.new(dx, dy, dz)
		local ray = Ray.new(p, Vector3.new(0, -scanHeight * 2, 0))
		local part, point = self:Raycast(ray, ignoreList)

		if part and (point.Y > -1) and (point.Y < 4) then
			table.insert(locations, point)
		end
	end

	return locations
end

function Dungeon:DistributeEncounters(encounters)
	print("Base dungeon DistributeEncounters called.")
end

return Dungeon