local Super = require(script.Parent)
local GuiClient = Super:Extend()

local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

GuiClient.LivesLast = 0
GuiClient.Level = 0

-- Junaiper was here 6/22/2021
function GuiClient:OnCreated()
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	
	self.PlayerList = {}
	self.Notifications = {}
	
	self.Gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Gui")
	self.BarsFrame = self.Gui:WaitForChild("BarsFrame")
	
	self.StatusGuis = {}
	
	self:ConnectRemote("StatusUpdated", self.OnStatusUpdated, false)
	self:ConnectRemote("ReviewRequested", self.ShowReview, false)
	self:ConnectRemote("RageUpdated", self.OnRageUpdated, false)
	self:ConnectRemote("AdrenalineUpdated", self.OnAdrenalineUpdated, false)
	self:ConnectRemote("AmmoUpdated", self.OnAmmoUpdated, false)
	self:ConnectRemote("AimAmmoUpdated", self.OnAimAmmoUpdated, false)
	self:ConnectRemote("CriticalMassUpdated", self.OnCriticalMassUpdated, false)
	self:ConnectRemote("VampiricUpdated", self.OnVampiricUpdated, false)
	self:ConnectRemote("PistolSaberUpdated", self.OnPistolSaberUpdated, false)
	self:ConnectRemote("BossStatusGuiUpdated", self.OnBossStatusGuiUpdated, false)
	self:ConnectRemote("BlockUpdated", self.OnBlockUpdated, false)
	self:ConnectRemote("NotificationRequested", self.OnNotificationRequested, false)
	self:ConnectRemote("PlayerListUpdated", self.OnPlayerListUpdated, false)
	self:ConnectRemote("TutorialUpdated", self.OnTutorialUpdated, false)
	self:ConnectRemote("TimerUpdated", self.OnTimerUpdated, false)
	self:ConnectRemote("BloodShardsUpdated", self.OnBloodShardsUpdated, false)
	self:ConnectRemote("ContestHealthUpdated", self.OnContestHealthUpdated, false)
	self:ConnectRemote("AnnouncementRequested", self.OnAnnouncementRequested, false)
	self:ConnectRemote("PromoRequested", self.OnPromoRequested, false)
	self:ConnectRemote("LivesDestroyed", self.OnLivesDestroyed, false)
	
	self:InitAbility()
	
	self.WeaponPickupPromptQueue = {}
	self.WeaponPickupPromptActive = false
	self.Storage:WaitForChild("Remotes"):WaitForChild("PromptWeaponPickup").OnClientInvoke = function(...)
		return self:ShowWeaponPickupPrompt(...)
	end
	
	self.Storage.Remotes:WaitForChild("PromptContest").OnClientInvoke = function(...)
		return self:ShowContestPrompt(...)
	end

	self.Storage.Remotes:WaitForChild("PromptAmount").OnClientInvoke = function(...)
		return self:ShowAmountPrompt(...)
	end
	
	self.Storage.Remotes:WaitForChild("PromptTransfer").OnClientInvoke = function(info)
		return self:CreateNew"TransferGui"{
			Parent = self.Gui,
			Info = info,
		}.Confirmed:Wait()
	end
	
	self:SetScale(1)
	
	-- gamepad
	GuiService.AutoSelectGuiEnabled = false
	self:ToggleGamepad(false)
	
	local function onLastInputTypeChanged(inputType)
		self:SetKeyboardLabelsVisible(false)
		self:SetTouchButtonsVisible(false)
		
		if inputType == Enum.UserInputType.Gamepad1 then
			self:ToggleGamepad(true)
		else
			self:ToggleGamepad(false)
			
			if inputType ~= Enum.UserInputType.Touch then
				self:SetKeyboardLabelsVisible(true)
				
			else
				
				self:SetTouchButtonsVisible(true)
			end
		end
	end
	UIS.LastInputTypeChanged:Connect(onLastInputTypeChanged)
	onLastInputTypeChanged(UIS:GetLastInputType())
	
	self:GetWorld():AddObject(self)
end

function GuiClient:OnPromoRequested(args)
	local text = args.Text
	local image = args.Image
	
	local gui = self.Storage.UI.PromoFrame:Clone()
	gui.Text.Text = text or gui.Text.Text
	gui.Image.Image = image
	gui.ConfirmButton.Activated:Connect(function()
		gui:Destroy()
	end)
	gui.Parent = self.Gui
end

