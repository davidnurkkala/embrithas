local CAS = game:GetService("ContextActionService")

local Super = require(script.Parent)
local CharacterClient = Super:Extend()

local DescriptionsByStat = {
	Strength = "Increases damage with heavy weapons such as mauls, swords, and axes. Also affects some physical abilities.",
	Agility = "Increases damage with light weapons such as bows, spears, and dirks. Affects some physical abilities. Slightly affects movement speed.",
	Constitution = "Increases maximum health and helps you resist internal damage like poison or bleeding.",
	Perseverance = "Increases maximum mana and helps you resist damage caused by magic.",
	Dominance = "Increases the magnitude of your harmful magical effects.",
	Compassion = "Increases the magnitude of your helpful magical effects.",
}

CharacterClient.QuickAdding = false

function CharacterClient:OnCreated()
	self.Stats = {
		Strength = 0,
		Agility = 0,
		Constitution = 0,
		Perseverance = 0,
		Dominance = 0,
		Compassion = 0,
	}
	self.BaseStats = {
		Strength = 0,
		Agility = 0,
		Constitution = 0,
		Perseverance = 0,
		Dominance = 0,
		Compassion = 0,
	}
	
	self.StatUpgradeCooldown = self:CreateNew"Cooldown"{Time = 0.1}
	
	local screenGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Gui")
	
	self.Gui = screenGui:WaitForChild("CharacterFrame")
	self.QuickUnspentPointsLabel = screenGui:WaitForChild("CharacterButton"):WaitForChild("UnspentPointsLabel") 
	
	-- toggle button
	local function onToggled()
		self:ToggleVisibility()
	end
	screenGui:WaitForChild("CharacterButton").Activated:Connect(onToggled)
	self.Gui:WaitForChild("ClickOutButton").Activated:Connect(onToggled)
	
	self:GetService("OptionsClient"):BindAction("Character", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end

		self:ToggleVisibility()
	end)
	
	-- remotes
	self:ConnectRemote("StatsUpdated", self.OnStatsUpdated, false)
	
	-- mouse over descriptions
	self:InitStatTooltips()
	self:InitStatButtons()
	
	-- talents
	self:InitTalents()
end

function CharacterClient:GetStatValue(statName)
	return self.Stats[statName]
end

function CharacterClient:InitStatTooltips()
	local statsFrame = self.Gui:WaitForChild("StatsFrame")
	local descText = statsFrame:WaitForChild("DescriptionFrame"):WaitForChild("TextLabel")
	
	for stat, description in pairs(DescriptionsByStat) do
		local frame = statsFrame:WaitForChild(stat.."Frame")
		frame.MouseMoved:Connect(function()
			descText.Text = description
		end)
		frame.MouseLeave:Connect(function()
			descText.Text = ""
		end)
	end
end

function CharacterClient:InitStatButtons()
	local statsFrame = self.Gui:WaitForChild("StatsFrame")
	
	for stat, _ in pairs(DescriptionsByStat) do
		local frame = statsFrame:WaitForChild(stat.."Frame")
		frame.UpgradeButton.Activated:Connect(function()
			self:UpgradeStat(stat)
		end)
	end
end

function CharacterClient:UpgradeStat(statName)
	if not self.StatUpgradeCooldown:IsReady() then return end
	self.StatUpgradeCooldown:Use()
	
	local count = 1
	if self.QuickAdding then
		count = 10
	end
	
	for _ = 1, count do
		self:FireRemote("StatUpgraded", statName)
	end
end

function CharacterClient:OnStatsUpdated(playerStats, playerBaseStats, pointsRemaining)
	self.Stats = playerStats
	self.BaseStats = playerBaseStats
	
	local statsFrame = self.Gui:WaitForChild("StatsFrame")
	local titleLabel = self.Gui:WaitForChild("StatsTitleLabel")
	
	if pointsRemaining > 0 then
		local quickAddString
		if self.QuickAdding then
			quickAddString = "(Adding 10 at a time, release shift to stop.)"
		else
			quickAddString = "(Hold shift to add 10 at a time.)"
		end
		titleLabel.Text = string.format([[Stats%s<font size="10">Points remaining: %d%s%s</font>]], "\n", pointsRemaining, "\n", quickAddString)
	else
		titleLabel.Text = "Stats"
	end
	
	self.QuickUnspentPointsLabel.Visible = (pointsRemaining > 0)
	self.QuickUnspentPointsLabel.Text = string.format("%d unspent points!", pointsRemaining)
	
	for statName, value in pairs(playerStats) do
		local frame = statsFrame:WaitForChild(statName.."Frame")
		
		local baseValue = self.BaseStats[statName]
		local bonus = value - baseValue
		local operator = (bonus < 0) and "-" or "+"
		
		frame.AmountLabel.Text = (bonus ~= 0) and string.format("%d (%d %s %d)", value, baseValue, operator, math.abs(bonus)) or value
		frame.UpgradeButton.Visible = (pointsRemaining > 0)
	end
end

function CharacterClient:ToggleVisibility()
	self.Gui.Visible = not self.Gui.Visible
	
	if self.Gui.Visible then
		CAS:BindAction("CharacterScreenQuickAdd", function(_, state)
			self.QuickAdding = state == Enum.UserInputState.Begin
		end, false, Enum.KeyCode.LeftShift)
	else
		CAS:UnbindAction("CharacterScreenQuickAdd")
	end
end

