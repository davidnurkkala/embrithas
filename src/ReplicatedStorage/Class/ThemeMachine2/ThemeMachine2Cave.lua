local Super = require(script.Parent)
local ThemeMachineCave = Super:Extend()

function ThemeMachineCave:GenerateFeatures(grid, cell)
	if not cell then return end
	self:GenerateFeatureFloorDecoration(grid, cell)
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
function ThemeMachineCave:GenerateFeatureFloorDecoration(grid, cell)
	if self.Random:NextInteger(1, 32) == 1 then
		self.Dungeon:ApplyFeatureIfFits(grid, self:CreateNew"DungeonFeature"{
			Position = cell.Position,
			Rotation = self.Random:NextInteger(0, 3),
			Model = self.Storage.Models.Cave[self:GetWeightedResult(FloorDecorationModelNames, self.Random)],
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

function ThemeMachineCave:CreatePatterns(roomCount)
	local patterns = {}
	
	for roomNumber = 1, roomCount do
		local size = Vector2.new(
			self.Random:NextInteger(12, 36),
			self.Random:NextInteger(12, 36)
		)
		
		table.insert(patterns, self:CreatePatternOrganic(size, 3))
	end
	
	return patterns
end

function ThemeMachineCave:PostBuild(grid, min, max)
	self:TerrainFillTiles("Empty", grid, min, max, Enum.Material.Rock)
end

return ThemeMachineCave