function GuiClient:SetScale(scale)
	local xboxDebug = false
	local playersFrame = self.Gui.PlayersFrame
	local basePlayersFrame = game:GetService("StarterGui").Gui.PlayersFrame
	
	if GuiService:IsTenFootInterface() or xboxDebug then
		self.Gui.UIScale.Scale = scale + 1.4
		
		playersFrame.UIScale.Scale = 1.2
		playersFrame.Size = basePlayersFrame.Size + UDim2.new(0, 0, 0, basePlayersFrame.Size.Y.Offset * 0.5)
		
		for _, key in pairs{"PaddingTop", "PaddingBottom", "PaddingRight", "PaddingLeft"} do
			self.Gui.UIPadding[key] = UDim.new(0, 16)
		end
		
	elseif self.Gui.AbsoluteSize.X >= 1024 then
		self.Gui.UIScale.Scale = scale + 0.4
		
		--playersFrame.UIScale.Scale = 1.2
		playersFrame.Size = basePlayersFrame.Size + UDim2.new(0, 0, 0, basePlayersFrame.Size.Y.Offset * 0.5)
		
		for _, key in pairs{"PaddingTop", "PaddingBottom", "PaddingRight", "PaddingLeft"} do
			self.Gui.UIPadding[key] = UDim.new(0, 8)
		end
	end
end

function GuiClient:SetKeyboardLabelsVisible(state)
	for _, object in pairs(CollectionService:GetTagged("KeyboardButtonLabel")) do
		object.Visible = state
	end
end

function GuiClient:SetTouchButtonsVisible(state)
	for _, object in pairs(CollectionService:GetTagged("TouchButton")) do
		object.Visible = state
	end
end

function GuiClient:ToggleGamepad(state)
	if self.GamepadActive == state then return end
	self.GamepadActive = state
	
	for _, object in pairs(CollectionService:GetTagged("XboxButtonLabel")) do
		object.Visible = state
	end
	UIS.MouseIconEnabled = not state
end

function GuiClient:ShowAmountPrompt(args)
	args.Parent = self.Gui
	local prompt = self:CreateNew"AmountPromptGui"(args)
	return prompt.Completed:Wait()
end

function GuiClient:ShowContestPrompt(args)
	if args.Cancel then
		if self.ContestPromptEvent then
			self.ContestPromptEvent:Fire("Cancel")
		end
		return
	end
	
	local gui = self.Storage.UI.ContestPrompt:Clone()
	
	gui.ButtonsFrame.UpgradeButton.Visible = args.CanUpgrade
	
	local event = Instance.new("BindableEvent")
	
	for index, data in pairs(args.Options) do
		local choice = gui.ChoicesFrame["Option"..index.."Frame"]
		choice.DetailsFrame.NameLabel.Text = data.Name
		choice.DetailsFrame.TypeLabel.Text = data.Type
		choice.DetailsFrame.DescriptionLabel.Text = data.Description
		choice.Icon.Image = data.Image
		choice.BuyButton.AmountLabel.Text = data.Cost
		
		if args.Currency >= data.Cost then
			choice.BuyButton.Activated:Connect(function()
				event:Fire("Option"..index)
			end)
		else
			choice.BuyButton.BorderColor3 = Color3.new(1, 0, 0)
		end
	end
	
	local buttons = gui.ButtonsFrame
	
	buttons.RerollButton.AmountLabel.Text = args.RerollCost
	if args.Currency >= args.RerollCost then
		buttons.RerollButton.Activated:Connect(function()
			event:Fire("Reroll")
		end)
	else
		buttons.RerollButton.BorderColor3 = Color3.new(1, 0, 0)
	end
	
	buttons.UpgradeButton.Visible = args.UpgradeCost ~= nil
	buttons.UpgradeButton.AmountLabel.Text = args.UpgradeCost
	if args.Currency >= args.UpgradeCost then
		buttons.UpgradeButton.Activated:Connect(function()
			event:Fire("Upgrade")
		end)
	else
		buttons.UpgradeButton.BorderColor3 = Color3.new(1, 0, 0)
	end
	
	buttons.FinishButton.Activated:Connect(function()
		event:Fire("Finish")
	end)
	
	gui.Parent = self.Gui
	self.ContestPromptEvent = event
	
	local result = event.Event:Wait()
	
	gui:Destroy()
	self.ContestPromptEvent = nil
	
	return result
end

function GuiClient:ShowWeaponPickupPrompt(text, image, confirmMessage, cancelMessage)
	local data = {Text = text, Image = image}
	table.insert(self.WeaponPickupPromptQueue, data)
	
	while self.WeaponPickupPromptActive or (self.WeaponPickupPromptQueue[1] ~= data) do
		wait()
	end
	
	self.WeaponPickupPromptActive = true
	
	local data = table.remove(self.WeaponPickupPromptQueue, 1)
	local prompt = self.Storage.UI.WeaponPromptFrame:Clone()
	prompt.Text.Text = data.Text
	prompt.Icon.Image = data.Image
	local position = prompt.Position
	prompt.Position = position - UDim2.new(0, prompt.AbsoluteSize.X, 0, 0)
	prompt.Parent = self.Gui
	
	self:Tween(prompt, {Position = position}, 0.5)
	
	local event = Instance.new("BindableEvent")
	
	prompt.ConfirmButton.Text = confirmMessage
	prompt.ConfirmButton.Activated:Connect(function()
		event:Fire(true)
	end)
	prompt.CancelButton.Text = cancelMessage
	prompt.CancelButton.Activated:Connect(function()
		event:Fire(false)
	end)
	
	CAS:BindAction("GamepadWeaponPrompt", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		local keyCode = input.KeyCode
		
		if keyCode == Enum.KeyCode.DPadLeft then
			event:Fire(true)
		elseif keyCode == Enum.KeyCode.DPadRight then
			event:Fire(false)
		end
	end, false, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight)
	
	local result = event.Event:Wait()
	
	CAS:UnbindAction("GamepadWeaponPrompt")
	
	prompt:Destroy()
	self.WeaponPickupPromptActive = false
	
	return result