function CharacterClient:InitTalents()
	self.UnlockedTalents = {}
	self.EquippedTalents = {}
	
	local talentsFrame = self.Gui:WaitForChild("TalentsFrame")
	local talentsTitleLabel = self.Gui:WaitForChild("TalentsTitleLabel")
	
	local gridFrame = talentsFrame:WaitForChild("GridFrame")
	local templateButton = gridFrame:WaitForChild("TemplateButton")
	templateButton.Visible = false
	
	local detailsFrame = talentsFrame:WaitForChild("DetailsFrame")
	local nameLabel = detailsFrame:WaitForChild("NameLabel")
	local descriptionLabel = detailsFrame:WaitForChild("DescriptionLabel")
	local unlockLabel = detailsFrame:WaitForChild("UnlockLabel")
	
	local equipButton = detailsFrame:waitForChild("EquipButton")
	local equipButtonCallback = nil
	equipButton.Activated:Connect(function()
		if equipButtonCallback then
			equipButtonCallback()
		end
	end)
	
	local selectedTalentId = nil
	
	local function clearDetails()
		nameLabel.Text = "Select a Talent"
		descriptionLabel.Text = ""
		unlockLabel.Text = ""
		
		equipButtonCallback = nil
		equipButton.Visible = false
	end
	
	local function showDetails(talentData, isUnlocked, isEquipped)
		selectedTalentId = talentData.Id
		
		clearDetails()
		
		nameLabel.Text = talentData.Name
		
		local description = talentData.Description
		if typeof(description) == "function" then
			description = description(talentData)
		end
		descriptionLabel.Text = description
		
		if isUnlocked then
			equipButton.Visible = true
			
			if isEquipped then
				equipButton.Text = "Unequip"
				equipButtonCallback = function()
					self:FireRemote("TalentsUpdated", "Unequipped", talentData.Id)
				end
			else
				equipButton.Text = "Equip"
				equipButtonCallback = function()
					self:FireRemote("TalentsUpdated", "Equipped", talentData.Id)
				end
			end
		else
			nameLabel.Text ..= " (Locked)"
			unlockLabel.Text = string.format("In order to unlock this talent, you must %s.", talentData.Unlock)
		end
	end
	
	local function clear()
		for _, child in pairs(gridFrame:GetChildren()) do
			if child.Name == "Button" then
				child:Destroy()
			end
		end
	end
	
	local function update(talentInfo)
		self.UnlockedTalents = talentInfo.Unlocked
		self.EquippedTalents = talentInfo.Equipped
		
		clear()
		
		local slots = talentInfo.AvailableSlots
		if slots < 1 then
			talentsTitleLabel.Text = "Talents"
		else
			talentsTitleLabel.Text = string.format("Talents\n(%d / %d)", #talentInfo.Equipped, slots)
		end
		
		local buttonInfos = {}
		
		local data = require(self.Storage.TalentData)
		for _, talentData in pairs(data) do
			local button = templateButton:Clone()
			button.Name = "Button"
			button.Visible = true
			button.Image = talentData.Image
			
			local isUnlocked = table.find(talentInfo.Unlocked, talentData.Id) ~= nil
			if (not isUnlocked) and (not talentData.Unlock) then
				continue
			end
			
			button.ImageColor3 = isUnlocked and Color3.new(1, 1, 1) or Color3.new(0.5, 0.5, 0.5)
			
			local isEquipped = table.find(talentInfo.Equipped, talentData.Id) ~= nil
			button.EquippedLabel.Visible = isEquipped
			
			if talentData.ImagePlaceholder then
				button.Image = ""
				local placeholder = Instance.new("TextLabel")
				placeholder.Name = "Placeholder"
				placeholder.BackgroundTransparency = 1
				placeholder.TextColor3 = button.ImageColor3
				placeholder.TextStrokeTransparency = 0
				placeholder.TextSize = 16
				placeholder.Font = Enum.Font.GothamBold
				placeholder.Text = talentData.ImagePlaceholder
				placeholder.Size = UDim2.new(1, 0, 1, 0)
				local padding = Instance.new("UIPadding")
				padding.PaddingTop = UDim.new(0, 2)
				padding.PaddingBottom = UDim.new(0, 2)
				padding.PaddingRight = UDim.new(0, 2)
				padding.PaddingLeft = UDim.new(0, 2)
				padding.Parent = placeholder
				placeholder.Parent = button
			end
			
			button.Activated:Connect(function()
				showDetails(talentData, isUnlocked, isEquipped)
			end)
			button.Parent = gridFrame
			
			table.insert(buttonInfos, {
				Button = button,
				Id = talentData.Id,
				IsEquipped = isEquipped,
				IsUnlocked = isUnlocked,
			})
		end
		
		if selectedTalentId then
			local talentData = data[selectedTalentId]
			local isUnlocked = table.find(talentInfo.Unlocked, talentData.Id) ~= nil
			local isEquipped = table.find(talentInfo.Equipped, talentData.Id) ~= nil
			showDetails(talentData, isUnlocked, isEquipped)
		end
		
		local function sortingScore(buttonInfo)
			local score = buttonInfo.Id
			if buttonInfo.IsEquipped then
				score -= 20000
			end
			if buttonInfo.IsUnlocked then
				score -= 10000
			end
			return score
		end
		table.sort(buttonInfos, function(a, b)
			return sortingScore(a) < sortingScore(b)
		end)
		
		for index, buttonInfo in pairs(buttonInfos) do
			buttonInfo.Button.LayoutOrder = index
		end
		
		local rows = math.ceil(#buttonInfos / 3)
		local padding = gridFrame.UIGridLayout.CellPadding.Y.Offset
		local height = rows * (gridFrame.UIGridLayout.CellSize.Y.Offset + padding) - padding
		gridFrame.CanvasSize = UDim2.new(0, 0, 0, height)
	end
	
	self:ConnectRemote("TalentsUpdated", function(_, ...) update(...) end, false)
	
	clearDetails()
end

local Singleton = CharacterClient:Create()
return Singleton