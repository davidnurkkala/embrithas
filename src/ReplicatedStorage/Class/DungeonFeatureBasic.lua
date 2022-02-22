local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")

local Super = require(script.Parent)
local DungeonFeatureBasic = Super:Extend()

function DungeonFeatureBasic:OnCreated()
	self:InitRoot()
	self:InitCollision()
end

function DungeonFeatureBasic:InitRoot()
	-- get the platform-oriented rotation then get rid of the platform
	local rotation, _ = self.Model:GetBoundingBox()
	self.Model.PrimaryPart:Destroy()
	
	-- disclude extra from the calculations
	local extra = self.Model:FindFirstChild("__Extra")
	if extra then
		extra.Parent = nil
	end
	
	-- create a new temporary root which will assist us in calculating a better bounding box
	local tempRoot = Instance.new("Part")
	tempRoot.Size = Vector3.new()
	
	local position = self.Model:FindFirstChildWhichIsA("BasePart", true).Position
	tempRoot.CFrame = rotation + (position - rotation.Position)
	tempRoot.Parent = self.Model
	self.Model.PrimaryPart = tempRoot
	
	-- now we can get an accurate bounding box
	local cframe, size = self.Model:GetBoundingBox()
	tempRoot:Destroy()
	
	-- create a part that matches the bounding box exactly
	local root = Instance.new("Part")
	root.Name = "FeatureRootPart"
	root.Anchored = true
	root.CanCollide = false
	root.Transparency = 1
	root.Color = Color3.new(1, 0, 1)
	root.Size = size
	root.CFrame = cframe
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.Material = Enum.Material.Plastic
	
	-- no mapping this
	CollectionService:AddTag(root, "MapIgnored")
	
	-- set it to an arbitrary height so that blocking features can't be stepped onto
	local desiredHeight = 12
	local deltaHeight = desiredHeight - root.Size.Y
	root.Size += Vector3.new(0, deltaHeight, 0)
	root.Position += Vector3.new(0, deltaHeight / 2, 0)
	
	-- set it to the desired shape
	local shape = self.Model:GetAttribute("CollisionShape") or "Box"
	if shape == "Cylinder" then
		root.Shape = Enum.PartType.Cylinder

		local width = math.min(root.Size.X, root.Size.Z)
		local height = root.Size.Y

		root.Size = Vector3.new(height, width, width)
		root.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	end
		
	-- assign it properly
	root.Parent = self.Model
	self.Model.PrimaryPart = root
	self.Root = root
	
	-- return the extra if we had one
	if extra then
		extra.Parent = self.Model
	end
end

function DungeonFeatureBasic:InitCollision()
	-- set all collision to debris, any collision will be only on the root
	for _, desc in pairs(self.Model:GetDescendants()) do
		if desc:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(desc, "Debris")
		end
	end
	
	-- do changes based on collision type
	local collisionType = self.Model:GetAttribute("CollisionType") or "Normal"
	if collisionType == "Normal" then
		self.Root.CanCollide = true
		PhysicsService:SetPartCollisionGroup(self.Root, "Dungeon")
		
	elseif collisionType == "Breakable" then
		local function onTouched(part)
			local model = self.Model
			local root = self.Root
			
			-- only trigger if we got hit by an enemy or legend
			local character = self:GetClass("Legend").GetLegendFromPart(part)
			if not character then
				character = self:GetClass("Enemy").GetEnemyFromPart(part)
				if not character then return end
			end
			
			-- temporarily disable collision on anything "left behind" to prevent spastic stuff
			local canCollides = {}
			local debris = model:FindFirstChild("__Debris")
			if debris then
				debris.Parent = model.Parent
				table.insert(canCollides, debris)
			end
			local extra = model:FindFirstChild("__Extra")
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
			
			-- destroy the root
			root:Destroy()
			
			-- call out and have the thing explode
			self:GetService("EffectsService"):RequestEffectAll("BreakBreakable", {
				Model = model,
				Position = character:GetFootPosition()
			})
			
			-- remove the model eventually
			game:GetService("Debris"):AddItem(model, 3)
		end
		
		self:SafeTouched(self.Root, onTouched)
	end
end

function DungeonFeatureBasic:IsSafe()
	return self.Model:GetAttribute("IsSafe")
end

function DungeonFeatureBasic:Activate()
	local className = self.Model:GetAttribute("FloorItemClass")
	if not className then return end
	
	local args = {}
	for key, val in pairs(self.Model:GetAttributes()) do
		args[key] = val
	end
	args.Model = self.Model
	args.Room = self.Room
	
	self.Room:AddFloorItem(self:CreateNew(className)(args))
end

return DungeonFeatureBasic