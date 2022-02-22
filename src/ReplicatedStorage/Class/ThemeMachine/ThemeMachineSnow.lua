local Super = require(script.Parent)
local ThemeMachineSnow = Super:Extend()

function ThemeMachineSnow:SetUpLighting()
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 12
	lighting.Brightness = 2
	
	lighting:ClearAllChildren()
	self.Storage.Models.OutdoorSky:Clone().Parent = lighting
end

function ThemeMachineSnow:GenerateFeatures(tile)
	if not tile.TerrainFilled then
		self:TerrainFillEmptyTiles(tile.Position, Enum.Material.Snow)
	end
	
	self:GenerateFeatureFloorDecoration(tile)
end

local FloorDecorationModelNames = {
	Campfire = 16,
	CampfireOut = 16,
	
	IcePillarCommon = 16,
	
	IceSpikes1 = 16,
	IceSpikes2 = 16,
	IceSpikes3 = 16,
	IceSpikes4 = 16,
	IceSpikes5 = 16,
	IceSpikes6 = 16,
	
	SnowPile1 = 16,
	SnowPile10 = 16,
	SnowPile11 = 16,
	SnowPile12 = 16,
	SnowPile18 = 16,
	SnowPile13 = 16,
	SnowPile14 = 16,
	SnowPile15 = 16,
	SnowPile16 = 16,
	SnowPile17 = 16,
	SnowPile2 = 16,
	SnowPile3 = 16,
	SnowPile4 = 16,
	SnowPile5 = 16,
	SnowPile6 = 16,
	SnowPile7 = 16,
	SnowPile8 = 16,
	SnowPile9 = 16,
	
	SnowPileBreakable1 = 16,
	SnowPileBreakable2 = 16,
	SnowPileBreakable3 = 16,
	SnowPileBreakable4 = 16,
	
	SnowPileRare = 1,
	IcePillarRare = 1,
	Snowman = 1,
	
	SpikePile1 = 16,
	SpikePile2 = 16,
	SpikePile3 = 16,
}
function ThemeMachineSnow:GenerateFeatureFloorDecoration(tile)
	if self.Random:NextInteger(1, 32) == 1 then
		self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = self.Random:NextInteger(0, 3),
			Model = self.Storage.Models.Snow[self:GetWeightedResult(FloorDecorationModelNames, self.Random)],
			PlacementType = "Center",
			Dungeon = self.Dungeon,
		})
	end
end

function ThemeMachineSnow:GetFloorPart()
	return self.Storage.Models.Snow.Floor:Clone()
end

function ThemeMachineSnow:GetWallPart()
	return self.Storage.Models.Snow.Wall:Clone()
end

function ThemeMachineSnow:GetDoorModel()
	return self.Storage.Models.Snow.Door:Clone()
end

local RoomTypes = {
	Square = 8,
	Circle = 8,
	Cave = 24,
}

function ThemeMachineSnow:GenerateChunk(chunkPosition)
	local chunkSize = self.Dungeon.ChunkSize
	local roomSize = chunkSize - self.Dungeon.ChunkPadding
	local choice = self:GetWeightedResult(RoomTypes, self.Random)
	
	local patternArgs = {}
					
	if choice == "Square" then
		local size = Vector2.new(
			self.Random:NextInteger(16, 32),
			self.Random:NextInteger(16, 32)
		)
		
		local position = Vector2.new(
			self.Random:NextInteger(0, roomSize.X - size.X - 1),
			self.Random:NextInteger(0, roomSize.Y - size.Y - 1)
		)
		position = position + chunkPosition * chunkSize
		
		patternArgs = {self:CreateSquareRoom(size, position)}
	
	elseif choice == "Circle" then
		local diameter = self.Random:NextInteger(16, 32)
		
		local position = Vector2.new(
			self.Random:NextInteger(0, roomSize.X - diameter - 1),
			self.Random:NextInteger(0, roomSize.Y - diameter - 1)
		)
		position = position + chunkPosition * chunkSize
		
		local subChoice = self.Random:NextInteger(1, 2)
		
		if subChoice == 1 then
			patternArgs = {self:CreateCircularRoom(diameter, position)}
		elseif subChoice == 2 then
			local innerDiameter = diameter - self.Random:NextInteger(12, diameter - 4)
			
			patternArgs = {self:CreateRingRoom(diameter, innerDiameter, position)}
		end
	elseif choice == "Cave" then
		patternArgs = {self:CreateLargeCaveRoom(roomSize, chunkPosition * chunkSize, 4)}
	end
	
	self.Dungeon:ApplyPattern(unpack(patternArgs))
end

return ThemeMachineSnow