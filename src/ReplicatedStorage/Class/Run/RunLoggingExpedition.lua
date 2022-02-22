local Super = require(script.Parent)
local RunLoggingExpedition = Super:Extend()

RunLoggingExpedition.Enemies = {"Skeleton", "Skeleton Warrior", "Bone Archer"}

function RunLoggingExpedition:NewDungeon()
	math.randomseed(tick())
	
	local size = Vector2.new(2, 2)
	
	self.Dungeon = self:CreateNew"DungeonGranular"{
		Run = self,
		Level = self.RunData.Level + self.Floor,
		Theme = "Forest",
		SizeInChunks = size,
		ChestsEnabled = true,
		
		CustomGenerateRooms = function(dungeon)
			local chunkX = dungeon.Random:NextInteger(dungeon.PaddingChunks, dungeon.SizeInChunks.X - 1 - dungeon.PaddingChunks)
			local chunkY = dungeon.Random:NextInteger(dungeon.PaddingChunks, dungeon.SizeInChunks.Y - 1 - dungeon.PaddingChunks)
			local chunkPosition = Vector2.new(chunkX, chunkY)
			
			dungeon:ResetChunk(chunkPosition)
			
			local roomSize = dungeon.ChunkSize - dungeon.ChunkPadding
			local radius = roomSize.X / 2
			local center = Vector2.new(
				math.floor((roomSize.X - 1) / 2),
				math.floor((roomSize.Y - 1) / 2)
			)
			local pattern = {}
			for x = 0, roomSize.X - 1 do
				pattern[x] = {}
				for y = 0, roomSize.Y - 1 do
					local delta = center - Vector2.new(x, y)
					local d = delta.Magnitude
					local cell = {Filled = d < radius, NoFeatures = true}
					
					if x == center.X then
						if y == 0 then
							cell.Walls = {NegY = "Door"}
						elseif y == roomSize.Y - 1 then
							cell.Walls = {PosY = "Door"}
						end
					elseif y == center.Y then
						if x == 0 then
							cell.Walls = {NegX = "Door"}
						elseif x == roomSize.X - 1 then
							cell.Walls = {PosX = "Door"}
						end
					end
					
					if x == center.X and y == center.Y then
						cell.FloorItems = {"IskithTree"}
					end
					
					pattern[x][y] = cell
				end
			end
			dungeon:ApplyPattern(pattern, roomSize, chunkPosition * dungeon.ChunkSize)
			
			local startRoomLegalChunkGrid = {}
			for x = 0, dungeon.SizeInChunks.X - 1 do
				startRoomLegalChunkGrid[x] = {}
				for y = 0, dungeon.SizeInChunks.Y - 1 do
					local isIllegal = (x == chunkX) and (y == chunkY)
					startRoomLegalChunkGrid[x][y] = not isIllegal
				end
			end
			dungeon.StartRoomLegalChunkGrid = startRoomLegalChunkGrid
		end
	}
	
	self:StartDungeon()
end

function RunLoggingExpedition:CheckForVictory()
	return self.Floor > 5
end

function RunLoggingExpedition:RequestEnemy()
	return self.Enemies[math.random(1, #self.Enemies)]
end

return RunLoggingExpedition