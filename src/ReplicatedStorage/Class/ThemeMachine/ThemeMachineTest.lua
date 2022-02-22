local Super = require(script.Parent)
local ThemeMachineTest = Super:Extend()

function ThemeMachineTest:GenerateChunk(chunkPosition)
	local chunkSize = self.Dungeon.ChunkSize
	local roomSize = chunkSize - self.Dungeon.ChunkPadding
	
	self.Dungeon:ApplyPattern(self:CreateSquareRoom(roomSize, chunkPosition * chunkSize))
end

return ThemeMachineTest