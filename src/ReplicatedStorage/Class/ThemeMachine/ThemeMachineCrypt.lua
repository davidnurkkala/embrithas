local Super = require(script.Parent)
local ThemeMachineCrypt = Super:Extend()

function ThemeMachineCrypt:GenerateFeatures(tile)
	self:GenerateFeatureWallDecoration(tile)
	self:GenerateFeatureFloorDecoration(tile)
end

local WallDecorationNames = {
	WallPillar = 4,
	WallCoffin1 = 1,
	WallCoffin2 = 1,
	WallCoffin3 = 1,
	WallCoffin4 = 1,
	WallCoffin5 = 1,
}
function ThemeMachineCrypt:GenerateFeatureWallDecoration(tile)
	if (self.Random:NextInteger(1, 8) == 1) and self:IsTileWall(tile) then
		local rotation = 0
		if tile.Walls.NegY then
			rotation = 1
		elseif tile.Walls.PosX then
			rotation = 2
		elseif tile.Walls.PosY then
			rotation = 3
		end
		
		local modelName = self:GetWeightedResult(WallDecorationNames, self.Random)
		local feature = self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = rotation,
			Model = self.Storage.Models.Crypt[modelName],
			Dungeon = self.Dungeon,
			PlacementType = "Back",
		}
		
		if self.Dungeon:IsFeatureAgainstWall(feature) then
			self.Dungeon:ApplyFeatureIfFits(feature)
		end
	end
end

local FloorDecorationNames = {
	Coffin1 = 8,
	Coffin2 = 8,
	Coffin3 = 8,
	Coffin4 = 8,
	Coffin5 = 8,
	Coffin6 = 8,
	Coffin7 = 8,
	Coffin8 = 8,
	Coffin9 = 9,
	
	Pot1 = 8,
	Pot2 = 8,
	Pot3 = 8,
	Pot4 = 8,
	Pot5 = 8,
	Pot6 = 8,
	Pot7 = 8,
	Pot8 = 8,
}
local PillarAndBrazier = {
	Brazier = 3,
	Pillar = 2,
}

function ThemeMachineCrypt:GenerateFeatureFloorDecoration(tile)
	if not tile.Filled then return end
	
	if self.Random:NextInteger(1, 32) == 1 then
		local modelName = self:GetWeightedResult(FloorDecorationNames, self.Random)
		local feature = self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = self.Random:NextInteger(0, 3),
			Model = self.Storage.Models.Crypt[modelName],
			Dungeon = self.Dungeon,
			PlacementType = "Center",
		}
		self.Dungeon:ApplyFeatureIfFits(feature)
	end
	
	if self.Random:NextInteger(1, 16) == 1 then
		self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = self.Random:NextInteger(0, 3),
			Model = self.Storage.Models.Crypt["FloorSlate"..self.Random:NextInteger(1, 8)],
			Dungeon = self.Dungeon,
			PlacementType = "Center",
		})
	end
	
	if self.Random:NextInteger(1, 128) == 1 then
		local modelName = self:GetWeightedResult(PillarAndBrazier, self.Random)
		local feature = self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = self.Random:NextInteger(0, 3),
			Model = self.Storage.Models.Crypt[modelName],
			Dungeon = self.Dungeon,
			PlacementType = "Center",
		}
		self.Dungeon:ApplyFeatureIfFits(feature)
	end
end

function ThemeMachineCrypt:GetFloorPart()
	return self.Storage.Models.Crypt.Floor:Clone()
end

function ThemeMachineCrypt:GetWallPart()
	return self.Storage.Models.Crypt.Wall:Clone()
end

return ThemeMachineCrypt