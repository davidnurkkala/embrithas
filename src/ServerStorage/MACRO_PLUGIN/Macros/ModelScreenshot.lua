local macro = {}

local active = false
local originalModel = nil
local activeModel = nil
local primaryPartOffset = nil
local storedProperties = nil
local storedStudioSettings = nil
local stepedConnection = nil
local cframeOffset = nil
local moveStartTime = nil
local modelBlackoutInstances = nil
local modelBlackoutProperties = nil
local modelEffects = nil
local modelScale = 1
local camera = workspace.CurrentCamera
local lighting = game.Lighting
local coreGui = game:GetService("CoreGui")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local globalSettings = settings()

local greenBox = script.GreenBox:Clone()
local matte = script.SquareMatte:Clone()
local lightingEffects = script.LightingEffects:Clone():GetChildren()


local FOV = 15
local ROT_SPEED_MIN = 0.01
local ROT_SPEED_MAX = 0.8
local ROT_SPEED_RAMP = 0.8

local TRANS_SPEED_MIN = 0.05
local TRANS_SPEED_MAX = 3
local TRANS_SPEED_RAMP = 0.8

local lightingSettings = {
		Ambient = Color3.fromRGB(0, 0, 0),
		OutdoorAmbient = Color3.fromRGB(161, 161, 161),
		ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
		ColorShift_Top = Color3.fromRGB(0, 0, 0),
		Brightness = 1,
		ClockTime = 10.6,
		GeographicLatitude = 349,
		FogColor = Color3.fromRGB(191, 191, 191),
		FogEnd = 100000,
		FogStart = 100000,
		--Technology = Enum.Technology.Legacy
	}


local studioSettings = {
	Studio = {
		["Camera Mouse Wheel Speed"] = 0.2
	}
}


local function storeProperty(instance, property)
	storedProperties[instance] = storedProperties[instance] or {}
	storedProperties[instance][property] = instance[property]
end


