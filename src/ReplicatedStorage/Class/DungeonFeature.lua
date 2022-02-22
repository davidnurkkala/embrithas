local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")

local Super = require(script.Parent)
local DungeonFeature = Super:Extend()

DungeonFeature.Position = Vector2.new()
DungeonFeature.Size = Vector2.new(1, 1)
DungeonFeature.Rotation = 0
DungeonFeature.PlacementType = "Corner"
DungeonFeature.RequiresFilled = true

function DungeonFeature:OnCreated()
	self:InitSize()
end

function DungeonFeature:GetCFrame()
	return self.Model:GetPrimaryPartCFrame()
end

function DungeonFeature:SetCFrame(cframe)
	self.Model:SetPrimaryPartCFrame(cframe)
end

function DungeonFeature:Rotate(cframe)
	self:SetCFrame(self:GetCFrame() * cframe)
end

function DungeonFeature:PlaceModel()
	local corner = Vector3.new(-1, -1, -1) / 2
	
	local delta
	if self.PlacementType == "Corner" then
		local position = self.Position
		local tileCenter = Vector3.new(position.X * self.Dungeon.TileSize, 0, position.Y * self.Dungeon.TileSize)
		local modelCorner = (
			self:GetCFrame() *
			CFrame.new(corner * self.Root.Size) *
			CFrame.new(-corner.X * self.Dungeon.TileSize, 0, -corner.Z * self.Dungeon.TileSize)
		).Position
		delta = tileCenter - modelCorner
	
	elseif self.PlacementType == "Back" then
		local size, position = self:GetFootprint()
		local center = position + (size - Vector2.new(1, 1)) / 2
		if self.Rotation == 0 then
			center = center + Vector2.new(-size.X / 2, 0)
		elseif self.Rotation == 1 then
			center = center + Vector2.new(0, -size.Y / 2)
		elseif self.Rotation == 2 then
			center = center + Vector2.new(size.X / 2, 0)
		elseif self.Rotation == 3 then
			center = center + Vector2.new(0, size.Y / 2)
		end
		
		local tileCenter = Vector3.new(center.X * self.Dungeon.TileSize, 0, center.Y * self.Dungeon.TileSize)
		local modelCenter = (
			self.Root.CFrame *
			CFrame.new(-self.Root.Size.X / 2, -self.Root.Size.Y / 2, 0)
		).Position
		delta = tileCenter - modelCenter
	
	elseif self.PlacementType == "Center" then
		local size, position = self:GetFootprint()
		local center = position + (size - Vector2.new(1, 1)) / 2
		local tileCenter = Vector3.new(center.X * self.Dungeon.TileSize, 0, center.Y * self.Dungeon.TileSize)
		local modelCenter = self.Root.Position - Vector3.new(0, self.Root.Size.Y / 2, 0)
		delta = tileCenter - modelCenter
	end
	
	self:SetCFrame(self:GetCFrame() + delta)
end

function DungeonFeature:InitSize()
	local _, size = self:GetAxisAlignedBoundingBox(self.Model)
	self.Size = Vector2.new(
		math.ceil(size.X / self.Dungeon.TileSize),
		math.ceil(size.Z / self.Dungeon.TileSize)
	)
end

function DungeonFeature:GetFootprint()
	local position = self.Position
	local size = self.Size
		
	if self.Rotation == 1 then
		position = Vector2.new(position.X - (size.Y - 1), position.Y)
		size = Vector2.new(size.Y, size.X)
	
	elseif self.Rotation == 2 then
		position = Vector2.new(position.X - (size.X - 1), position.Y - (size.Y - 1))
	
	elseif self.Rotation == 3 then
		position = Vector2.new(position.X, position.Y - (size.X - 1))
		size = Vector2.new(size.Y, size.X)
	end
	
	return size, position
end

function DungeonFeature:GetAxisAlignedBoundingBox(model)
	local extra = model:FindFirstChild("Extra")
	if extra then
		extra.Parent = nil
	end
	
	local cframe, size = model:GetBoundingBox()
	local max = (cframe * CFrame.new( size / 2)).Position
	local min = (cframe * CFrame.new(-size / 2)).Position
	size = Vector3.new(
		math.abs(max.X - min.X),
		math.abs(max.Y - min.Y),
		math.abs(max.Z - min.Z)
	)
	cframe = CFrame.new(cframe.Position)
	
	if extra then
		extra.Parent = model
	end
	
	return cframe, size
