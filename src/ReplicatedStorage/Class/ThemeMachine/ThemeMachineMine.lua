local Super = require(script.Parent)
local ThemeMachineMine = Super:Extend()

function ThemeMachineMine:GetDoorModel()
	return self.Storage.Models.Mine.Door:Clone()
end

function ThemeMachineMine:GenerateFeatures(tile)
	self:GenerateFeatureCrumblingWall(tile)
	self:GenerateFeatureColumn(tile)
	self:GenerateFeatureMinecart(tile)
end

function ThemeMachineMine:GenerateFeatureMinecart(tile)
	if not tile.Filled then return end
	
	if self.Random:NextInteger(1, 128) == 1 then
		self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = self.Random:NextInteger(0, 3),
			PlacementType = "Center",
			Model = self.Storage.Models.Mine.Minecart,
			Dungeon = self.Dungeon,
		})
	end
end

local ColumnModelNames = {
	Column = 4,
	ColumnBroken = 1,
	ColumnTorch = 2,
}
function ThemeMachineMine:GenerateFeatureColumn(tile)
	if not tile.Walls then return end
	if not tile.Filled then return end
	
	local modelName = self:GetWeightedResult(ColumnModelNames, self.Random)
	
	local freq = 6
	if (tile.Walls.PosX == "Wall") or (tile.Walls.NegX == "Wall") then
		if tile.Position.Y % freq == 0 then
			self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
				Position = tile.Position,
				Rotation = (tile.Walls.PosX == "Wall") and 2 or 0,
				PlacementType = "Back",
				Model = self.Storage.Models.Mine[modelName],
				Dungeon = self.Dungeon,
			})
		end
	elseif (tile.Walls.PosY == "Wall") or (tile.Walls.NegY == "Wall") then
		if tile.Position.X % freq == 0 then
			self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
				Position = tile.Position,
				Rotation = (tile.Walls.PosY == "Wall") and 3 or 1,
				PlacementType = "Back",
				Model = self.Storage.Models.Mine[modelName],
				Dungeon = self.Dungeon,
			})
		end
	end
end

function ThemeMachineMine:GenerateFeatureCrumblingWall(tile)
	if (self.Random:NextInteger(1, 8) == 1) and self:IsTileWall(tile) then
		local rotation = 0
		if tile.Walls.NegY then
			rotation = 1
		elseif tile.Walls.PosX then
			rotation = 2
		elseif tile.Walls.PosY then
			rotation = 3
		end
		local feature = self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = rotation,
			Model = self.Storage.Models.Mine["CrumblingWall"..self.Random:NextInteger(1, 4)],
			Dungeon = self.Dungeon,
		}
		
		if self.Dungeon:IsFeatureAgainstWall(feature) then
			self.Dungeon:ApplyFeatureIfFits(feature)
		end
	end
end

function ThemeMachineMine:GetFloorPart()
	local floorPart = self.BasePart:Clone()
	floorPart.Material = Enum.Material.Pebble
	floorPart.Color = Color3.new(0.5, 0.5, 0.5)
	
	return floorPart
end

function ThemeMachineMine:GetWallPart()
	local wallPart = self.BasePart:Clone()
	wallPart.Material = Enum.Material.Slate
	wallPart.Color = Color3.new(0.5, 0.5, 0.5)
	
	return wallPart
end



--function ThemeMachineMine:GenerateChunk(chunkPosition)
--	local chunkSize = self.Dungeon.ChunkSize
--	local roomSize = chunkSize - self.Dungeon.ChunkPadding
--	
--	self.Dungeon:ApplyPattern(self:CreateSquareRoom(roomSize, chunkPosition * chunkSize))
--end

return ThemeMachineMine