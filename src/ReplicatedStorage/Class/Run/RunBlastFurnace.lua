local Super = require(script.Parent)
local Run = Super:Extend()

Run.Enemies = {"Fiery Corruption", "Stone Corruption"}

function Run:NewDungeon()
	math.randomseed(tick())
	
	local size = Vector2.new(5, 5)
	
	self.Dungeon = self:CreateNew"DungeonGranular"{
		Run = self,
		Level = self.RunData.Level + self.Floor,
		Theme = "MagmaCave",
		SizeInChunks = size,
		ChestsEnabled = true,
		
		CustomChunkGenerateGrid = function(dungeon, chunkGrid, carveBetween)
			for _, position in pairs{
					Vector2.new(2, 3),
					Vector2.new(4, 3),
					Vector2.new(3, 2),
					Vector2.new(3, 4),
				}
			do
				carveBetween(chunkGrid[3][3], chunkGrid[position.X][position.Y])
			end
		end,
		
		CustomGenerateRooms = function(dungeon)
			local chunkPosition = Vector2.new(3, 3)
			
			dungeon:ResetChunk(chunkPosition)
			
			local chunkSize = dungeon.ChunkSize - dungeon.ChunkPadding
			local roomSize = self:MapVector2(chunkSize / 2, math.floor)
			local roomPosition = self:MapVector2(chunkSize / 2 - roomSize / 2, math.floor)
			
			local pattern, size, position = dungeon.ThemeMachine:CreateSquareRoom(roomSize, chunkPosition * dungeon.ChunkSize + roomPosition)
			
			-- mining camp in the center
			local center = self:MapVector2(roomSize / 2, math.floor)
			pattern[center.X][center.Y].FloorItems = {"BlastFurnaceCamp"}
			
			-- no other features in this room
			for x, row in pairs(pattern) do
				for y, cell in pairs(row) do
					cell.NoFeatures = true
					
					local delta = Vector2.new(x, y) - center
					local d = math.max(math.abs(delta.X), math.abs(delta.Y))
					if d > 1 then
						cell.Occupied = true
					end
				end
			end
			
			dungeon:ApplyPattern(pattern, size, position)
			
			dungeon.StartRoomChunkPosition = chunkPosition
		end
	}
	
	self:StartDungeon()
end

function Run:CheckForVictory()
	return self.Floor > 1
end

function Run:RequestEnemy()
	return self.Enemies[math.random(1, #self.Enemies)]
end

return Run