end

function DungeonFeature:InitModel()
	local model = self.Model:Clone()
	self.Model = model
	
	self:InitRoot()
end

function DungeonFeature:InitRoot()
	local cframe, size = self:GetAxisAlignedBoundingBox(self.Model)
	
	local root = Instance.new("Part")
	root.Name = "DungeonFeatureRoot"
	root.Anchored = true
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.Color = Color3.new(1, 0.5, 0.5)
	root.Size = size
	root.CFrame = cframe
	CollectionService:AddTag(root, "MapIgnored")
	root.Parent = self.Model
	
	self.Root = root
	self.Model.PrimaryPart = root
end

function DungeonFeature:ConvertToCylinder()
	local root = self.Root
	root.Shape = Enum.PartType.Cylinder
	
	local width = math.min(root.Size.X, root.Size.Z)
	local height = root.Size.Y
	
	root.Size = Vector3.new(height, width, width)
	root.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
end

function DungeonFeature:SetUpDebris(model)
	for _, desc in pairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(desc, "Debris")
		end
	end
end

function DungeonFeature:SetUpBreakable(model, root, callback)
	self:SetUpDebris(model)
	root.Transparency = 1
	
	local function onTouched(part)
		local character = self:GetClass("Legend").GetLegendFromPart(part)
		if not character then
			character = self:GetClass("Enemy").GetEnemyFromPart(part)
			if not character then return end
		end
		
		local canCollides = {}
		local debris = model:FindFirstChild("Debris")
		if debris then
			debris.Parent = model.Parent
			table.insert(canCollides, debris)
		end
		local extra = model:FindFirstChild("Extra")
		if extra then
			extra.Parent = model.Parent
			table.insert(canCollides, extra)
		end
		for _, model in pairs(canCollides) do
			for _, desc in pairs(model:GetDescendants()) do
				if desc:IsA("BasePart") then
					if desc.CanCollide then
						desc.CanCollide = false
						delay(2, function()
							desc.CanCollide = true
						end)
					end
				end
			end
		end
		
		root:Destroy()
		
		self:GetService("EffectsService"):RequestEffectAll("BreakBreakable", {
			Model = model,
			Position = character:GetFootPosition()
		})
		
		game:GetService("Debris"):AddItem(model, 3)

		if callback then
			callback()
		end
	end
	self:SafeTouched(root, onTouched)
end

function DungeonFeature:ApplyFeatureTags()
	local function hasTag(tag)
		return CollectionService:HasTag(self.Model, tag)
	end
	
	if hasTag("FeatureBlocker") then
		local debris = self.Model:FindFirstChild("Debris")
		local extra = self.Model:FindFirstChild("Extra")
		if debris then
			self:SetUpDebris(debris)
			debris.Parent = nil
		end
		if extra then
			self:SetUpDebris(extra)
			extra.Parent = nil
		end
		
		if extra or debris then
			self.Root:Destroy()
			self:InitRoot()
		end
		
		if debris then	
			debris.Parent = self.Model
		end
		if extra then
			extra.Parent = self.Model
		end
		
		-- only hitbox needs to be collideable
		for _, desc in pairs(self.Model:GetDescendants()) do
			if desc:IsA("BasePart") and desc ~= self.Root then
				desc.CanCollide = false
			end
		end
		
		local delta = Vector3.new(0, self.Dungeon.WallHeight - self.Root.Size.Y, 0)
		self.Root.Size = self.Root.Size + delta
		self.Root.Position = self.Root.Position + (delta / 2)
		
		if hasTag("FeatureCylindrical") then
			self:ConvertToCylinder()
		end
			
		self.Root.Transparency = 1
		
		CollectionService:AddTag(self.Root, "InvisibleWall")
	
	elseif hasTag("FeatureDebris") then
		self:SetUpDebris(self.Model)
		self.Root:Destroy()
	
	elseif hasTag("FeatureBreakable") then
		self:SetUpBreakable(self.Model, self.Root)
		
	else
		self.Root:Destroy()
	end
end

function DungeonFeature:Finalize()
	self:InitModel()
	
	self:Rotate(CFrame.Angles(0, (-math.pi / 2) * self.Rotation, 0))
	self:PlaceModel()
	
	self:ApplyFeatureTags()
	self.Model.Parent = self.Dungeon.Model
end

return DungeonFeature