local Super = require(script.Parent)
local OptionsClient = Super:Extend()

local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")

local DisplayActionPairs = {
	{"Primary Attack", "AttackLight"},
	{"Secondary Attack", "AttackHeavy"},
	{"Swap Hotbars", "QuickSwitch"},
	{"Sheath Weapons", "SheathWeapons"},
	{"Hotbar 1", "Hotbar1"},
	{"Hotbar 2", "Hotbar2"},
	{"Hotbar 3", "Hotbar3"},
	{"Hotbar 4", "Hotbar4"},
	{"Hotbar 5", "Hotbar5"},
	{"Hotbar 6", "Hotbar6"},
	{"Hotbar 7", "Hotbar7"},
	{"Hotbar 8", "Hotbar8"},
	{"Hotbar 9", "Hotbar9"},
	{"Hotbar 10", "Hotbar10"},
	{"Inventory", "Inventory"},
	{"Character", "Character"},
	{"Map", "Map"},
	{"Celebrate", "Celebrate"},
	{"Pan Camera", "PanCamera"},	
}

local DisplayNamesByKeyCode = {
	MouseButton1 = "LMB",
	MouseButton2 = "RMB",
	MouseButton3 = "MMB",
	Space = "_",
	LeftShift = "LSHFT",
	RightShift = "RSHFT",
	LeftControl = "LCTRL",
	RightControl = "RCTRL",
	LeftAlt = "LALT",
	RightAlt = "RALT",
	One = "1",
	Two = "2",
	Three = "3",
	Four = "4",
	Five = "5",
	Six = "6",
	Seven = "7",
	Eight = "8",
	Nine = "9",
	Zero = "0",
}

function OptionsClient:OnCreated()
	self.Updated = self:CreateNew"Event"()
	
	-- general init
	self.Visible = false
	
	-- init gui stuff
	local gui = self:GetService("GuiClient").Gui
	
	self.Frame = gui:WaitForChild("OptionsFrame")
	
	-- connect to updates and fire off an update request
	self:ConnectRemote("OptionsUpdated", self.OnOptionsUpdated, false)
	self:FireRemote("OptionsUpdated", "RequestUpdate")
	
	-- toggle button
	local button = gui:WaitForChild("OptionsButton")
	button.Activated:Connect(function()
		self:Toggle(not self.Visible)
	end)
	
	-- click out button
	self.Frame:WaitForChild("ClickOutButton").Activated:Connect(function()
		self:Toggle(false)
	end)
	
	-- gamepad
	CAS:BindAction("GamepadToggleOptions", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		self:GamepadToggleVisibility()
	end, false, Enum.KeyCode.ButtonSelect)
	
	self:InitOptionsGui()
end

function OptionsClient:GamepadToggleVisibility()
	self:Toggle(not self.Visible)
	
	if self.Visible then
		GuiService:AddSelectionParent("GamepadOptions", self.Frame)
		GuiService.SelectedObject = self.Frame.ContentFrame.AutoMap.Check
		
		CAS:BindAction("GamepadCloseOptions", function(name, state, input)
			if state ~= Enum.UserInputState.Begin then return end
			self:GamepadToggleVisibility()
		end, false, Enum.KeyCode.ButtonB)
	else
		GuiService:RemoveSelectionGroup("GamepadOptions")
		GuiService.SelectedObject = nil
		
		CAS:UnbindAction("GamepadCloseOptions")
	end
end

function OptionsClient:SetOption(name, value)
	self.Options[name] = value
	self:FireRemote("OptionsUpdated", "ChangeOption", name, value)
	self:Update()
end

