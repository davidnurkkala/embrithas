local Super = require(script.Parent)
local ThemeMachineSwamp = Super:Extend()

local TerrainSettings = {
	WaterColor = Color3.fromRGB(75, 85, 75),
	WaterReflectance = 0,
	CollisionGroupId = game:GetService("PhysicsService"):GetCollisionGroupId("Debris")
}

function ThemeMachineSwamp:SetUpLighting()
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 12
	lighting.Brightness = 1
	
	lighting:ClearAllChildren()
	self.Storage.Models.OutdoorSky:Clone().Parent = lighting
	
	local originalTerrainSettings = {}
	for key, val in pairs(TerrainSettings) do
		originalTerrainSettings[key] = workspace.Terrain[key]
		workspace.Terrain[key] = val
	end
	self.OriginalTerrainSettings = originalTerrainSettings
end

function ThemeMachineSwamp:CleanUp()
	for key, val in pairs(self.OriginalTerrainSettings) do
		workspace.Terrain[key] = val
	end
end

local Trees = {
	Tree1 = 6,
	Tree2 = 1,
}
local FloorModels = {
	Rock1 = 4,
	Rock2 = 4,
	Rock3 = 4,
	
	Roots1 = 4,
	Roots2 = 4,
	
	Crates1 = 2,
	Crates2 = 2,
	Crates3 = 2,
	Crates4 = 2,
}
function ThemeMachineSwamp:GenerateFeatures(tile)
	local function feature(modelName, requiresFilled)
		if requiresFilled == nil then requiresFilled = true end
		
		self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
			RequiresFilled = requiresFilled,
			Position = tile.Position,
			Rotation = self.Random:NextInteger(0, 3),
			Model = self.Storage.Models.Swamp[modelName],
			Dungeon = self.Dungeon,
			PlacementType = "Center",
		})
	end
	
	if self.Random:NextInteger(1, 64) == 1 then
		feature(self:GetWeightedResult(Trees, self.Random))
	end
	
	if self.Random:NextInteger(1, 32) == 1 then
		feature(self:GetWeightedResult(FloorModels, self.Random))
	end
	
	if not tile.Filled and self.Random:NextInteger(1, 128) == 1 then
		feature("LilyPad"..self.Random:NextInteger(1, 2), false)
	end
end

function ThemeMachineSwamp:GenerateCustom()
	local size = self.Dungeon.SizeInChunks * self.Dungeon.ChunkSize * self.Dungeon.TileSize
	
	local cframe = CFrame.new(size.X / 2, -4, size.Y / 2)
	size = Vector3.new(size.X, 4, size.Y)
	
	workspace.Terrain:FillBlock(cframe, size, Enum.Material.Water)
	cframe = cframe - Vector3.new(0, 4, 0)
	workspace.Terrain:FillBlock(cframe, size, Enum.Material.Mud)
end

function ThemeMachineSwamp:PreRender()
	self.Dungeon.FloorThickness = 8
end

function ThemeMachineSwamp:GetFloorPart()
	return self.Storage.Models.Swamp.Floor:Clone()
end

function ThemeMachineSwamp:GetWallPart()
	local wall = self.Storage.Models.Swamp.Wall:Clone()
	wall.Transparency = 1
	return wall
end

function ThemeMachineSwamp:GetDoorModel()
	return self.Storage.Models.Swamp.Door:Clone()
end

function ThemeMachineSwamp:GenerateChunk(chunkPosition)
	local chunkSize = self.Dungeon.ChunkSize
	local roomSize = chunkSize - self.Dungeon.ChunkPadding
	
	local patternArgs = {self:CreateLargeCaveRoom(roomSize, chunkPosition * chunkSize, 4)}
	self.Dungeon:ApplyPattern(unpack(patternArgs))
end

return ThemeMachineSwamp