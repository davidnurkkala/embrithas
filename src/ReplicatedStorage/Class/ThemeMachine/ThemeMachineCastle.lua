local Super = require(script.Parent)
local ThemeMachineCastle = Super:Extend()

function ThemeMachineCastle:GenerateFeatures(tile)
	self:GenerateFeatureWallDecoration(tile)
	self:GenerateFeatureTable(tile)
end

local WallDecorationNames = {
	Shelf1 = 1,
	Shelf2 = 1,
	Shelf3 = 1,
	Shelf4 = 1,
	BrokenShelf = 1,
	Cabinet1 = 1,
	Cabinet2 = 1,
	Cabinet3 = 1,
	Cabinet4 = 1,
	Cabinet5 = 1,
	Desk = 1,
	Banner = 1,
	WallShelf1 = 1,
	WallShelf2 = 1,
	WallShelf3 = 1,
	BrokenWallShelf = 1,
	Mirror = 1,
	Stove = 2,
}
function ThemeMachineCastle:GenerateFeatureWallDecoration(tile)
	if (self.Random:NextInteger(1, 4) == 1) and self:IsTileWall(tile) then
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
			Model = self.Storage.Models.Castle[modelName],
			Dungeon = self.Dungeon,
			PlacementType = "Back",
		}
		
		if self.Dungeon:IsFeatureAgainstWall(feature) then
			self.Dungeon:ApplyFeatureIfFits(feature)
		end
	end
end

local ChairModelNames = {
	Chair = 4,
	Stool = 4,
	BrokenChair = 1
}
function ThemeMachineCastle:GenerateFeatureChair(position, rotation)
	if rotation == nil then rotation = self.Random:NextInteger(0, 3) end
	
	self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
		Position = position,
		Rotation = rotation,
		Model = self.Storage.Models.Castle[self:GetWeightedResult(ChairModelNames, self.Random)],
		Dungeon = self.Dungeon,
		PlacementType = "Center",
	})
end

local TableModelNames = {
	Table1 = 4,
	Table2 = 4,
	BrokenTable = 1
}
function ThemeMachineCastle:GenerateFeatureTable(tile)
	if self.Random:NextInteger(1, 128) ~= 1 then return end
	
	local rotation = self.Random:NextInteger(0, 3)
	
	local feature = self:CreateNew"DungeonFeature"{
		Position = tile.Position,
		Rotation = rotation,
		Model = self.Storage.Models.Castle[self:GetWeightedResult(TableModelNames, self.Random)],
		Dungeon = self.Dungeon,
		PlacementType = "Center",
	}
	local success = self.Dungeon:ApplyFeatureIfFits(feature)
	
	if success and self.Random:NextInteger(1, 2) == 1 then
		local size, position = feature:GetFootprint()
		if rotation == 0 or rotation == 2 then
			for dy = 0, size.Y - 1 do
				self:GenerateFeatureChair(Vector2.new(position.X - 1, position.Y + dy), 0)
				self:GenerateFeatureChair(Vector2.new(position.X + size.X, position.Y + dy), 2)
			end
		else
			for dx = 0, size.X - 1 do
				self:GenerateFeatureChair(Vector2.new(position.X + dx, position.Y - 1), 1)
				self:GenerateFeatureChair(Vector2.new(position.X + dx, position.Y + size.Y), 3)
			end
		end
	end
end

return ThemeMachineCastle