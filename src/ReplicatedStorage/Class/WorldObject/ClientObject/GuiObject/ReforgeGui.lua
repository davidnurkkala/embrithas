local CAS = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UIS = game:GetService("UserInputService")

local Super = require(script.Parent)
local ReforgeGui = Super:Extend()

function ReforgeGui:OnCreated()
	self.Closed = self:CreateNew"Event"()
	self.Content = {}
	self.SelectedIndex = -1
	
	self.Gui = self.Storage.UI.ReforgeFrame:Clone()
	
	self.Gui.ClickOutButton.Activated:Connect(function()
		self:Close()
	end)
	
	CAS:BindAction("GamepadCloseReforge", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		
		self:Close()
	end, false, Enum.KeyCode.ButtonB, Enum.KeyCode.E)
	
	local reforgeButton = self.Gui.DetailsFrame.ReforgeButton
	reforgeButton.Activated:Connect(function()
		if not reforgeButton.Active then return end
		
		self:ReforgeSelected()
	end)
	
	self:Update()
	self.Gui.Parent = self.Parent
	
	if self:IsGamepad() then
		GuiService.SelectedObject = self.Content[1]
	end
end

function ReforgeGui:IsGamepad()
	return UIS:GetLastInputType() == Enum.UserInputType.Gamepad1
end

function ReforgeGui:GetItemData(slotData)
	return self:GetService("WeaponService"):GetWeaponData(slotData)
end

