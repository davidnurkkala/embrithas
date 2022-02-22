local Super = require(script.Parent)
local Run = Super:Extend()

Run.Enemies = {"Orc", "Orc Archer", "Orc Bulwark", "Orc Brute", "Orc Berserker"}

function Run:NewDungeon()
	math.randomseed(tick())
	
	local size = Vector2.new(5, 5)
	
	self.Dungeon = self:CreateNew"DungeonGranular"{
		Run = self,
		Level = self.RunData.Level + self.Floor,
		Theme = "Mountain",
		ChestsEnabled = true,
		
		ChunkMap = {
			"#####",
			"#####",
			"#####",
			"#####",
			"#####",
		},
		
		CustomGenerateRooms = function(dungeon)
			local chunkPosition = Vector2.new(3, 3)
			
			dungeon:ResetChunk(chunkPosition)
			
			local chunkSize = dungeon.ChunkSize - dungeon.ChunkPadding
			local roomSize = self:MapVector2(chunkSize / 2, math.floor)
			local roomPosition = self:MapVector2(chunkSize / 2 - roomSize / 2, math.floor)
			
			local pattern, size, position = dungeon.ThemeMachine:CreateSquareRoom(roomSize, chunkPosition * dungeon.ChunkSize + roomPosition)
			
			-- mining camp in the center
			local center = self:MapVector2(roomSize / 2, math.floor)
			pattern[center.X][center.Y].FloorItems = {"MiningCamp"}
			
			-- no other features in this room
			for x, row in pairs(pattern) do
				for y, cell in pairs(row) do
					cell.NoFeatures = true
					
					local delta = Vector2.new(x, y) - center
					local d = math.max(math.abs(delta.X), math.abs(delta.Y))
					if d > 2 then
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

function Run:OnPlayerAdded(player)
	Super.OnPlayerAdded(self, player)
	
	self:GetService("EffectsService"):RequestEffect(player, "Thunderstorm", {})
end

function Run:CheckForVictory()
	return self.Floor > 1
end

function Run:RequestEnemy()
	return self.Enemies[math.random(1, #self.Enemies)]
end

return Run