function OptionsClient:InitOptionsGui()
	local frame = self.Frame.ContentFrame
	
	-- booleans
	local function connectBooleanOption(gui, option)
		local function onActivated()
			self.Options[option] = not self.Options[option]
			self:FireRemote("OptionsUpdated", "ChangeOption", option, self.Options[option])
			self:Update()
		end
		
		gui.Check.Activated:Connect(onActivated)
		gui.Text.Activated:Connect(onActivated)
	end
	
	connectBooleanOption(frame.AutoMap, "AutoMap")
	connectBooleanOption(frame.AutoSalvage, "AutoSalvage")
	connectBooleanOption(frame.MusicMuted, "MusicMuted")
	connectBooleanOption(frame.ShowRange, "ShowRange")
	connectBooleanOption(frame.DisablePlayerGuide, "DisablePlayerGuide")
	connectBooleanOption(frame.TrueTopDown, "TrueTopDown")
	
	-- lists
	local function connectListOption(gui, option, choices)
		for _, choice in pairs(choices) do
			gui[choice.."Button"].Activated:Connect(function()
				self.Options[option] = choice
				self:FireRemote("OptionsUpdated", "ChangeOption", option, self.Options[option])
				self:Update()
			end)
		end
	end
	
	connectListOption(frame.PlayerListSorting, "PlayerListSorting", {"Name", "Level", "Health", "Deaths"})
	connectListOption(frame.InviteFilter, "InviteFilter", {"None", "Friends"})
	
	-- scalars
	local function connectScalarOption(gui, option, step, min, max)
		local function changeOption(amount)
			self.Options[option] = math.clamp(self.Options[option] + amount, min, max)
			self:FireRemote("OptionsUpdated", "ChangeOption", option, self.Options[option])
			self:Update()
		end
		gui.PlusButton.Activated:Connect(function()
			changeOption(step)
		end)
		gui.MinusButton.Activated:Connect(function()
			changeOption(-step)
		end)
	end
	
	connectScalarOption(frame.UIScaling, "UIScaling", 0.1, 0.1, 4)
	
	-- other things
	do
		local stage = 0
		local button = frame.DeleteSaveFile.Button
		local restoreTime = 0
		local function restore()
			stage = 0
			button.Text = "Delete my save file"
			button.BackgroundColor3 = Color3.new(0, 0, 0)
		end
		button.Activated:Connect(function()
			if stage == 0 then
				restoreTime = tick() + 15
				spawn(function()
					while tick() < restoreTime do
						wait(restoreTime - tick())
					end
					restore()
				end)
				
				button.BackgroundColor3 = Color3.new(1, 0, 0)
				button.Text = "THIS WILL DELETE YOUR SAVE FILE. ARE YOU SURE?"
				button.Active = false
				stage = 1
				wait(3)
				for n = 5, 1, -1 do
					button.Text = "YOU CAN CONTINUE IN "..n
					wait(1)
				end
				button.Text = "ARE YOU CERTAIN YOU WISH TO DELETE YOUR SAVE FILE?"
				button.Active = true
				
			elseif stage == 1 then
				restoreTime = tick() + 10
				button.Text = "CLICKING AGAIN WILL DELETE YOUR SAVE FILE!!!"
				button.Active = false
				stage = 2
				wait(3)
				for n = 5, 1, -1 do
					button.Text = "LAST CHANCE TO CHANGE YOUR MIND... "..n
					wait(1)
				end
				button.Text = "IF YOU CLICK THIS, YOUR SAVE FILE WILL BE DELETED!!!"
				button.Active = true
			elseif stage == 2 then
				button.Text = "DELETING SAVE FILE."
				self:FireRemote("SaveFileDeleted")
			end
		end)
	end
end

function OptionsClient:RebindAction(actionName)
	if self.RebindingAction then return end
	self.RebindingAction = true
	
	-- deactivate click out
	local clickOutButton = self.Frame.ClickOutButton
	clickOutButton.Active = false
	
	-- wait for any input
	local input = UIS.InputBegan:Wait()
	
	-- save and push the new keybind
	local keybinds = self.Options.Keybinds
	if input.UserInputType == Enum.UserInputType.Keyboard then
		keybinds[actionName] = {"Keyboard", input.KeyCode.Name}
	else
		keybinds[actionName] = {input.UserInputType.Name}
	end
	self:FireRemote("OptionsUpdated", "ChangeOption", "Keybinds", keybinds)
	
	-- reactivate click out
	clickOutButton.Active = true
	
	self.RebindingAction = false
end

-- tothetix was here 1/19/2021
function OptionsClient:GetKeybind(actionName, backup)
	if self.Options and self.Options.Keybinds then
		local keybind = self.Options.Keybinds[actionName]
		if not keybind then
			return backup
		end
		
		return {Enum.UserInputType[keybind[1]], keybind[2] and Enum.KeyCode[keybind[2]]}
	end
	return backup
end

function OptionsClient:IsInputKeybind(actionName, backup, input)
	local keybind = self:GetKeybind(actionName, backup)
	if input.UserInputType == keybind[1] then
		if (not keybind[2]) or (input.KeyCode == keybind[2]) then
			return true
		end
	end
	return false
end

function OptionsClient:BindAction(actionName, callback)
	local bindName = actionName.."Action"
	
	local function onUpdated()
		local options = self.Options or self.Updated:Wait()
		
		local keybinds = options.Keybinds
		if not keybinds then return end
		
		local keybind = keybinds[actionName]
		if not keybind then return end
		
		CAS:UnbindAction(bindName)
		
		local input = (keybind[1] == "Keyboard") and Enum.KeyCode[keybind[2]] or Enum.UserInputType[keybind[1]]
		CAS:BindAction(bindName, callback, false, input)
	end
	onUpdated()
	self.Updated:Connect(onUpdated)
end

