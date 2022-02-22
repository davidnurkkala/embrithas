local Super = require(script.Parent)
local TutorialClient = Super:Extend()

local UIS = game:GetService("UserInputService")

local Player = game:GetService("Players").LocalPlayer

function TutorialClient:OnCreated()
	self.Text = Player:WaitForChild("PlayerGui"):WaitForChild("Gui"):WaitForChild("TutorialText")
	
	self:ConnectRemote("TutorialUpdated", self.OnTutorialUpdated, false)
	self:FireRemote("TutorialUpdated")
end

function TutorialClient:GetRoot()
	return (Player.Character or Player.CharacterAdded:Wait()).PrimaryPart
end

function TutorialClient:ShowTrail(part)
	local trail = self.Storage.Models.TutorialTrail:Clone()
	local a0 = Instance.new("Attachment", self:GetRoot())
	local a1 = Instance.new("Attachment", part)
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Parent = workspace.Effects
	
	self.TrailObjects = {trail, a0, a1}
end

function TutorialClient:HideTrail()
	if self.TrailObjects then
		for _, object in pairs(self.TrailObjects) do
			object:Destroy()
		end
		self.TrailObjects = nil
	end
end

function TutorialClient:SetText(text)
	if text then
		self.Text.Visible = true
		self.Text.Text = text
	else
		self.Text.Visible = false
	end
end

function TutorialClient:OnTutorialUpdated(step, data)
	if step == 1 then
		self:SetText("Kick down the door!")
		self:ShowTrail(data.Door)
	elseif step == 2 then
		self:HideTrail()
		self:SetText("Left-click to slash monsters.\nPress left control to charge with your shield.\nAvoid red circles!")
	elseif step == 3 then
		self:SetText("Kick down the door!")
		self:ShowTrail(data.Door)
	elseif step == 4 then
		self:HideTrail()
		self:SetText("Slay the monsters!\nPress the spacebar to roll out of danger!")
	elseif step == 5 then
		self:SetText("Kick down the door!")
		self:ShowTrail(data.Door)
	elseif step == 6 then
		self:HideTrail()
		self:SetText("Cleanse corruption crystals to earn extra lives.\nPress the G key to sheathe your weapon and run faster!\nKick down the door!")
		self:ShowTrail(data.Door)
	elseif step == 7 then
		self:HideTrail()
		self:SetText("Defeat this final challenge!")
	elseif step == 8 then
		self:SetText("Kick down the door!")
		self:ShowTrail(data.Door)
	elseif step == 9 then
		self:HideTrail()
		self:SetText()
	end
end

local Singleton = TutorialClient:Create()
return Singleton