function enable()
	storedProperties = {}
	
	-- Update lighting and effects
	for property, value in pairs(lightingSettings) do
		storeProperty(lighting, property)
		lighting[property] = value
	end
	for _, effect in pairs(lighting:GetChildren()) do
		storeProperty(effect, "Parent")
		effect.Parent = nil
	end
	for _, effect in pairs(lightingEffects) do
		effect.Parent = lighting
	end
	
	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA("SelectionBox") and v.Visible then
			storeProperty(v, "Visible")
			v.Visible = false
		end
	end
	
	-- Workspace setup
	activeModel = originalModel:Clone()
	greenBox.Parent = workspace
	local cframe, modelSize = activeModel:GetBoundingBox()
	modelScale = modelSize.magnitude
	primaryPartOffset = (activeModel.PrimaryPart.CFrame - activeModel.PrimaryPart.CFrame.p) * cframe:toObjectSpace(activeModel.PrimaryPart.CFrame)
	cframeOffset = CFrame.new()
	setModelCFrame()
	for _, v in pairs(activeModel:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Locked = true	
		end
	end
	updateEffects()
	updateModelBlackout()
	activeModel.Parent = workspace
	
	-- Set studio settings
	storedStudioSettings = {}
	for settingsKey, settings in pairs(studioSettings) do
		storedStudioSettings[settingsKey] = {}
		for key, value in pairs(settings) do
			storedStudioSettings[settingsKey][key] = globalSettings[settingsKey][key]
			if key == "Camera Mouse Wheel Speed" then
				value = value * modelScale / 10
			end
			globalSettings[settingsKey][key] = value
		end
	end

	-- Set Camera and matte
	storeProperty(camera, "CFrame")
	storeProperty(camera, "FieldOfView")
	camera.CFrame = greenBox.PrimaryPart.CFrame * CFrame.Angles(0, math.pi / 8, math.pi / 8) * CFrame.new(0, 0, -modelScale / (2 * math.tan(math.rad(FOV) / 2)))
	camera.CameraType = Enum.CameraType.Watch
	camera.CameraSubject = greenBox.PrimaryPart
	camera.FieldOfView = FOV
	
	for _, v in pairs(matte.Frame:GetChildren()) do
		if v:IsA("Frame") then
			v.BackgroundColor3 = globalSettings.Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
		end
	end
	matte.Parent = coreGui

	-- Connect controls
	stepedConnection = runService.RenderStepped:Connect(controlsUpdate)
	
	thumbnailButton:SetVisible(true)
	blackBackground:SetVisible(true)
	blackModel:SetVisible(true)
	removeEffects:SetVisible(true)
end


function disable()
	-- Disconnect controls
	stepedConnection:Disconnect()
	stepedConnection = nil

	-- Remove effects
	for _, effect in pairs(lightingEffects) do
		effect.Parent = nil
	end
	-- Restore properties
	for instance, propList in pairs(storedProperties) do
		for property, value in pairs(propList) do
			instance[property] = value
		end
	end
	storedProperties = {}
	activeModel:Destroy()
	
	-- Restore workspace
	activeModel:Destroy()
	greenBox.Parent = nil
		
	-- Restore studio settings
	for settingsKey, settings in pairs(storedStudioSettings) do
		for key, value in pairs(settings) do
			globalSettings[settingsKey][key] = value
		end
	end
	storedStudioSettings = nil
	
	-- Restore camera and matte
	camera.CameraSubject = nil
	camera.CameraType = Enum.CameraType.Scriptable
	matte.Parent = nil
	wait()
	camera.CameraType = Enum.CameraType.Fixed
	
	removeEffects:SetVisible(false)
	blackModel:SetVisible(false)
	blackBackground:SetVisible(false)
	thumbnailButton:SetVisible(false)
end


function setModelCFrame()
	activeModel:SetPrimaryPartCFrame(greenBox.PrimaryPart.CFrame * cframeOffset * primaryPartOffset)
end


function controlsUpdate(dt)
	local ws = (userInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (userInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
	local ad = (userInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (userInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
	local qe = (userInputService:IsKeyDown(Enum.KeyCode.E) and 1 or 0) - (userInputService:IsKeyDown(Enum.KeyCode.Q) and 1 or 0)
	local doTranslate = userInputService:IsKeyDown(Enum.KeyCode.LeftShift)
	
	if not (ws == 0 and ad == 0 and qe == 0) then
		moveStartTime = moveStartTime or tick()
		if doTranslate then
			local step = (math.min(tick() - moveStartTime, TRANS_SPEED_RAMP) / TRANS_SPEED_RAMP * (TRANS_SPEED_MAX - TRANS_SPEED_MIN) + TRANS_SPEED_MIN) * dt * modelScale / 10
			cframeOffset = CFrame.new(-ad * step, qe * step, ws * step) * cframeOffset
		else
			local step = (math.min(tick() - moveStartTime, ROT_SPEED_RAMP) / ROT_SPEED_RAMP * (ROT_SPEED_MAX - ROT_SPEED_MIN) + ROT_SPEED_MIN) * dt
			cframeOffset = CFrame.new(cframeOffset.p) * CFrame.Angles(ws * step, -qe * step, ad * step) * (cframeOffset - cframeOffset.p)
		end
			
		setModelCFrame()
	else
		moveStartTime = nil
	end
end


function updateModelBlackout()
	if blackModel.Value then
		modelBlackoutInstances = {}
		modelBlackoutProperties = {}
		for _, v in pairs(activeModel:GetDescendants()) do
			if v:IsA("BasePart") then
				for _, surface in pairs(Enum.NormalId:GetEnumItems()) do
					local decal = Instance.new("Decal")
					decal.Texture = "rbxassetid://2586100278"
					decal.Color3 = Color3.new(0, 0, 0)
					decal.Face = surface
					decal.Parent = v
					table.insert(modelBlackoutInstances, decal)
				end
				modelBlackoutProperties[v] = {Color = v.Color, Material = v.Material}
				v.Color = Color3.new(0,0,0)
				v.Material = Enum.Material.SmoothPlastic
			end
		end
	else
		for _, v in pairs(modelBlackoutInstances or {}) do
			v:Destroy()
		end
		for instance, properties in pairs(modelBlackoutProperties or {}) do
			for key, val in pairs(properties) do
				instance[key] = val
			end
		end
		modelBlackoutInstances = nil
		modelBlackoutProperties = nil
	end
end


function updateEffects()
	if removeEffects.Value then
		modelEffects = {}
		for _, v in pairs(activeModel:GetDescendants()) do
			if v:IsA("Light") or v:IsA("ParticleEmitter") then
				modelEffects[v] = v.Parent
				v.Parent = nil
			end
		end
	else
		for effect, parent in pairs(modelEffects or {}) do
			effect.Parent = parent
		end
		modelEffects = nil
	end
end


function updateBackground(active)
	local color = active and Color3.new(0, 0, 0) or Color3.new(0, 1, 0)
	for _, v in pairs(greenBox:GetChildren()) do
		if v:FindFirstChild("SurfaceGui") then
			v.SurfaceGui.Frame.BackgroundColor3 = color
		end
	end
end


function macro:Init(plugin, pluginSettings, updatePluginSettingsCallback)
	updateBackground(blackBackground.Value)
	removeEffects:SetVisible(false)
	blackModel:SetVisible(false)
	blackBackground:SetVisible(false)
	thumbnailButton:SetVisible(false)
end


button = {}
button.Type = "Button"
button.Text = "📷 Take Screenshot"

function button:Activate()
	if active then
		active = false
		button:UpdateText("📷 Take Screenshot")
		disable()
	else
		originalModel = game.Selection:Get()[1]
		if not (originalModel and originalModel:IsA("Model")) then
			originalModel = nil
			warn("Select a model to 📷 screenshot")
			return
		elseif not originalModel.PrimaryPart then
			originalModel = nil
			warn("📷 Model has no primary part")
			return
		end
		active = true
		print("📷", originalModel.Name)
		button:UpdateText("🔴 Exit Screenshot")
		enable()
		game.Selection:Set({})
	end
end
	
	
thumbnailButton = {}
thumbnailButton.Type = "Button"
thumbnailButton.Text = "📷 Create Thumbnail Camera"

function thumbnailButton:Activate()
	if active then
		if activeModel then
			if originalModel:FindFirstChild("ThumbnailCamera") then
				originalModel.ThumbnailCamera:Destroy()
			end
			if activeModel:FindFirstChild("ThumbnailCamera") then
				activeModel.ThumbnailCamera:Destroy()
			end 
			
			local thumbCamera = camera:Clone()
			thumbCamera.Name = "ThumbnailCamera"
			thumbCamera.CFrame = originalModel.PrimaryPart.CFrame * activeModel.PrimaryPart.CFrame:toObjectSpace(camera.CFrame)
			thumbCamera.Parent = originalModel
			
			
			local thumbCameraActive = camera:Clone()
			thumbCameraActive.Name = "ThumbnailCamera"
			thumbCameraActive.Parent = activeModel
			
			print("Thumbnail camera created")
		end
	end
end


blackBackground = {}
blackBackground.Type = "Boolean"
blackBackground.Text = "Black background"
blackBackground.SettingId = "ScreenshotBackground"
blackBackground.Value = false

function blackBackground:Changed(newValue, oldValue)
	updateBackground(newValue)
end


blackModel = {}
blackModel.Type = "Boolean"
blackModel.Text = "Blackout model"
blackModel.SettingId = "ScreenshotModelBlack"
blackModel.Value = false

function blackModel:Changed(newValue, oldValue)
	if activeModel then
		updateModelBlackout()
	end
end


removeEffects = {}
removeEffects.Type = "Boolean"
removeEffects.Text = "Remove effects"
removeEffects.SettingId = "ScreenshotRemoveEffects"
removeEffects.Value = false

function removeEffects:Changed(newValue, oldValue)
	if activeModel then
		updateEffects()
	end
end


macro.Items = {button, thumbnailButton, blackBackground, blackModel, removeEffects}

return macro