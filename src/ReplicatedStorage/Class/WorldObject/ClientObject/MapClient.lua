local Super = require(script.Parent)
local MapClient = Super:Extend()

local Players = game:GetService("Players")

local CAS = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")

function MapClient:OnCreated()
	self.Toggled = self:CreateNew"Event"()
	
	-- set up ui elements
	local gui = Players.LocalPlayer.PlayerGui:WaitForChild("Gui")
	
	-- here's our viewport frame
	self.Viewport = gui:WaitForChild("MapFrame")
	
	-- now for the toggle button
	local function onButtonActivated()
		self:Toggle(not self.Visible)
	end
	gui:WaitForChild("MapButton").Activated:Connect(onButtonActivated)
	
	-- some quick initialization
	self:SetTransparency(1)
	
	local MarkerTemplate = self.Viewport.MarkerTemplate
	MarkerTemplate.Parent = nil
	self.MarkerTemplate = MarkerTemplate
	
	local playerMarkerTemplate = self.Viewport.PlayerMarkerTemplate
	playerMarkerTemplate.Parent = nil
	self.PlayerMarkerTemplate = playerMarkerTemplate
	
	self.Markers = {}
	
	-- this is our viewport frame's camera
	local camera = Instance.new("Camera")
	camera.FieldOfView = 10
	camera.CameraType = Enum.CameraType.Scriptable
	camera.Parent = self.Viewport
	self.Viewport.CurrentCamera = camera
	self.Camera = camera
	
	-- determine when dungeons get added to the workspace and update map
	local function onChildAdded(child)
		if child.Name == "Dungeon" then
			self:OnDungeonAdded(child)
		end
	end
	workspace.ChildAdded:Connect(onChildAdded)
	if workspace:FindFirstChild("Dungeon") then
		self:OnDungeonAdded(workspace.Dungeon)
	end
	
	-- determine when players get added and their characters so that we can
	-- update markers for them
	local function onPlayerAdded(player)
		player.CharacterAdded:Connect(function(character)
			self:OnPlayerCharacterAdded(player, character)
		end)
		if player.Character then
			self:OnPlayerCharacterAdded(player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	
	-- do that but for enemies too
	local function onEnemyAdded(model)
		self:OnEnemyAdded(model)
	end
	workspace.Enemies.ChildAdded:Connect(onEnemyAdded)
	for _, model in pairs(workspace.Enemies:GetChildren()) do
		self:OnEnemyAdded(model)
	end
	
	-- all done, add ourselves to the world
	self:GetWorld():AddObject(self)
	
	-- connect to server map controls
	self:ConnectRemote("MapToggled", self.Toggle, false)
	self:ConnectRemote("DoorKickedDown", self.OnDoorKickedDown, false)
	
	-- gamepad controls
	CAS:BindAction("GamepadToggleMap", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		
		self:Toggle(not self.Visible)
	end, false, Enum.KeyCode.ButtonR3)
	
	-- keyboard controls
	self:GetService("OptionsClient"):BindAction("Map", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		
		self:Toggle(not self.Visible)
	end)
end

function MapClient:OnDoorKickedDown(position)
	local icon = Instance.new("ImageLabel")
	icon.Name = "MapIcon"
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://5752398156"
	icon.Size = UDim2.new(0, 8, 0, 8)
	icon.Position = self:WorldToMap(position)
	icon.Parent = self.Viewport
end

function MapClient:SetTransparency(t)
	t = math.clamp(t, 0, 1)
	if t == self.Transparency then return end
	
	self.Transparency = t
	
	if t == 1 then
		self.Viewport.Visible = false
	else
		self.Viewport.Visible = true
		
		self.Viewport.ImageTransparency = self:Lerp(0.5, 1, t)
		for _, child in pairs(self.Viewport:GetChildren()) do
			if child:IsA("ImageLabel") then
				child.ImageTransparency = t
			
			elseif child:IsA("GuiObject") then
				child.BackgroundTransparency = t
			end
		end
	end
end

function MapClient:Toggle(state)
	self.Visible = state
	self.Toggled:Fire()
end

function MapClient:ClearDungeon()
	if self.Model then
		self.Model:Destroy()
		self.Model = nil
		self.Dungeon = nil
	end
	
	for _, child in pairs(self.Viewport:GetChildren()) do
		if child.Name == "MapIcon" then
			child:Destroy()
		end
	end
end

function MapClient:UpdateMapCamera()
	if self.UpdatingMapCamera then
		self.MapCameraTimer = 0.25
		return
	end
	
	self.MapCameraTimer = 0.25
	self.UpdatingMapCamera = true
	
	spawn(function()
		repeat
			self.MapCameraTimer = self.MapCameraTimer - wait()
		until self.MapCameraTimer <= 0
		
		local model = self.Model
		local cframe, size = model:GetBoundingBox()
		local p = cframe.Position
		
		self:ZoomCameraToFit(
			self.Camera,
			Vector3.new(p.X + size.X / 2, p.Y + size.Y / 2, p.Z + size.Z / 2),
			Vector3.new(p.X - size.X / 2, p.Y + size.Y / 2, p.Z - size.Z / 2)
		)
		
		for _, child in pairs(self.Viewport:GetChildren()) do
			if (child.Name == "MapIcon") and (child:FindFirstChild("WorldPosition") ~= nil) then
				child.Position = self:WorldToMap(child.WorldPosition.Value)
			end
		end
		
		self.UpdatingMapCamera = false
	end)
end

function MapClient:OnDungeonAdded(dungeon)
	self:ClearDungeon()
	
	self.Dungeon = dungeon
	self.DungeonCFrame = dungeon:GetBoundingBox()
	self.Model = Instance.new("Model")
	self.Model.Parent = self.Viewport
	
	local function onDescendantAdded(desc)
		if desc:IsA("StringValue") and desc.Name == "MapIconName" then
			local icon = self.Storage.UI.MapIcons:FindFirstChild(desc.Value):Clone()
			icon.Name = "MapIcon"
			icon.Position = self:WorldToMap(desc.Parent.Position)
			
			local worldPosition = Instance.new("Vector3Value")
			worldPosition.Name = "WorldPosition"
			worldPosition.Value = desc.Parent.Position
			worldPosition.Parent = icon
			
			if desc.Value == "Door" then
				local _, y = desc.Parent.CFrame:ToEulerAnglesXYZ()
				local turns = math.floor(y / (math.pi / 2))
				if turns % 2 == 0 then
					icon.Size = UDim2.new(icon.Size.Y, icon.Size.X)
				end
			end
			
			icon.Parent = self.Viewport
			
			local connection
			connection = desc.AncestryChanged:Connect(function(_, parent)
				if parent == nil then
					icon:Destroy()
					connection:Disconnect()
				end
			end)
		end
		if desc:IsA("BasePart") then
			if (not CollectionService:HasTag(desc, "MapIgnored")) then
				local part = desc:Clone()
				
				-- is this a wall? make it bolder
				if part.Name == "_DungeonWall" then
					part.Color = Color3.new(0, 0, 0)
					part.Size += Vector3.new(2, 0, 2)
					part.Material = "Neon"
					part.Transparency = 0
				end
				
				part.Parent = self.Model
				self:UpdateMapCamera()
			end
		end
	end
	dungeon.DescendantAdded:Connect(onDescendantAdded)
	for _, desc in pairs(dungeon:GetDescendants()) do
		onDescendantAdded(desc)
	end
end

function MapClient:OnPlayerCharacterAdded(player, character)
	local frame, color, layer
	
	if player == Players.LocalPlayer then
		color = Color3.new(1, 1, 0.5)
		frame = self.PlayerMarkerTemplate:Clone()
		frame.ImageColor3 = color
		layer = 4
	else
		color = Color3.new(1, 1, 1)
		frame = self.MarkerTemplate:Clone()
		layer = 1
	end
	
	frame.Parent = self.Viewport
	
	local marker = {
		Model = character,
		Frame = frame,
		RotateToCamera = player == Players.LocalPlayer,
		Color = color,
		Layer = layer,
	}
	
	table.insert(self.Markers, marker)
end

function MapClient:OnEnemyAdded(model)
	local frame = self.MarkerTemplate:Clone()
	frame.BackgroundColor3 = Color3.new(1, 0, 0)
	frame.Size = UDim2.new(0, 2, 0, 2)
	frame.Parent = self.Viewport
	
	local marker = {
		Model = model,
		Frame = frame
	}
	table.insert(self.Markers, marker)
end

function MapClient:ZoomCameraToFit(camera, a, b, scale)
	local m = (a + b) / 2
	local d = math.max(math.abs(a.X - b.X), math.abs(a.Z - b.Z))
	local f = math.rad(camera.FieldOfView)
	local zHeight = math.abs(d / (2 * math.tan(f / 2)))
	local zWidth = zHeight * (camera.ViewportSize.Y / camera.ViewportSize.X)
	local z = math.min(zHeight, zWidth)
	local p = m + Vector3.new(0, z * (scale or 1.25), 0)
	camera.CFrame = CFrame.new(p) * CFrame.Angles(-math.pi / 2, 0, 0)
end

function MapClient:WorldToMap(position)
	local modelPosition = position
	local mapPosition = self.Camera:WorldToViewportPoint(modelPosition)
	return UDim2.new(mapPosition.X, 0, mapPosition.Y, 0)
end

function MapClient:UDim2ToVector2(udim2)
	return Vector2.new(
		self.Viewport.Size.X.Offset * udim2.X.Scale + udim2.X.Offset,
		self.Viewport.Size.Y.Offset * udim2.Y.Scale + udim2.Y.Offset
	)
end

function MapClient:OnUpdated(dt)
	local deltaTransparency = dt * 4
	if self.Visible then
		self:SetTransparency(self.Transparency - deltaTransparency)
	else
		self:SetTransparency(self.Transparency + deltaTransparency)
	end
	
	if not self.Dungeon then return end
	
	for index = #self.Markers, 1, -1 do
		local marker = self.Markers[index]
		marker.TimeActive = (marker.TimeActive or 0) + dt
		
		if marker.Model.Parent and marker.Model.PrimaryPart then
			marker.Frame.Position = self:WorldToMap(marker.Model.PrimaryPart.Position)
			
			if marker.RotateToCamera then
				local delta = workspace.CurrentCamera.CFrame.LookVector
				local theta = math.atan2(delta.Z, delta.X)
				marker.Frame.Rotation = math.deg(theta)
			end
		else
			table.remove(self.Markers, index)
			
			local frame = marker.Frame
			self:Tween(frame, {BackgroundTransparency = 1}, 0.1).Completed:Connect(function()
				frame:Destroy()
			end)
		end
	end
end

local Singleton = MapClient:Create()
return Singleton