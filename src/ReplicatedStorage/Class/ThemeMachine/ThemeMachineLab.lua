local Super = require(script.Parent)
local ThemeMachineLab = Super:Extend()

local Models = Super.Storage.Models.Lab

function ThemeMachineLab:GetDoorModel()
	return self.Storage.Models.Mine.Door:Clone()
end

function ThemeMachineLab:GenerateFeatures(tile)
	self:GenerateFeatureWallDecoration(tile)
	self:GenerateFeatureFloorDecoration(tile)
end

local FloorDecorationModelNames = {
	Cauldron1 = 8,
	Cauldron2 = 8,
	Cauldron3 = 8,
	Cauldron4 = 8,
	Cauldron5 = 8,
	
	Desk1 = 8,
	Desk2 = 8,
	Desk3 = 8,
	Desk4 = 8,
	Desk5 = 8,
	Desk6 = 8,
	
	Table1 = 8,
	Table2 = 8,
	Table3 = 8,
	Table4 = 8,
	Table5 = 8,
	Table6 = 8,
}
function ThemeMachineLab:GenerateFeatureFloorDecoration(tile)
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

local WallDecorationModelNames = {
	Shelf1 = 8,
	Shelf2 = 8,
	Shelf3 = 8,
	Shelf4 = 8,
	Shelf5 = 8,
	Shelf6 = 8,
	
	Tube = 8,
	TubeEmpty = 8,
	
	WallTube1 = 8,
	WallTube2 = 8,
	
	WallTorch = 64,
	WallTorchOut = 4,

	Counter1 = 8,
	Counter2 = 8,
	Counter3 = 8,
	Counter4 = 8,
	Counter5 = 8,
	Counter6 = 8,
}
function ThemeMachineLab:GenerateFeatureWallDecoration(tile)
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
			Model = Models[self:GetWeightedResult(WallDecorationModelNames, self.Random)],
			PlacementType = "Back",
			Dungeon = self.Dungeon,
		}
		
		if self.Dungeon:IsFeatureAgainstWall(feature) then
			self.Dungeon:ApplyFeatureIfFits(feature)
		end
	end
end

function ThemeMachineLab:GetFloorPart()
	return Models.Floor:Clone()
end

function ThemeMachineLab:GetWallPart()
	return Models.Wall:Clone()
end

return ThemeMachineLab