end

function GuiClient:ShowPrompt(text, confirmText, cancelText)
	local prompt = self.Storage.UI.PromptFrame:Clone()
	
	prompt.Text.Text = text
	if confirmText then
		prompt.ConfirmButton.Text = confirmText
	end
	if cancelText then
		prompt.CancelButton.Text = cancelText
	end
	
	local event = Instance.new("BindableEvent")
	
	prompt.ConfirmButton.Activated:Connect(function()
		event:Fire(true)
	end)
	prompt.CancelButton.Activated:Connect(function()
		event:Fire(false)
	end)
	prompt.ClickOutButton.Activated:Connect(function()
		event:Fire(false)
	end)
	
	prompt.Parent = self.Gui
	
	-- gamepad
	local selectedObject = GuiService.SelectedObject
	GuiService.SelectedObject = nil
	CAS:BindAction("GamepadPrompt", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		local keyCode = input.KeyCode
		
		if keyCode == Enum.KeyCode.ButtonA then
			event:Fire(true)
		elseif keyCode == Enum.KeyCode.ButtonB then
			event:Fire(false)
		end
	end, false, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonB)
	
	local result = event.Event:Wait()
	
	prompt:Destroy()
	
	-- gamepad
	GuiService.SelectedObject = selectedObject
	CAS:UnbindAction("GamepadPrompt")
	
	return result
end

function GuiClient:InitAbility()
	local hotbar = self.Gui:WaitForChild("HotbarFrame")
	
	for slotNumber = 1, 10 do
		hotbar:WaitForChild("Ability"..slotNumber).Visible = false
	end
	
	self:ConnectRemote("AbilityInfoUpdated", self.OnAbilityInfoUpdated, false)
end

function GuiClient:OnAbilityInfoUpdated(update)
	local hotbar = self.Gui.HotbarFrame
	
	for slotNumberNumber = 1, 10 do
		local slotNumber = tostring(slotNumberNumber)
		
		local abilityInfo = update[slotNumber]
		
		local abilityFrame = hotbar["Ability"..slotNumber]
		abilityFrame.Visible = true
		
		if abilityInfo then
			abilityFrame.Icon.Image = abilityInfo.Image
			
			local cooldownBar = abilityFrame.CooldownBar
			if abilityInfo.CooldownActive then
				abilityFrame.BorderColor3 = Color3.new(0, 0, 0)
				
				cooldownBar.Visible = true
				cooldownBar.Size = UDim2.new(1, 0, abilityInfo.CooldownRemaining / abilityInfo.CooldownTime, 0)
			else
				abilityFrame.BorderColor3 = Color3.new(1, 1, 1)
				
				cooldownBar.Visible = false
			end
		else
			abilityFrame.Icon.Image = ""
			abilityFrame.CooldownBar.Visible = false
		end
	end
	
	local weaponFrame = self.Gui.WeaponFrame
	local cooldownGuiPairs = {
		{update.WeaponLight, weaponFrame.LightCooldownFrame},
		{update.WeaponHeavy, weaponFrame.HeavyCooldownFrame},
	}
	for _, pair in pairs(cooldownGuiPairs) do
		local cooldown = pair[1]
		local gui = pair[2]
		
		if cooldown.CooldownActive then
			gui.Icon.ImageTransparency = 0.75
			gui.Size = UDim2.new(gui.Size.X, UDim.new(1 - cooldown.CooldownRemaining / cooldown.CooldownTime, gui.Size.Y.Offset))
		else
			gui.Icon.ImageTransparency = 0.5
			gui.Size = UDim2.new(gui.Size.X, UDim.new(1, gui.Size.Y.Offset))
		end
	end
end

