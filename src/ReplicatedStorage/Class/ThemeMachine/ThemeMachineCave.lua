local Super = require(script.Parent)
local ThemeMachineCave = Super:Extend()

local Models = Super.Storage.Models.Cave

function ThemeMachineCave:GenerateFeatures(tile)
	if not tile.TerrainFilled then
		self:TerrainFillEmptyTiles(tile.Position, Enum.Material.Rock)
	end
	
	self:GenerateFeatureFloorDecoration(tile)
end

local FloorDecorationModelNames = {
	Column1 = 8,
	Column2 = 8,
	Column3 = 8,
	Column4 = 8,
	
	Stalagmite1 = 8,
	Stalagmite2 = 8,
	Stalagmite3 = 8,
	Stalagmite4 = 8,
	Stalagmite5 = 8,
}
function ThemeMachineCave:GenerateFeatureFloorDecoration(tile)
	if self.Random:NextInteger(1, 32) == 1 then
		self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = self.Random:NextInteger(0, 3),
			Model = Models[self:GetWeightedResult(FloorDecorationModelNames, self.Random)],
			PlacementType = "Center",
			Dungeon = self.Dungeon,
		})
	end
end

function ThemeMachineCave:GetFloorPart()
	return self.Storage.Models.Cave.Floor:Clone()
end

function ThemeMachineCave:GetWallPart()
	local wall = self.Storage.Models.Cave.Wall:Clone()
	wall.Transparency = 1
	return wall
end

function ThemeMachineCave:GetDoorjambPart()
	return self.Storage.Models.Cave.Wall:Clone()
end

function ThemeMachineCave:GenerateChunk(chunkPosition)
	local chunkSize = self.Dungeon.ChunkSize
	local roomSize = chunkSize - self.Dungeon.ChunkPadding
	
	self.Dungeon:ApplyPattern(self:CreateLargeCaveRoom(roomSize, chunkPosition * chunkSize, 3))
end

return ThemeMachineCave