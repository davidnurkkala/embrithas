local Super = require(script.Parent)
local Room = Super:Extend()

function Room:OnCreated()
	assert(self.Dungeon)
	
	self.State = "Inactive"
	
	self.Completed = self:CreateNew"Event"()
	self.Activated = self:CreateNew"Event"()
	
	self.FloorItems = {}
end

function Room:GetSpawn(useSpawn)
	error("Base room GetSpawn called.")
end

function Room:Activate()
	error("Base room Activate called.")
end

function Room:Complete()
	self.State = "Completed"
	self.Completed:Fire()
end

function Room:GetDefaultEncounterData()
	local count = math.random(4, 8)
	local totalHealthMultiplier = 4
	local healthMultiplier = totalHealthMultiplier / count

	local difficulty = self.Dungeon.Run:GetDifficultyData()
	if difficulty.ExtraSpawns then
		count += math.random(difficulty.ExtraSpawns[1], difficulty.ExtraSpawns[2])
	end

	return {
		Type = "Mob",
		Count = count,
		Level = self.Dungeon.Level,
		HealthMultiplier = healthMultiplier,
	}
end

function Room:GetLevelFromEncounter(data)
	if data.Level then
		return data.Level
	elseif data.LevelDelta then
		return math.max(1, self.Dungeon.Level + data.LevelDelta)
	else
		return self.Dungeon.Level
	end
end

return Room