function GuiClient:OnPlayerListUpdated(infoById)
	local listFrame = self.Gui.PlayersFrame
	local frameInfoPairs = {}
	
	-- update and add in new frames[]
	for id, info in pairs(infoById) do
		local frame = self.PlayerList[id]
		
		if not frame then
			frame = listFrame.TemplateFrame:Clone() 
			frame.Visible = true
			frame.Name = "Frame"
			frame.Parent = listFrame
			self.PlayerList[id] = frame
		end
		
		frame.NameLabel.Text = info.Name
		frame.LevelLabel.Text = info.Level
		frame.DeathsLabel.Text = "💀"..info.Deaths
		frame.IconFrame.Icon.Image = info.Icon
		frame.HealthFrame.Bar.Size = UDim2.new(info.HealthRatio, 0, 1, 0)
		frame.HealthFrame.Bar.BackgroundColor3 = Color3.new(0.666667, 0, 0):Lerp(Color3.fromRGB(85, 170, 127), info.HealthRatio)
		
		table.insert(frameInfoPairs, {frame, info})
	end
	
	-- sort frames
	local sort = self:GetClass("OptionsClient"):GetOption("PlayerListSorting")
	table.sort(frameInfoPairs, function(pairA, pairB)
		local a = pairA[2]
		local b = pairB[2]
		
		if sort == "Name" then
			return a.Name < b.Name
		elseif sort == "Level" then
			local levelA = a.Level
			if type(levelA) == "string" then levelA = 0 end
			local levelB = b.Level
			if type(levelB) == "string" then levelB = 0 end
			
			if levelA == levelB then
				return a.Name < b.Name
			else
				return levelA > levelB
			end
		elseif sort == "Health" then
			local ratioA = a.HealthRatio
			if ratioA == 0 then ratioA = 2 end
			local ratioB = b.HealthRatio
			if ratioB == 0 then ratioB = 2 end
			
			if ratioA == ratioB then
				return a.Name < b.Name
			else
				return ratioA < ratioB
			end
		elseif sort == "Deaths" then
			return a.Deaths > b.Deaths
		end
	end)
	for index, pair in pairs(frameInfoPairs) do
		pair[1].LayoutOrder = index
	end
	
	-- remove old ones
	for id, frame in pairs(self.PlayerList) do
		if not infoById[id] then
			frame:Destroy()
			self.PlayerList[id] = nil
		end
	end
	
	-- resize
	local count = 0
	for _, child in pairs(listFrame:GetChildren()) do
		if child:IsA("Frame") and child.Visible then
			count = count + 1
		end
	end
	local padding = listFrame.UIListLayout.Padding.Offset
	local height = count * (listFrame.TemplateFrame.Size.Y.Offset + padding) - padding
	listFrame.CanvasSize = UDim2.new(0, 0, 0, height)
end

function GuiClient:OnLivesDestroyed(duration, sound)
	local circle = self.Gui.LivesLabel.Circle:Clone()
	circle.Size = UDim2.new(0, 512, 0, 512)
	circle.ImageColor3 = Color3.new(0.333333, 0, 0.498039)
	circle.Visible = true

	self:Tween(circle, {Size = UDim2.new(0, 0, 0, 0)}, duration).Completed:Connect(function()
		sound = sound:Clone()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
		sound.Parent = workspace
		sound:Play()
		
		self:Tween(circle, {Size = UDim2.new(0, 256, 0, 256), ImageTransparency = 1}, 1).Completed:Connect(function()
			circle:Destroy()
		end)
	end)
	circle.Parent = self.Gui.LivesLabel
end

