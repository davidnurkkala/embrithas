local Super = require(script.Parent)
local ThemeMachineCastle = Super:Extend()

function ThemeMachineCastle:GenerateFeatures(grid, cell)
	if not cell then return end
	self:GenerateFeatureWallDecoration(grid, cell)
	self:GenerateFeatureTable(grid, cell)
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
function ThemeMachineCastle:GenerateFeatureWallDecoration(grid, cell)
	if (self.Random:NextInteger(1, 4) == 1) and self:IsCellWall(cell) then
		local rotation = 0
		if cell.Walls.NegY then
			rotation = 1
		elseif cell.Walls.PosX then
			rotation = 2
		elseif cell.Walls.PosY then
			rotation = 3
		end
		
		local modelName = self:GetWeightedResult(WallDecorationNames, self.Random)
		local feature = self:CreateNew"DungeonFeature"{
			Position = cell.Position,
			Rotation = rotation,
			Model = self.Storage.Models.Castle[modelName],
			Dungeon = self.Dungeon,
			PlacementType = "Back",
		}
		
		if self.Dungeon:IsFeatureAgainstWall(grid, feature) then
			self.Dungeon:ApplyFeatureIfFits(grid, feature)
		end
	end
end

local ChairModelNames = {
	Chair = 4,
	Stool = 4,
	BrokenChair = 1
}
function ThemeMachineCastle:GenerateFeatureChair(grid, position, rotation)
	if rotation == nil then rotation = self.Random:NextInteger(0, 3) end
	
	self.Dungeon:ApplyFeatureIfFits(grid, self:CreateNew"DungeonFeature"{
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
function ThemeMachineCastle:GenerateFeatureTable(grid, cell)
	if self.Random:NextInteger(1, 128) ~= 1 then return end
	
	local rotation = self.Random:NextInteger(0, 3)
	
	local feature = self:CreateNew"DungeonFeature"{
		Position = cell.Position,
		Rotation = rotation,
		Model = self.Storage.Models.Castle[self:GetWeightedResult(TableModelNames, self.Random)],
		Dungeon = self.Dungeon,
		PlacementType = "Center",
	}
	local success = self.Dungeon:ApplyFeatureIfFits(grid, feature)
	
	if success and self.Random:NextInteger(1, 2) == 1 then
		local size, position = feature:GetFootprint()
		if rotation == 0 or rotation == 2 then
			for dy = 0, size.Y - 1 do
				self:GenerateFeatureChair(grid, Vector2.new(position.X - 1, position.Y + dy), 0)
				self:GenerateFeatureChair(grid, Vector2.new(position.X + size.X, position.Y + dy), 2)
			end
		else
			for dx = 0, size.X - 1 do
				self:GenerateFeatureChair(grid, Vector2.new(position.X + dx, position.Y - 1), 1)
				self:GenerateFeatureChair(grid, Vector2.new(position.X + dx, position.Y + size.Y), 3)
			end
		end
	end
end

local PatternFunctionNames = {
	Large = 1,
	Medium = 3,
	Small = 6,
	Hall = 1,
	Corner = 1,
}
local PatternFunctions = {
	Large = function(self)
		local size = self.Random:NextInteger(18, 24)
		return self:CreatePatternRectangle(Vector2.new(size, size))
	end,
	Medium = function(self)
		local size = self.Random:NextInteger(12, 18)
		return self:CreatePatternRectangle(Vector2.new(size, size))
	end,
	Small = function(self)
		local size = self.Random:NextInteger(6, 12)
		return self:CreatePatternRectangle(Vector2.new(size, size))
	end,
	Hall = function(self)
		local length = self.Random:NextInteger(24, 36)
		length = math.floor(length / 4) * 4
		local width = length / 4
		return self:CreatePatternRectangle(Vector2.new(width, length))
	end,
	Corner = function(self)
		local size = Vector2.new(
			self.Random:NextInteger(12, 24),
			self.Random:NextInteger(12, 24)
		)
		local width = self.Random:NextInteger(6, 9)
		return self:CreatePatternCorner(size, width)
	end,
	
	Ring = function(self)
		local size = Vector2.new(1, 1) * 60
		local width = 4
		return self:CreatePatternSquareRingWithInternalDoors(size, width)
	end
}
function ThemeMachineCastle:CreatePatterns(roomCount)
	local patterns = {}
	
	if self.Random:NextInteger(1, 3) == 1 then
		roomCount -= 1
		table.insert(patterns, PatternFunctions.Ring(self))
	end
	
	for roomNumber = 1, roomCount do
		table.insert(patterns, PatternFunctions[self:GetWeightedResult(PatternFunctionNames, self.Random)](self))
	end
	
	return patterns
end

return ThemeMachineCastle