--fire_king66 was here

local Super = require(script.Parent)
local ThemeMachineFrozenCastle = Super:Extend()

function ThemeMachineFrozenCastle:GenerateFeatures(tile)
	self:GenerateFeatureWallDecoration(tile)
	self:GenerateFeatureTable(tile)
	self:GenerateFeatureFloorDecoration(tile)
end

local Models = Super.Storage.Models.FrozenCastle

local FloorDecorationModelNames = {
	SnowPile1 = 16,
	SnowPile10 = 16,
	SnowPile11 = 16,
	SnowPile12 = 16,
	SnowPile13 = 16,
	SnowPile14 = 16,
	SnowPile15 = 16,
	SnowPile2 = 64,
	SnowPile3 = 64,
	SnowPile4 = 16,
	SnowPile5 = 16,
	SnowPile6 = 16,
	SnowPile7 = 16,
	SnowPile8 = 16,
	SnowPile9 = 16,
	
	SnowPileBreakable1 = 64,
	SnowPileBreakable2 = 64,
	SnowPileBreakable3 = 64,
	SnowPileBreakable4 = 64,
	
	SpikePile1 = 16,
	SpikePile2 = 16,
	SpikePile3 = 16,
	SpikePile4 = 64,
}
function ThemeMachineFrozenCastle:GenerateFeatureFloorDecoration(tile)
	if self.Random:NextInteger(1, 48) == 1 then
		self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = self.Random:NextInteger(0, 3),
			Model = Models[self:GetWeightedResult(FloorDecorationModelNames, self.Random)],
			PlacementType = "Center",
			Dungeon = self.Dungeon,
		})
	end
end

local WallDecorationNames = {
	Bookshelf = 1,
	Fireplace = 1,
}
function ThemeMachineFrozenCastle:GenerateFeatureWallDecoration(tile)
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
			Model = Models[modelName],
			Dungeon = self.Dungeon,
			PlacementType = "Back",
		}
		
		if self.Dungeon:IsFeatureAgainstWall(feature) then
			self.Dungeon:ApplyFeatureIfFits(feature)
		end
	end
end

local ChairModelNames = {
	ChairDestroyed = 1,
	ChairDestroyedSnowy = 1,
}
function ThemeMachineFrozenCastle:GenerateFeatureChair(position, rotation)
	if rotation == nil then rotation = self.Random:NextInteger(0, 3) end
	
	self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
		Position = position,
		Rotation = rotation,
		Model = Models[self:GetWeightedResult(ChairModelNames, self.Random)],
		Dungeon = self.Dungeon,
		PlacementType = "Center",
	})
end

local TableModelNames = {
	Table1 = 4,
	Table2 = 4,
}
function ThemeMachineFrozenCastle:GenerateFeatureTable(tile)
	if self.Random:NextInteger(1, 128) ~= 1 then return end
	
	local rotation = self.Random:NextInteger(0, 3)
	
	local feature = self:CreateNew"DungeonFeature"{
		Position = tile.Position,
		Rotation = rotation,
		Model = Models[self:GetWeightedResult(TableModelNames, self.Random)],
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

return ThemeMachineFrozenCastle