function GuiClient:OnStatusUpdated(status)
	local shield = status.Shield or 0
	local totalBarAmount = math.max(status.Health + shield, status.MaxHealth)
	
	-- health
	local healthRatio = status.Health / totalBarAmount
	self.BarsFrame.HealthFrame.Bar.Size = UDim2.new(math.max(0, healthRatio), 0, 1, 0)
	if healthRatio < 0 then
		self.BarsFrame.HealthFrame.TextLabel.Text = "Overkilled: "..math.floor(-healthRatio * 100).."%"
	else
		self.BarsFrame.HealthFrame.TextLabel.Text = string.format("%d / %d", status.Health, status.MaxHealth)
	end
	
	-- shield
	local shieldRatio = shield / totalBarAmount
	self.BarsFrame.HealthFrame.ShieldBar.Position = UDim2.new(healthRatio, 0, 0, 0)
	self.BarsFrame.HealthFrame.ShieldBar.Size = UDim2.new(shieldRatio, 0, 1, 0)
	
	-- man
	local manaRatio = status.Mana / status.MaxMana
	self.BarsFrame.ManaFrame.Bar.Size = UDim2.new(math.max(0, manaRatio), 0, 1, 0)
	self.BarsFrame.ManaFrame.TextLabel.Text = string.format("%d / %d", status.Mana, status.MaxMana)
	
	local manaCooldownBar = self.BarsFrame.ManaFrame.CooldownBar
	manaCooldownBar.Size = UDim2.new(math.clamp(status.ManaRegenCooldown, 0, 1), 0, 0.05, 0)
	
	-- points
	local pointsImage = self.Gui.PointsImage
	local gradient = pointsImage.Gradient
	local ratio = status.Points / status.PointsRequired
	local border = 0.01
	if ratio == 0 then
		gradient.Transparency = NumberSequence.new(1)
	elseif ratio == 1 then
		gradient.Transparency = NumberSequence.new(0)
	elseif ratio < border then
		gradient.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(ratio, 1),
			NumberSequenceKeypoint.new(1, 1),
		}
	elseif (1 - ratio) < border then
		gradient.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(ratio, 0),
			NumberSequenceKeypoint.new(1, 1),
		}
	else
		gradient.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(ratio, 0),
			NumberSequenceKeypoint.new(ratio + border, 1),
			NumberSequenceKeypoint.new(1, 1),
		}
	end
	
	-- lives
	self.Gui.LivesLabel.Text = "❤️x"..status.Lives
	
	if status.Lives > self.LivesLast then
		local circle = self.Gui.LivesLabel.Circle:Clone()
		circle.Visible = true
		
		self:Tween(circle, {Size = UDim2.new(0, 0, 0, 0)}, 1).Completed:Connect(function()
			circle:Destroy()
		end)
		circle.Parent = self.Gui.LivesLabel
	end
	self.LivesLast = status.Lives
	
	-- level and experience
	self.Gui.LevelLabel.Text = string.format("Lv. %d", status.Level or 1)
	self.Gui.ExperienceFrame.Bar.Size = UDim2.new((status.Experience or 0) / (status.ExperienceRequired or 1), 0, 1, 0)
	
	self.Level = status.Level
	
	-- channeling
	local channel = status.Channel
	self.Gui.ChannelFrame.Visible = channel.Active
	self.Gui.ChannelFrame.Bar.Size = UDim2.new(1 - channel.Duration / channel.DurationMax, 0, 1, 0)
	self.Gui.ChannelFrame.NameLabel.Text = string.format("%s...", channel.Name)
	self.Gui.ChannelFrame.TimeLabel.Text = string.format("%4.1f", channel.Duration)
	
	-- statuses
	self:UpdateStatuses(status.Statuses)
end

function GuiClient:UpdateStatuses(statuses)
	local frame = self.BarsFrame.StatusesFrame
	
	local function create(guid, status)
		local gui = frame.TemplateFrame:Clone()
		gui.Name = guid
		gui.Visible = true
		
		if status.Category == "Good" then
			gui.BorderColor3 = Color3.new(0.333333, 1, 0.498039)
			gui.LayoutOrder -= 128
			
		elseif status.Category == "Bad" then
			gui.BorderColor3 = Color3.new(0.666667, 0, 0)
			gui.LayoutOrder += 128
		end
		
		if status.ImagePlaceholder then
			gui.Text.Visible = true
			gui.Text.Text = status.ImagePlaceholder
			
			gui.Icon.Visible = false
			
		elseif status.Image then
			gui.Icon.Image = status.Image
			
		else
			gui.Text.Visible = true
			gui.Text.Text = "?"
			
			gui.Icon.Visible = false
		end
		
		self.StatusGuis[guid] = gui
		gui.Parent = frame
	end
	
	local function update(guid, status)
		local gui = self.StatusGuis[guid]
		gui.Bar.Size = UDim2.new(1, 0, status.Ratio, 0)
		
		if status.ExtraInfo then
			gui.StacksText.Visible = true
			gui.StacksText.Text = status.ExtraInfo
		else
			gui.StacksText.Visible = status.Stacks and (status.Stacks > 1)
			gui.StacksText.Text = status.Stacks or 0
		end
	end
	
	local function destroy(guid)
		self.StatusGuis[guid]:Destroy()
		self.StatusGuis[guid] = nil
	end
	
	for guid, status in pairs(statuses) do
		if not self.StatusGuis[guid] then
			create(guid, status)
		end
		update(guid, status)
	end
	
	for guid, status in pairs(self.StatusGuis) do
		if not statuses[guid] then
			destroy(guid)
		end
	end
end

