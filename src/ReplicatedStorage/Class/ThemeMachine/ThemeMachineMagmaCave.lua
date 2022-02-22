local Super = require(script.Parent)
local ThemeMachineMagmaCave = Super:Extend()

local Models = Super.Storage.Models.Magma

function ThemeMachineMagmaCave:GenerateFeatures(tile)
	if not tile.TerrainFilled then
		self:TerrainFillEmptyTiles(tile.Position, Enum.Material.Basalt)
	end
	
	self:GenerateFeatureFloorDecoration(tile)
end

function ThemeMachineMagmaCave:SetUpLighting()
	Super.SetUpLighting(self)
	
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 12
	lighting.Brightness = 0.25
	
	lighting:ClearAllChildren()
	self.Storage.Models.RedSky:Clone().Parent = lighting
end

local BigModelNames = {
	MagmaCrack1 = 8,
	MagmaCrack2 = 8,
	MagmaCrack3 = 8,
	
	MagmaSpout1 = 8,
	MagmaSpout2 = 8,
}

local FloorDecorationModelNames = {
	Banner1 = 8,
	Banner2 = 8,
	
	Column1 = 8,
	Column2 = 8,
	Column3 = 8,
	Column4 = 8,
	
	Fence1 = 8,
	Fence2 = 8,
	Fence3 = 8,
	Fence4 = 8,
	Fence5 = 8,
	Fence6 = 8,
	
	FloorRock1 = 8,
	FloorRock2 = 8,
	FloorRock3 = 8,
	FloorRock4 = 8,
	
	Firepit1 = 8,
	Firepit2 = 8,
	Firepit3 = 8,
	
	MagmaGeyser1 = 8,
	MagmaGeyser2 = 8,
	
	Obelisk1 = 8,
	Obelisk2 = 8,
	Obelisk3 = 8,
	Obelisk4 = 8,
	Obelisk5 = 8,
	Obelisk6 = 8,
	
	Rock1 = 8,
	Rock2 = 8,
	Rock3 = 8,
	Rock4 = 8,
	RockRare = 2,
	
	Spike1 = 8,
	Spike2 = 8,
	Spike3 = 8,
	Spike4 = 8,
	Spike5 = 8,
	
	Trail1 = 8,
	Trail2 = 8,
	Trail3 = 8,
}
function ThemeMachineMagmaCave:GenerateFeatureFloorDecoration(tile)
	if self.Random:NextInteger(1, 32) == 1 then
		self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = self.Random:NextInteger(0, 3),
			Model = Models[self:GetWeightedResult(BigModelNames, self.Random)],
			PlacementType = "Center",
			Dungeon = self.Dungeon,
		})
	end
	
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

function ThemeMachineMagmaCave:GetFloorPart()
	return self.Storage.Models.Magma.Floor:Clone()
end

function ThemeMachineMagmaCave:GetWallPart()
	local wall = self.Storage.Models.Magma.Wall:Clone()
	wall.Transparency = 1
	return wall
end

function ThemeMachineMagmaCave:GetDoorjambPart()
	return self.Storage.Models.Magma.Wall:Clone()
end

function ThemeMachineMagmaCave:GenerateChunk(chunkPosition)
	local chunkSize = self.Dungeon.ChunkSize
	local roomSize = chunkSize - self.Dungeon.ChunkPadding
	
	self.Dungeon:ApplyPattern(self:CreateLargeCaveRoom(roomSize, chunkPosition * chunkSize, 3))
end

return ThemeMachineMagmaCave