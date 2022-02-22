local PhysicsService = game:GetService("PhysicsService")

local Super = require(script.Parent)
local TileSet = Super:Extend()

function TileSet:OnCreated()
	self.Tiles = {
		DeadEnd = {},
		Corner = {},
		Hallway = {},
		ThreeWay = {},
		FourWay = {},
	}
	
	self.Doors = {}
	
	self.Features = {
		Rotatable = {},
		Oriented = {},
	}
	
	self.Lighting = {
		Attributes = {},
	}
	
	if not self.Random then
		self.Random = Random.new()
	end
	
	self:ProcessData()
end

function TileSet:GetSizeKey(part)
	return string.format("%s,%s", part.Size.X, part.Size.Z)
end

function TileSet:ProcessData()
	local folder = self.Storage.TileSets:FindFirstChild(self.TileSetName)
	
	for _, model in pairs(folder.Tiles:GetChildren()) do
		self.Tiles[model.Name][model] = model:GetAttribute("Weight") or 1
	end
	
	for _, model in pairs(folder.Doors:GetChildren()) do
		self.Doors[model] = model:GetAttribute("Weight") or 1
	end
	
	for _, model in pairs(folder.Features:GetChildren()) do
		local root = model.PrimaryPart
		if not root then error(string.format([[Fill "%s" was missing a PrimaryPart.]], model:GetFullName())) end
		
		local list
		if root:FindFirstChild("Orientation") then
			list = self.Features.Oriented
		else
			list = self.Features.Rotatable
		end
		
		local key = self:GetSizeKey(model.PrimaryPart)
		local subList = list[key]
		if not subList then
			subList = {}
			list[key] = subList
		end
		
		subList[model] = model:GetAttribute("Weight") or 1
	end
	
	local lighting = folder:FindFirstChild("Lighting")
	if lighting then
		for _, child in pairs(lighting:GetChildren()) do
			if child.Name == "SkyboxName" then
				self.Lighting.SkyboxName = child.Value
			else
				self.Lighting.Attributes[child.Name] = child.Value
			end
		end
	end
end

function TileSet:FillSlots(model)
	local features = Instance.new("Folder")
	features.Name = "__Features"
	
	for _, slot in pairs(model.__Slots:GetChildren()) do
		local isOriented = slot:FindFirstChild("Orientation") ~= nil 
		local list
		if isOriented then
			list = self.Features.Oriented
		else
			list = self.Features.Rotatable
		end
		
		local key = self:GetSizeKey(slot)
		local subList = list[key]
		if not subList then
			error(string.format([[Found %s slot of size %s but had no Features to put there.]], isOriented and "an oriented" or "a rotatable", key))
		end
		
		local feature = self:GetWeightedResult(subList, self.Random):Clone()
		local cframe = slot.CFrame * CFrame.new(0, -slot.Size.Y / 2, 0) * CFrame.new(0, -feature.PrimaryPart.Size.Y / 2, 0)
		if not isOriented then
			local rotations = self.Random:NextInteger(0, 3)
			cframe *= CFrame.Angles(0, math.pi / 2 * rotations, 0)
		end
		feature:SetPrimaryPartCFrame(cframe)
		feature.Parent = features
		
		slot:Destroy()
	end
	
	features.Parent = model
end

function TileSet:GetTile(tileType)
	local model = self:GetWeightedResult(self.Tiles[tileType], self.Random):Clone()
	
	for _, desc in pairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(desc, "Dungeon")
		end
	end
	
	if model:FindFirstChild("__Slots") then
		self:FillSlots(model)
	end
	
	return model
end

function TileSet:GetDoor()
	return self:GetWeightedResult(self.Doors, self.Random):Clone()
end

return TileSet