function GuiClient:ShowReview(title, reviewData, runAgainEnabled)
	local blackout = self.Storage.UI.ReviewFrame:Clone()
	blackout.BackgroundTransparency = 1
	
	local frame = blackout.Frame
	frame.StatusText.Text = title
	
	local position = frame.Position
	frame.Position = position + UDim2.new(0, 0, -1, 0)
	
	blackout.Parent = self.Gui
	
	self:Tween(blackout, {BackgroundTransparency = 0}, 1)
	self:Tween(frame, {Position = position}, 2)
	
	-- prepare to show results
	local statsFrame = frame.StatsFrame
	
	local statsTemplate = statsFrame.StatsTemplate
	statsTemplate.Parent = nil
	
	local statsFrameName = "Stats"
	
	local function clearStats()
		for _, child in pairs(statsFrame:GetChildren()) do
			if child.Name == statsFrameName then
				child:Destroy()
			end
		end
	end
	
	local function showStats(category)
		clearStats()
		
		statsFrame.CategoryText.Text = category
		
		-- prepare them in a data structure for sorting
		local stats = reviewData.StatsByCategory[category]
		local list = {}
		for name, amount in pairs(stats) do
			local frame = statsTemplate:Clone()
			frame.Name = statsFrameName
			frame.Icon.Image = reviewData.IconsByName[name] or "rbxassetid://119971175"
			frame.NameText.Text = name
			frame.ValueText.Text = string.format("%d", amount)
			table.insert(list, {amount, frame})
		end
		
		-- sort them in order and parent them
		table.sort(list, function(a, b)
			return b[1] < a[1]
		end)
		for index, pair in pairs(list) do
			pair[2].LayoutOrder = index
			pair[2].Parent = statsFrame
		end
	end
	
	-- set up categories
	do
		local categoriesFrame = frame.CategoriesFrame
		
		local categoryTemplate = categoriesFrame.ButtonTemplate
		categoryTemplate.Parent = nil
		
		local list = {}
		for category, _ in pairs(reviewData.StatsByCategory) do
			local button = categoryTemplate:Clone()
			button.Text = category
			button.Activated:Connect(function()
				showStats(category)
			end)
			table.insert(list, {category, button})
		end
		
		table.sort(list, function(a, b)
			return a[1] < b[1]
		end)
		for index, pair in pairs(list) do
			pair[2].LayoutOrder = index
			pair[2].Parent = categoriesFrame
		end
		showStats(list[1][1])
	end
	
	-- voting stuff
	local repeatFrame = frame.VotingFrame.RepeatVotesFrame
	local returnFrame = frame.VotingFrame.ReturnVotesFrame
	local timer = frame.VotingFrame.TimerText
	
	local voteTemplate = repeatFrame.VoteTemplate
	voteTemplate.Parent = nil
	
	local function clearVotes()
		for _, frame in pairs{repeatFrame, returnFrame} do
			for _, child in pairs(frame:GetChildren()) do
				if child.Name == "Vote" then
					child:Destroy()
				end
			end
		end
	end
	
	local function showVotes(voteData)
		for name, vote in pairs(voteData) do
			local icon = voteTemplate:Clone()
			icon.Name = "Vote"
			icon.Image = reviewData.IconsByName[name]
			icon.Parent = (vote == "Repeat") and repeatFrame or returnFrame
		end
	end
	
	-- connect remotes
	local reviewVoted, reviewEnded
	local function onReviewEnded()
		blackout:Destroy()
		reviewEnded:Disconnect()
		reviewVoted:Disconnect()
	end
	local function onReviewVoted(timeRemaining, voteData)
		clearVotes()
		showVotes(voteData)
		timer.Text = string.format("%d", timeRemaining)
	end
	reviewVoted = self.Storage.Remotes.ReviewVoted.OnClientEvent:Connect(onReviewVoted)
	reviewEnded = self.Storage.Remotes.ReviewEnded.OnClientEvent:Connect(onReviewEnded)
	
	if not runAgainEnabled then
		frame.VotingFrame.RepeatButton.Visible = false
	end
	
	frame.VotingFrame.RepeatButton.Activated:Connect(function()
		self:FireRemote("ReviewVoted", "Repeat")
	end)
	frame.VotingFrame.ReturnButton.Activated:Connect(function()
		self:FireRemote("ReviewVoted", "Return")
	end)
	
	if UIS:GetLastInputType() == Enum.UserInputType.Gamepad1 then
		delay(3, function()
			GuiService.SelectedObject = frame.VotingFrame.RepeatButton
		end)
	end
end

function GuiClient:OnAnnouncementRequested(announcement)
	local label = self.Gui.TimerLabel:Clone()
	label.Name = "AnnouncementLabel"
	label.Visible = true
	label.Text = announcement
	label.Parent = self.Gui
	
	label.TextTransparency = 1
	label.TextStrokeTransparency = 1
	self:Tween(label, {TextTransparency = 0, TextStrokeTransparency = 0}, 1, Enum.EasingStyle.Linear)
	
	wait(8)
	
	self:Tween(label, {TextTransparency = 1, TextStrokeTransparency = 1}, 1).Completed:Connect(function()
		label:Destroy()
	end)
end

function GuiClient:OnBossStatusGuiUpdated(update)
	if update.Type == "Show" then
		self.Gui.BossHealthFrame.Visible = true
		
		local topLeft, bottomRight = GuiService:GetGuiInset()
		self.Gui.BossHealthFrame.Position = UDim2.new(0.5, 0, 0, -topLeft.Y / self.Gui.UIScale.Scale)
	elseif update.Type == "Hide" then
		self.Gui.BossHealthFrame.Visible = false
	elseif update.Type == "Update" then
		self.Gui.BossHealthFrame.Bar.Size = UDim2.new(update.Ratio, 0, 1, 0)
		self.Gui.BossHealthFrame.TextLabel.Text = update.Name
	end
end

