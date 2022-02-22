local Super = require(script.Parent)
local QuestClient = Super:Extend()

function QuestClient:OnCreated()
	self.Hidden = false
	self.Gui = self:GetService("GuiClient").Gui:WaitForChild("QuestsFrame")
	
	self:ConnectRemote("QuestsUpdated", self.OnQuestsUpdated, false)
	
	spawn(function()
		local optionsClient = self:GetService("OptionsClient")
		self.Gui:WaitForChild("TitleFrame"):WaitForChild("ToggleButton").Activated:Connect(function()
			optionsClient:SetOption("QuestLogHidden", not self.Hidden)
		end)
		optionsClient.Updated:Connect(function(...)
			self:OnOptionsUpdated(...)
		end)
		self:SetHidden(optionsClient:GetOption("QuestLogHidden"))
	end)
end

function QuestClient:OnOptionsUpdated(options)
	self:SetHidden(options.QuestLogHidden)
end

function QuestClient:SetHidden(hidden)
	if hidden == self.Hidden then return end
	
	self.Hidden = hidden
	
	self.Gui.QuestsFrame.Visible = not hidden
	self.Gui.TitleFrame.TitleLabel.Visible = not hidden
	self.Gui.TitleFrame.ToggleButton.Text = hidden and "<" or ">"
end

function QuestClient:GetMissionNameFromId(missionId)
	local missionScript = self.Storage.Missions:FindFirstChild(missionId)
	if not missionScript then
		return "MISSING MISSION"
	else
		return require(missionScript).Name
	end
end

function QuestClient:GetAbilityNameFromId(id)
	local itemData = require(self.Storage.ItemData)
	local abilities = itemData.Abilities
	local ability = abilities[id]
	if ability then
		return ability.Name
	else
		return "MISSING ABILITY"
	end
end

function QuestClient:SetUpGoalFrame(frame, goal)
	if goal.Type == "StartMission" then
		frame.TextLabel.Text = string.format("- Start mission \"%s\"", self:GetMissionNameFromId(goal.MissionId))
		frame.CheckboxLabel.Visible = true
		frame.CheckboxLabel.Text = goal.Completed and "X" or ""
		
	elseif goal.Type == "CompleteMission" then
		frame.TextLabel.Text = string.format("- Complete Mission \"%s\"", self:GetMissionNameFromId(goal.MissionId))
		frame.CheckboxLabel.Visible = true
		frame.CheckboxLabel.Text = goal.Completed and "X" or ""
		
	elseif goal.Type == "KillWithProjectile" then
		frame.TextLabel.Text = string.format("- Slay monsters with projectiles")
		frame.AmountLabel.Visible = true
		frame.AmountLabel.Text = string.format("%d / %d", goal.CountCurrent, goal.CountMax)
		
	elseif goal.Type == "KillWithAbility" then
		frame.TextLabel.Text = string.format("- Slay monsters with %s", self:GetAbilityNameFromId(goal.Id))
		frame.AmountLabel.Visible = true
		frame.AmountLabel.Text = string.format("%d / %d", goal.CountCurrent, goal.CountMax)
	end
end

function QuestClient:OnQuestsUpdated(data)
	local frame = self.Gui.QuestsFrame
	
	for _, child in pairs(frame:GetChildren()) do
		if child.Name == "QuestFrame" then
			child:Destroy()
		end
	end
	
	for questIndex, quest in ipairs(data.Quests) do
		local questFrame = frame.TemplateFrame:Clone()
		questFrame.Name = "QuestFrame"
		questFrame.LayoutOrder = questIndex
		questFrame.Visible = true
		
		questFrame.TitleLabel.Text = quest.Name
		
		for goalIndex, goal in ipairs(quest.Goals) do
			questFrame.Size += UDim2.new(UDim.new(), frame.TemplateFrame.Size.Y)
			
			local goalFrame = questFrame.TemplateFrame:Clone()
			goalFrame.Name = "GoalFrame"
			goalFrame.LayoutOrder = goalIndex
			goalFrame.Visible = true
			
			self:SetUpGoalFrame(goalFrame, goal)
			
			goalFrame.Parent = questFrame
		end
		
		questFrame.Parent = frame
	end
end

local Singleton = QuestClient:Create()
return Singleton