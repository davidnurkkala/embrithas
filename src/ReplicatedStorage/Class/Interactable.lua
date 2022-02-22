local Super = require(script.Parent)
local Interactable = Super:Extend()

local CAS = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

Interactable.Enabled = true

function Interactable:OnCreated()
	self.Gui = self.Storage:WaitForChild("UI"):WaitForChild("InteractableBillboard"):Clone()
	
	self.Guid = HttpService:GenerateGUID()
	
	if not (self.Model and self.Model.PrimaryPart) then
		self:Destroy()
		return
	end
	
	self.Player = game:GetService("Players").LocalPlayer
	self.Visible = false
	
	self.RadiusSq = self.Radius ^ 2
	
	self.Gui.Adornee = self.Model.PrimaryPart
	self.Gui.Enabled = false
	self.Gui.StudsOffsetWorldSpace = self.Gui.StudsOffsetWorldSpace + (self.Offset or Vector3.new())
	self.Gui.TouchButton.Activated:Connect(function()
		self:Activate()
	end)
	self.Gui.Parent = self.Player.PlayerGui:WaitForChild("Gui")
end

function Interactable:Destroy()
	CAS:UnbindAction("InteractableInteract"..self.Guid)
	self.Gui:Destroy()
end

function Interactable:Activate()
	if self.CooldownTime then
		self.Enabled = false
		delay(self.CooldownTime, function()
			self.Enabled = true
		end)
	end
	
	self.Callback(self)
end

function Interactable:GetPlayerPosition()
	local char = self.Player.Character
	if not char then return Vector3.new() end
	
	local root = char.PrimaryPart
	if not root then return Vector3.new() end
	
	return root.Position
end

function Interactable:SetVisible(state)
	if self.Visible == state then return end
	self.Visible = state
	
	self.Gui.Enabled = state
	
	if state then
		CAS:BindAction("InteractableInteract"..self.Guid, function(name, state, input)
			if state ~= Enum.UserInputState.Begin then return end
			self:Activate()
		end, false, Enum.KeyCode.ButtonA, Enum.KeyCode.E)
	else
		CAS:UnbindAction("InteractableInteract"..self.Guid)
	end
end

function Interactable:OnUpdated()
	if not (self.Model and self.Model.PrimaryPart) then
		return self:Destroy()
	end
	
	local here = self.Model:GetPrimaryPartCFrame().Position
	local there = self:GetPlayerPosition()
	local delta = (there - here)
	local distanceSq = delta.X ^ 2 + delta.Z ^ 2
	
	if self.Visible then
		if (not self.Enabled) or (distanceSq > self.RadiusSq) then
			self:SetVisible(false)
		end
	else
		if (self.Enabled) and (distanceSq < self.RadiusSq) then
			self:SetVisible(true)
		end
	end
end

return Interactable