function GuiClient:OnTimerUpdated(update)
	if update.Type == "Update" then
		self.Gui.TimerLabel.Visible = true
		self.Gui.TimerLabel.Text = "⌛"..update.Text
	elseif update.Type == "Hide" then
		self.Gui.TimerLabel.Visible = false
	end
end

function GuiClient:OnRageUpdated(update)
	if update.Type == "Show" then
		self.BarsFrame.RageFrame.Visible = true
	elseif update.Type == "Hide" then
		self.BarsFrame.RageFrame.Visible = false
	elseif update.Type == "Update" then
		self.BarsFrame.RageFrame.Bar.Size = UDim2.new(update.Ratio, 0, 1, 0)
		self.BarsFrame.RageFrame.BorderColor3 = (update.Ratio == 1) and Color3.new(1, 0, 0) or Color3.new(0, 0, 0)
	end
end

function GuiClient:OnPistolSaberUpdated(update)
	local frame = self.BarsFrame.PistolSaberFrame
	
	if update.Type == "Update" then
		frame.Visible = true
		
		for stage = 1, 3 do
			local image = frame["Stage"..stage] 
			image.ImageColor3 = Color3.new(0, 0, 0)
			
			if update.Stage >= stage then
				image.ImageColor3 = Color3.new(1, 1, 1)
			end
		end
		
		if update.Stage < 3 then
			frame.StatusText.Text = tostring(3 - update.Stage)
			frame.StatusText.TextColor3 = Color3.new(0.75, 0.75, 0.75)
		else
			frame.StatusText.Text = "Ready!"
			frame.StatusText.TextColor3 = Color3.new(1, 1, 1)
		end
	elseif update.Type == "Hide" then
		frame.Visible = false
	end
end

function GuiClient:OnAimAmmoUpdated(update)
	if update.Type == "Show" then
		self.BarsFrame.AimAmmoFrame.Visible = true
	elseif update.Type == "Hide" then
		self.BarsFrame.AimAmmoFrame.Visible = false
	elseif update.Type == "Update" then
		self.BarsFrame.AimAmmoFrame.BarFrame.Bar.Size = UDim2.new(update.Ratio, 0, 1, 0)
		self.BarsFrame.AimAmmoFrame.AmmoLabel.Text = string.format("%s: %d", update.AmmoWord, update.Ammo) 
		self.BarsFrame.AimAmmoFrame.TextLabel.Text = update.AimWord or "Aim"
	end
end

function GuiClient:OnCriticalMassUpdated(update)
	if update.Type == "Show" then
		self.BarsFrame.CriticalMassFrame.Visible = true
	elseif update.Type == "Hide" then
		self.BarsFrame.CriticalMassFrame.Visible = false
	elseif update.Type == "Update" then
		self.BarsFrame.CriticalMassFrame.Bar.Size = UDim2.new(update.Ratio, 0, 1, 0)
	end
end

function GuiClient:OnVampiricUpdated(update)
	local frame = self.BarsFrame.VampiricFrame
	if update.Type == "Show" then
		frame.Visible = true
	elseif update.Type == "Hide" then
		frame.Visible = false
	elseif update.Type == "Update" then
		local ratio = update.Ratio
		local add = math.floor(ratio)
		if add > 0 then
			frame.Text.Text = "+"..add
			frame.Text.Visible = true
		else
			frame.Text.Visible = false
		end
		frame.Bar.Size = UDim2.new(ratio - add, 0, 1, 0)
	end
end

function GuiClient:OnContestHealthUpdated(update)
	if update.Type == "Update" then
		local frame = self.ContestHealthFrame 
		if not frame then
			frame = self.Storage.UI.ContestHealthFrame:Clone()
			
			local top = GuiService:GetGuiInset()
			frame.Position -= UDim2.new(0, 0, 0, top.Y / 2)
			
			frame.Parent = self.Gui
			self.ContestHealthFrame = frame
		end
		
		frame.BlueHealthFrame.Bar.Size = UDim2.new(update.RatioBlue, 0, 1, 0)
		frame.RedHealthFrame.Bar.Size = UDim2.new(update.RatioRed, 0, 1, 0)
		
	elseif update.Type == "Hide" then
		self.ContestHealthFrame:Destroy()
		self.ContestHealthFrame = nil
	end
end

function GuiClient:OnAdrenalineUpdated(update)
	if update.Type == "Show" then
		self.BarsFrame.AdrenalineFrame.Visible = true
	elseif update.Type == "Hide" then
		self.BarsFrame.AdrenalineFrame.Visible = false
	elseif update.Type == "Update" then
		self.BarsFrame.AdrenalineFrame.Bar.Size = UDim2.new(update.Ratio, 0, 1, 0)
	end
end