function OptionsClient:Update()
	local frame = self.Frame.ContentFrame
	
	-- booleans
	frame.AutoMap.Check.Text = self.Options.AutoMap and "X" or ""
	frame.AutoSalvage.Check.Text = self.Options.AutoSalvage and "X" or ""
	frame.MusicMuted.Check.Text = self.Options.MusicMuted and "X" or ""
	frame.ShowRange.Check.Text = self.Options.ShowRange and "X" or ""
	frame.DisablePlayerGuide.Check.Text = self.Options.DisablePlayerGuide and "X" or ""
	frame.TrueTopDown.Check.Text = self.Options.TrueTopDown and "X" or ""
	
	-- lists
	local function updateListOption(gui, value)
		for _, child in pairs(gui:GetChildren()) do
			if child:IsA("TextButton") then
				child.BorderSizePixel = 1
				child.Font = Enum.Font.Gotham
			end
		end
		
		local button = gui:FindFirstChild(value.."Button")
		button.BorderSizePixel = 3
		button.Font = Enum.Font.GothamBold
	end
	
	updateListOption(frame.PlayerListSorting, self.Options.PlayerListSorting)
	updateListOption(frame.InviteFilter, self.Options.InviteFilter)
	
	-- scalars
	frame.UIScaling.AmountLabel.Text = self.Options.UIScaling
	self:GetService("GuiClient"):SetScale(self.Options.UIScaling)
	
	-- other
	workspace:WaitForChild("Music").Volume = self.Options.MusicMuted and 0 or 0.5
	
	-- keybinds
	local binds = self.Frame.KeybindsFrame
	
	-- remove old keybinds
	for _, child in pairs(binds:GetChildren()) do
		if child.Name == "Frame" then
			child:Destroy()
		end
	end
	
	-- add in new keybinds
	local bindCount = 0
	
	for index, displayActionPair in pairs(DisplayActionPairs) do
		local actionName = displayActionPair[2]
		local displayName = displayActionPair[1]
		
		local keybind = self.Options.Keybinds[actionName]
		local keyCode = (keybind[2] ~= nil) and keybind[2] or keybind[1]
		local keyDisplayName = DisplayNamesByKeyCode[keyCode] or keyCode
		
		local frame = binds.TemplateFrame:Clone()
		frame.Visible = true
		frame.Name = "Frame"
		frame.LayoutOrder = index
		frame.NameLabel.Text = displayName
		frame.KeybindButton.Text = keyDisplayName
		frame.KeybindButton.Activated:Connect(function()
			local rebinding = true
			spawn(function()
				local counter = 0
				while rebinding do
					frame.KeybindButton.Text = string.rep(".", counter + 1)
					counter = (counter + 1) % 3
					wait(0.5)
				end
			end)
			
			self:RebindAction(actionName)
			
			frame.KeybindButton.Text = ""
			rebinding = false
		end)
		frame.Parent = binds
		
		bindCount += 1
	end
	
	-- resize the scrolling frame
	local padding = binds.UIListLayout.Padding.Offset
	local height = bindCount * (binds.TemplateFrame.Size.Y.Offset + padding) - padding
	height += binds.UIPadding.PaddingTop.Offset + binds.UIPadding.PaddingBottom.Offset
	binds.CanvasSize = UDim2.new(0, 0, 0, height)
	
	local mapClient = self:GetService("MapClient")
	mapClient.Viewport.AnchorPoint = Vector2.new(0, 1)
	mapClient.Viewport.Position = UDim2.new(0, 0, 1, 0)
	
	self:UpdateKeybindGuis()
	
	self.Updated:Fire(self.Options)
end

function OptionsClient:GetActionDisplayName(actionName)
	local options = self.Options
	if not options then return "" end
	
	local keybinds = options.Keybinds
	if not keybinds then return "" end
	
	local keybind = keybinds[actionName]
	if not keybind then return "" end
	
	local keyCode = keybind[1]
	if keybind[1] == "Keyboard" then
		keyCode = keybind[2]
	end
	return DisplayNamesByKeyCode[keyCode] or keyCode
end

function OptionsClient:UpdateKeybindGuis()
	local gui = self:GetService("GuiClient").Gui
	
	-- hotbar
	local hotbar = gui:WaitForChild("HotbarFrame")
	for slot = 1, 10 do
		local actionName = "Hotbar"..slot
		local guiName = "Ability"..slot
		
		hotbar:WaitForChild(guiName):WaitForChild("KeyboardButtonLabel").Text = self:GetActionDisplayName(actionName)
	end
	hotbar:WaitForChild("Weapon"):WaitForChild("KeyboardButtonLabel").Text = self:GetActionDisplayName("QuickSwitch")
	
	-- inventory
	gui:WaitForChild("InventoryButton"):WaitForChild("KeyboardButtonLabel").Text = self:GetActionDisplayName("Inventory")
	
	-- character
	gui:WaitForChild("CharacterButton"):WaitForChild("KeyboardButtonLabel").Text = self:GetActionDisplayName("Character")
	
	-- map
	gui:WaitForChild("MapButton"):WaitForChild("KeyboardButtonLabel").Text = self:GetActionDisplayName("Map")
end

function OptionsClient:GetOption(optionName)
	while not (self.Options and self.Options[optionName]) do
		self.Updated:Wait()
	end
	return self.Options[optionName]
end

function OptionsClient:OnOptionsUpdated(options)
	self.Options = options
	self:Update()
end

function OptionsClient:Toggle(state)
	if state == self.Visible then return end
	
	self.Visible = state
	self.Frame.Visible = state
end

local Singleton = OptionsClient:Create()
return Singleton