function ReforgeGui:Update()
	for _, content in pairs(self.Content) do
		content:Destroy()
	end
	self.Content = {}
	
	local frame = self.Gui:WaitForChild("ContentFrame", 15)
	if not frame then return end
	
	for index, slotData in pairs(self.SlotDatas) do
		local itemData = self:GetItemData(slotData)
		
		local content = frame.TemplateButton:Clone()
		content.Visible = true
		content.Image = itemData.Image
		
		if itemData.Upgrades then
			content.LevelLabel.Text = "+"..itemData.Upgrades
		else
			content.LevelLabel.Text = ""
		end
		
		content.Activated:Connect(function()
			self.SelectedIndex = index
			self:ShowItem(itemData)
			
			if self:IsGamepad() then
				--self.InReforgeDetails = true
				GuiService.SelectedObject = self.Gui.DetailsFrame.ReforgeButton
				GuiService:AddSelectionParent("ReforgeDetails", self.Gui.DetailsFrame)
				CAS:BindAction("ReforgeDetailsBack", function(name, state)
					if state ~= Enum.UserInputState.Begin then return end
					
					CAS:UnbindAction("ReforgeDetailsBack")
					GuiService:RemoveSelectionGroup("ReforgeDetails")
					GuiService.SelectedObject = self.Content[self.SelectedIndex]
					--self.InReforgeDetails = false
				end, false, Enum.KeyCode.ButtonB)
			end
		end)
		content.SelectionGained:Connect(function()
			--if self.InReforgeDetails then return end
			
			self.SelectedIndex = index
			self:ShowItem(itemData)
		end)
		
		table.insert(self.Content, content)
		content.Parent = frame
	end
	
	local rows = math.ceil(#self.Content / 4)
	local padding = frame.UIGridLayout.CellPadding.Y.Offset
	local height = rows * (frame.UIGridLayout.CellSize.Y.Offset + padding) - padding
	frame.CanvasSize = UDim2.new(0, 0, 0, height)
end

function ReforgeGui:ReforgeSelected()
	local button = self.Gui.DetailsFrame.ReforgeButton
	button.Active = false
	
	-- check to see if we have gold, play animation if not
	local slotData = self.SlotDatas[self.SelectedIndex]
	local reforgeCost = self:GetService("LootService"):GetReforgeCost(slotData)
	local gold = self:GetService("InventoryClient").Inventory.Gold
	
	if gold < reforgeCost then
		button.BorderColor3 = Color3.new(1, 0, 0)
		self:Tween(button, {BorderColor3 = Color3.new(1, 1, 1)}, 0.5, Enum.EasingStyle.Linear).Completed:Wait()
		button.Active = true
		
		return
	end
	
	-- play forging animation
	local sound = self.Storage.Sounds.AnvilHit
	local function playSound(speed)
		local s = sound:Clone()
		s.PlaybackSpeed = speed
		s.Parent = workspace.Effects
		s:Play()
		game:GetService("Debris"):AddItem(s, 2)
	end
	playSound(0.8)
	delay(0.5, function() playSound(0.8) end)
	delay(1.0, function() playSound(1) end)
	
	self:Tween(button.Bar, {Size = UDim2.new(1, 0, 1, 0)}, 1, Enum.EasingStyle.Linear).Completed:Wait()
	
	-- call up and do data management
	local success, inventory = self.Storage.Remotes.ReforgeWeapon:InvokeServer(self.SelectedIndex)
	self.SlotDatas = inventory.Weapons
	self:Update()
	if self.SlotDatas[self.SelectedIndex] then
		self:ShowItem(self:GetItemData(self.SlotDatas[self.SelectedIndex]))
	end
	
	-- "cool down" the button
	self:Tween(button.Bar, {Size = UDim2.new(1, 0, 0, 0)}, 0.5, Enum.EasingStyle.Linear).Completed:Wait()
	
	button.Active = true
end

function ReforgeGui:GetModifierChancePairs(itemData)
	local modifierWeightTable = self.Storage.Remotes.GetModifierWeightTable:InvokeServer(itemData)
	local total = 0
	for _, number in pairs(modifierWeightTable) do
		total += number
	end
	local modifierChancePairs = {}
	for modifier, number in pairs(modifierWeightTable) do
		table.insert(modifierChancePairs, {
			modifier,
			number / total * 100,
		})
	end
	table.sort(modifierChancePairs, function(a, b)
		return a[2] > b[2]
	end)
	return modifierChancePairs
end

function ReforgeGui:ShowModifier(modifierId)
	local selectedObject = GuiService.SelectedObject
	
	local modifierData = require(self.Storage:WaitForChild("ModifierData"))
	local modifier = modifierData[modifierId]
	if not modifier then return end
	
	local frame = self.Storage:WaitForChild("UI"):WaitForChild("ItemDetailsPrompt"):Clone()
	
	local function close()
		frame:Destroy()
		GuiService.SelectedObject = selectedObject
		GuiService:RemoveSelectionGroup("ModifierDetails")
		CAS:UnbindAction("GamepadCloseModifierDetails")
	end
	frame.ClickOutButton.Activated:Connect(close)
	frame.CloseButton.Activated:Connect(close)
	CAS:BindAction("GamepadCloseModifierDetails", function(name, state)
		if state ~= Enum.UserInputState.Begin then return end
		
		close()
	end, false, Enum.KeyCode.ButtonB)
	
	frame.NameLabel.Text = modifier.Name
	frame.CategoryLabel.Text = "Weapon Modifier"
	frame.DescriptionLabel.Text = modifier.Description
	frame.Icon.Image = "rbxassetid://5637278275"
	
	frame.Parent = self.Parent
	
	GuiService:AddSelectionParent("ModifierDetails", frame)
	if self:IsGamepad() then
		GuiService.SelectedObject = frame.CloseButton
	end
end

function ReforgeGui:ShowItem(itemData)
	local frame = self.Gui.DetailsFrame
	
	frame.NameLabel.Text = self:GetService("ItemService"):GetItemName("Weapons", itemData)
	
	local class = self:GetClass(itemData.Class)
	frame.TypeLabel.Text = class.DisplayName
	
	local modifierChancePairs = self:GetModifierChancePairs(itemData)
	local modifiersFrame = frame:WaitForChild("ModifiersFrame", 15)
	if not modifiersFrame then return end
	for _, child in pairs(modifiersFrame:GetChildren()) do
		if child.Name == "Frame" then
			child:Destroy()
		end
	end
	for index, pair in pairs(modifierChancePairs) do
		local new = modifiersFrame.TemplateFrame:Clone()
		new.Visible = true
		new.Name = "Frame"
		new.NameButton.Text = pair[1]
		new.NameButton.Activated:Connect(function()
			self:ShowModifier(pair[1])
		end)
		new.ChanceLabel.Text = string.format("%4.4f%%", pair[2])
		new.LayoutOrder = index
		new.Parent = modifiersFrame
	end
	
	local padding = modifiersFrame.UIListLayout.Padding.Offset
	local height = #modifierChancePairs * (modifiersFrame.TemplateFrame.Size.Y.Offset + padding)
	modifiersFrame.CanvasSize = UDim2.new(0, 0, 0, height)
	
	frame.GoldFrame.AmountLabel.Text = self:GetService("LootService"):GetReforgeCost(itemData)
end

function ReforgeGui:Close()
	CAS:UnbindAction("GamepadCloseReforge")
	self.Gui:Destroy()
	self.Closed:Fire()
end

return ReforgeGui