function GuiClient:OnAmmoUpdated(update)
	local frame = self.BarsFrame.AmmoFrame
	if update.Type == "Show" then
		frame.Visible = true
	elseif update.Type == "Hide" then
		frame.Visible = false
	elseif update.Type == "Update" then
		frame.AmmoText.Text = string.format("%s %d/%d", update.AmmoType, update.Ammo, update.AmmoMax)
		for _, child in pairs(frame.IconsFrame:GetChildren()) do
			if child.Name == "Icon" then
				child:Destroy()
			end
		end
		for _ = 1, update.Ammo do
			local icon = frame.IconsFrame.IconTemplate:Clone()
			icon.Visible = true
			icon.Image = update.AmmoImage
			icon.Name = "Icon"
			icon.Parent = frame.IconsFrame
		end
	end
end

function GuiClient:OnBloodShardsUpdated(update)
	local frame = self.Gui.BloodShardsFrame
	if update.Type == "Update" then
		frame.Visible = true
		frame.AmountLabel.Text = update.Amount
	elseif update.Type == "Hide" then
		frame.Visible = false
	end
end

function GuiClient:OnBlockUpdated(update)
	local frame = self.BarsFrame.BlockFrame
	if update.Type == "Show" then
		frame.Visible = true
	elseif update.Type == "Hide" then
		frame.Visible = false
	elseif update.Type == "Update" then
		frame.Bar.Size = UDim2.new(update.Ratio, 0, 1, 0)
		frame.Bar.Visible = not (update.Ratio == 0)
		frame.TextLabel.Text = string.format("%d / %d", update.Block, update.BlockMax)
	end
end

function GuiClient:UpdateNotification(note, dt)
	local speedX = 256
	local speedY = 256
	
	local p = note.Position
	local delta = note.DesiredPosition - p
	
	local mx = math.min(speedX * dt, math.abs(delta.X)) * math.sign(delta.X)
	local my = math.min(speedY * dt, math.abs(delta.Y)) * math.sign(delta.Y)
	
	note.Position = note.Position + Vector2.new(mx, my)
	note.Gui.Position = UDim2.new(0, note.Position.X, 0.5, note.Position.Y)
end

function GuiClient:OnUpdated(dt)
	for _, notification in pairs(self.Notifications) do
		self:UpdateNotification(notification, dt)
	end
end

function GuiClient:OnNotificationRequested(data)
	for _, notification in pairs(self.Notifications) do
		notification.DesiredPosition = notification.DesiredPosition + Vector2.new(0, notification.Gui.Size.Y.Offset)
	end
	
	local gui = self.Storage.UI.NotificationFrame:Clone()
	gui.TitleLabel.Text = data.Title
	gui.ContentLabel.Text = data.Content
	
	if data.Image then
		gui.Icon.Image = data.Image
		gui.Icon.Visible = true
	end
	
	local note = {
		Gui = gui,
	}
	
	local offscreenDistance = gui.Size.X.Offset * 2
	
	note.Position = Vector2.new(-offscreenDistance, 0)
	note.DesiredPosition = Vector2.new(-self.Gui.UIPadding.PaddingLeft.Offset, 0)
	
	gui.Parent = self.Gui
	table.insert(self.Notifications, note)
	wait(5)
	note.DesiredPosition = note.DesiredPosition + Vector2.new(-offscreenDistance, 0)
	wait(2)
	table.remove(self.Notifications, table.find(self.Notifications, note))
	note.Gui:Destroy()
end

function GuiClient:HideArrow()
	if self.ArrowGui then
		self.ArrowGui:Destroy()
		self.ArrowGui = nil
	end
end

function GuiClient:ShowArrow(position, rotation)
	self:HideArrow()
	
	local arrow = self.Storage.UI.ArrowFrame:Clone()
	local sg = Instance.new("ScreenGui")
	arrow.Position = UDim2.new(0, position.X, 0, position.Y)
	arrow.Rotation = rotation
	arrow.Parent = sg
	sg.Parent = Players.LocalPlayer.PlayerGui
	
	spawn(function()
		while sg.Parent do
			local a = Vector3.new(0.5, 0.5, 0.5)
			local b = Vector3.new(1, 1, 1)
			local t = (math.sin(tick() * 8) + 1) / 2
			local c = self:Lerp(a, b, t)
			arrow.Image.ImageColor3 = Color3.new(c.X, c.Y, c.Z)
			wait()
		end
	end)
	
	self.ArrowGui = sg
end

function GuiClient:OnTutorialUpdated(step)
	if step == "rookiesGraveShowMap" then
		self:ShowArrow(self.Gui.MapButton.AbsolutePosition)
		local d = self:GetService("EffectsClient"):EffectDialogue{
			Name = "Drillmaster Leon",
			Image = "rbxassetid://5617833593",
			Text = "Rookie, be sure to use your map to navigate more easily.",
			ManualTiming = true,
		}
		self:GetService("MapClient").Toggled:Wait()
		d:End()
		self:HideArrow()
	end
end

local Singleton = GuiClient:Create()
return Singleton