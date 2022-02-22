local Super = require(script.Parent)
local CameraClient = Super:Extend()

local UIS = game:GetService("UserInputService")
local TwoPi = math.pi * 2

CameraClient.Distance = 32
CameraClient.DistanceMin = 8
CameraClient.DistanceMax = 64
CameraClient.ZoomSpeed = 4

CameraClient.PanAngle = math.pi / 4
CameraClient.PanSensitivity = 0.0025
CameraClient.Panning = false

function CameraClient:OnCreated()
	self.Enabled = true
	
	self.OptionsClient = self:GetService("OptionsClient")
	
	game:GetService("RunService"):BindToRenderStep("IsometricCamera", Enum.RenderPriority.Camera.Value - 1, function(dt)
		self:OnUpdated(dt)
	end)
	
	UIS.InputBegan:Connect(function(...)
		self:OnInputBegan(...)
	end)
	
	UIS.InputChanged:Connect(function(...)
		self:OnInputChanged(...)
	end)
	
	UIS.InputEnded:Connect(function(...)
		self:OnInputEnded(...)
	end)
end

function CameraClient:OnInputBegan(input, sunk)
	if sunk then return end
	
	if self.OptionsClient:IsInputKeybind("PanCamera", Enum.UserInputType.MouseButton2, input) then
		UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		self.Panning = true
		
	elseif input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.O then
			self:Zoom(-5)
		elseif input.KeyCode == Enum.KeyCode.I then
			self:Zoom(5)
		end
	end
end

function CameraClient:Pan(amount)
	self.PanAngle = self.PanAngle + amount
	
	if self.PanAngle >= TwoPi then
		self.PanAngle = self.PanAngle - TwoPi
	elseif self.PanAngle < 0 then
		self.PanAngle = self.PanAngle + TwoPi
	end
end

function CameraClient:Zoom(amount)
	self.Distance = math.clamp(self.Distance + amount, self.DistanceMin, self.DistanceMax)
end

function CameraClient:OnInputChanged(input, sunk)
	if sunk then return end
	
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		local delta = -input.Position.Z * self.ZoomSpeed
		self:Zoom(delta)
	
	elseif input.UserInputType == Enum.UserInputType.MouseMovement then
		if self.Panning then
			local delta = input.Delta
			self:Pan(-delta.X * self.PanSensitivity)
		end
	end
end

function CameraClient:OnInputEnded(input, sunk)
	if self.OptionsClient:IsInputKeybind("PanCamera", Enum.UserInputType.MouseButton2, input) then
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		self.Panning = false
	end
	
	if sunk then return end
end

function CameraClient:GetCharacter()
	return game.Players.LocalPlayer.Character
end

function CameraClient:GetTiltAngle()
	local optionsClient = self:GetClass"OptionsClient"
	if optionsClient.Options and optionsClient.Options.TrueTopDown then
		return -89.5
	else
		return -60
	end
end

function CameraClient:GetDesiredCFrame()
	local character = self:GetCharacter()
	if not character then return end
	
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	return CFrame.new(root.Position) *
		CFrame.Angles(0, self.PanAngle, 0) *
		CFrame.Angles(math.rad(self:GetTiltAngle()), 0, 0) *
		CFrame.new(0, 0, self.Distance)
end

function CameraClient:ReturnCamera(duration)
	local camera = workspace.CurrentCamera
	local startCFrame = camera.CFrame
	
	self:CreateNew"Timeline"{
		Time = duration,
		OnTicked = function(t, dt)
			local b = t:GetProgress() ^ 0.5
			local a = t:GetProgress() ^ 2
			local w = self:Lerp(a, b, t:GetProgress())
			camera.CFrame = startCFrame:Lerp(self:GetDesiredCFrame(), w)
		end,
		OnEnded = function()
			camera.CFrame = self:GetDesiredCFrame()
			self.Enabled = true
		end,
	}:Start()
end

function CameraClient:OnUpdated(dt)
	if not self.Enabled then return end
	
	local camera = workspace.CurrentCamera
	if not camera then return end
	
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = self:GetDesiredCFrame() or camera.CFrame
end

local Singleton = CameraClient:Create()
return Singleton