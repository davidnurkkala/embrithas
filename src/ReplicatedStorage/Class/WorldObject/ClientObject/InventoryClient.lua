local Super = require(script.Parent)
local InventoryClient = Super:Extend()

local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local Configuration = require(game:GetService("ReplicatedStorage"):WaitForChild("Configuration"))

local Colors = require(Super.Storage:WaitForChild("RarityColors"))

function InventoryClient:OnCreated()
	self.SelectedTab = nil
	
	self.Toggled = self:CreateNew"Event"()
	self.TabSelected = self:CreateNew"Event"()
	self.ItemSelected = self:CreateNew"Event"()
	self.ItemEquipped = self:CreateNew"Event"()
	self.ItemUpgraded = self:CreateNew"Event"()
	
	self.Gui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Gui")
	
	self.Frame = self.Gui:WaitForChild("InventoryFrame")
	
	-- set up the toggle button
	self.ToggleButton = self.Gui:WaitForChild("InventoryButton")
	local function onToggleButtonActivated()
		self:ToggleVisibility()
	end
	self.ToggleButton.Activated:Connect(onToggleButtonActivated)
	self.Frame:WaitForChild("ClickOutButton").Activated:Connect(onToggleButtonActivated)
	
	self:GetService("OptionsClient"):BindAction("Inventory", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		
		self:ToggleVisibility()
	end)
	
	self.Inventory = {}
	
	self:InitContent()
	self:InitItemDetails()
	self:InitTabButtons()
	self:InitGamepad()
	
	self:ConnectRemote("InventoryUpdated", self.OnInventoryUpdated, false)
	self:ConnectRemote("AlignmentUpdated", self.OnAlignmentUpdated, false)
	spawn(function()
		local alignment = self.Storage:WaitForChild("Remotes"):WaitForChild("GetPlayerAlignment"):InvokeServer()
		self:OnAlignmentUpdated(alignment)
	end)
end

function InventoryClient:GamepadToggleVisibility()
	self:ToggleVisibility()
	
	local frame = self.Frame
	if frame.Visible then
		GuiService:AddSelectionParent("GamepadInventory", self.ContentFrame)
		GuiService.SelectedObject = frame.ContentFrame:FindFirstChildOfClass("ImageButton")
		
		CAS:BindAction("GamepadCloseInventory", function(name, state, input)
			if state ~= Enum.UserInputState.Begin then return end
			self:GamepadToggleVisibility()
		end, false, Enum.KeyCode.ButtonB)
		
		CAS:BindAction("GamepadInventoryChangeTabs", function(name, state, input)
			if state ~= Enum.UserInputState.Begin then return end
			if not self.Frame.Visible then return end
			
			local keyCode = input.KeyCode
			
			if keyCode == Enum.KeyCode.ButtonR1 then
				self.GamepadTabIndex = self.GamepadTabIndex + 1
				if self.GamepadTabIndex > #self.GamepadTabs then
					self.GamepadTabIndex = 1
				end
			elseif keyCode == Enum.KeyCode.ButtonL1 then
				self.GamepadTabIndex = self.GamepadTabIndex - 1
				if self.GamepadTabIndex < 1 then
					self.GamepadTabIndex = #self.GamepadTabs
				end
			end
			
			self:SelectTab(self.GamepadTabs[self.GamepadTabIndex])
			GuiService.SelectedObject = self.ContentFrame:FindFirstChildOfClass("ImageButton")
		end, false, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
	else
		GuiService:RemoveSelectionGroup("GamepadInventory")
		GuiService.SelectedObject = nil
		
		CAS:UnbindAction("GamepadCloseInventory")
		CAS:UnbindAction("GamepadInventoryChangeTabs")
	end
end

function InventoryClient:InitGamepad()
	CAS:BindAction("GamepadToggleInventory", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		self:GamepadToggleVisibility()
		
	end, false, Enum.KeyCode.ButtonY)
	
	self.GamepadTabs = {"Weapons", "Abilities", "Trinkets", "Materials"}
	self.GamepadTabIndex = 1
	
	GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		local object = GuiService.SelectedObject
		if not object then return end
		
		if object.Parent == self.ContentFrame then
			self:SelectContent(object)
		end
	end)
end

function InventoryClient:GamepadContentActivated()
	if GuiService.SelectedObject ~= self.SelectedContent then return end
	
	local buttons = self.Frame.DetailsFrame.ButtonsFrame
	local selected = false
	
	local equipButton = buttons.EquipButton
	if equipButton.Visible then
		GuiService.SelectedObject = equipButton
		selected = true
	else
		local upgradeButton = buttons.UpgradeButton
		if upgradeButton.Visible then
			GuiService.SelectedObject = upgradeButton
			selected = true
		else
			local discardButton = buttons.DiscardButton
			if discardButton.Visible then
				GuiService.SelectedObject = discardButton
				selected = true
			end
		end
	end
	
	if selected then
		GuiService:AddSelectionParent("GamepadDetailsButtons", buttons)
		
		CAS:BindAction("GamepadExitDetailsButtons", function(name, state, input)
			if state ~= Enum.UserInputState.Begin then return end
			
			GuiService:RemoveSelectionGroup("GamepadDetailsButtons")
			GuiService.SelectedObject = self.SelectedContent
			CAS:UnbindAction("GamepadExitDetailsButtons")
		end, false, Enum.KeyCode.ButtonB)
	end
end

function InventoryClient:InitContent()
	self.ContentFrame = self.Frame:WaitForChild("ContentFrame")
	self.ContentTemplate = self.ContentFrame:WaitForChild("TemplateButton")
	self.ContentTemplate.Parent = nil
	self.ContentSelected = nil
	self.SelectedIndex = 0
	self.ItemIndexByContent = {}
end

function InventoryClient:ClearContent()
	self.ItemIndexByContent = {}
	for _, child in pairs(self.ContentFrame:GetChildren()) do
		if child:IsA("ImageButton") then
			child:Destroy()
		end
	end
end

function InventoryClient:InitTabButtons()
	local tabsFrame = self.Frame:WaitForChild("TabsFrame")
	self.TabButtons = {
		tabsFrame:WaitForChild("MaterialsButton"),
		tabsFrame:WaitForChild("WeaponsButton"),
		tabsFrame:WaitForChild("AbilitiesButton"),
		tabsFrame:WaitForChild("TrinketsButton")
	}
	
	tabsFrame.MaterialsButton.Activated:Connect(function()
		self:SelectTab("Materials")
	end)
	tabsFrame.WeaponsButton.Activated:Connect(function()
		self:SelectTab("Weapons")
	end)
	tabsFrame.AbilitiesButton.Activated:Connect(function()
		self:SelectTab("Abilities")
	end)
	tabsFrame.TrinketsButton.Activated:Connect(function()
		self:SelectTab("Trinkets")
	end)
end

function InventoryClient:SelectTab(tab)
	if tab == self.SelectedTab then
		return
	end
	
	self.SelectedTab = tab
	
	for _, button in pairs(self.TabButtons) do
		if button.Name:find(self.SelectedTab) then
			button.Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, 1, 0)
			button.BorderSizePixel = 0
		else
			button.Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, 1, -2)
			button.BorderSizePixel = 1
		end
	end
	
	self:ClearContent()
	self:ClearItemDetails()
	self:ShowContent()
	
	self.TabSelected:Fire(tab)
end

function InventoryClient:SelectContentByIndex(index)
	for content, i in pairs(self.ItemIndexByContent) do
		if i == index then
			self:SelectContent(content)
			break
		end
	end
end

function InventoryClient:SelectContent(content)
	-- datakeeping
	local index = self.ItemIndexByContent[content]
	self.SelectedIndex = index
	self:ShowItemDetails(index, self.Inventory[self.SelectedTab][index])
	self.ItemSelected:Fire()
	
	-- remove effects from previous
	if self.SelectedContent then
		self.SelectedContent.BorderSizePixel = 0
	end
	
	-- add effects to new
	content.BorderSizePixel = 1
	
	-- remember new
	self.SelectedContent = content
end

function InventoryClient:ShowContent()
	local tab = self.SelectedTab
	local itemDatas = self.Inventory[tab]
	
	local contentInfos = {}
	
	for index, itemData in pairs(itemDatas) do
		local content = self.ContentTemplate:Clone()
		content.BorderSizePixel = 0
		
		content.Activated:Connect(function()
			self:SelectContent(content)
			self:GamepadContentActivated()
		end)
		
		if itemData.Favorited then
			content.FavoritedLabel.Visible = true
		end
		
		if tab == "Weapons" then
			if index == self.Inventory.EquippedWeaponIndex then
				content.EquippedLabel.Visible = true
			end
			
			if index == self.Inventory.OffhandWeaponIndex then
				content.EquippedLabel.Visible = true
				content.EquippedLabel.Text = "✋"
			end
			
			local weaponData = self:GetService("WeaponService"):GetWeaponData(itemData)
			content.Image = weaponData.Image
			
			if weaponData.Upgrades then
				content.AmountLabel.TextSize = 10
				content.AmountLabel.Text = "+"..weaponData.Upgrades
				content.AmountLabel.Visible = true
			end
			
			if weaponData.Rarity == "Rare" then
				content.RarityBar.Visible = true
				content.RarityBar.BackgroundColor3 = Colors.Rare
			elseif weaponData.Rarity == "Mythic" then
				content.RarityBar.Visible = true
				content.RarityBar.BackgroundColor3 = Colors.Mythic
			elseif weaponData.Rarity == "Legendary" then
				content.RarityBar.Visible = true
				content.RarityBar.BackgroundColor3 = Colors.Legendary
			end
			
		elseif tab == "Abilities" then
			local isEquipped = self:DictFind(self.Inventory.EquippedAbilityIndices, index) ~= nil
			local isOffhanded = self:DictFind(self.Inventory.OffhandAbilityIndices, index) ~= nil
			
			if isEquipped or isOffhanded then
				content.EquippedLabel.Visible = true
				
				if isEquipped and isOffhanded then
					content.EquippedLabel.Text = "✊✋"
				elseif isOffhanded then
					content.EquippedLabel.Text = "✋"
				else
					content.EquippedLabel.Text = "✊"
				end
			end
			
			local abilityData = self:GetService("AbilityService"):GetAbilityData(itemData.Id, self:GetPlayerLevel())
			content.Image = abilityData.Image
			
			if itemData.Upgrades then
				content.AmountLabel.TextSize = 10 
				content.AmountLabel.Text = "+"..itemData.Upgrades
				content.AmountLabel.Visible = true
			end
			
		elseif tab == "Trinkets" then
			
			local slotNumber = table.find(self.Inventory.EquippedTrinketIndices, index)
			if slotNumber then
				content.EquippedLabel.Text = slotNumber
				content.EquippedLabel.Visible = true
			end
			
			local data = self:GetService("ItemService"):GetItemData("Trinkets", itemData)
			content.Image = data.Image
			
			if itemData.Upgrades then
				content.AmountLabel.TextSize = 10
				content.AmountLabel.Text = "+"..itemData.Upgrades
				content.AmountLabel.Visible = true
			end
			
		elseif tab == "Materials" then
			content.AmountLabel.Text = itemData.Amount
			content.AmountLabel.Visible = true
			
			local materialData = self:GetService("MaterialService"):GetMaterialData(itemData.Id)
			content.Image = materialData.Image
		end
		
		content.Parent = self.ContentFrame
		self.ItemIndexByContent[content] = index
		
		table.insert(contentInfos, {Content = content, SlotData = itemData, Index = index})
	end
	
	local rows = math.ceil(#itemDatas / 4)
	local padding = self.ContentFrame.UIGridLayout.CellPadding.Y.Offset
	local height = rows * (self.ContentFrame.UIGridLayout.CellSize.Y.Offset + padding) - padding
	self.ContentFrame.CanvasSize = UDim2.new(0, 0, 0, height)
	
	table.sort(contentInfos, function(a, b)
		if a.SlotData.Favorited and (not b.SlotData.Favorited) then
			return true
		elseif (not a.SlotData.Favorited) and b.SlotData.Favorited then
			return false
		else
			return a.Index < b.Index
		end
	end)
	for index, contentInfo in pairs(contentInfos) do
		contentInfo.Content.LayoutOrder = index
	end
end

function InventoryClient:GetFullItemData(itemData, tab)
	local fullData = {}
	for k, v in pairs(itemData) do
		fullData[k] = v
	end
	
	local extraData = {}
	if tab == "Weapons" then
		extraData = self:GetService("WeaponService"):GetWeaponData(itemData)
	elseif tab == "Abilities" then
		extraData = self:GetService("AbilityService"):GetAbilityData(itemData.Id, self:GetPlayerLevel())
	elseif tab == "Trinkets" then
		extraData = self:GetService("ItemService"):GetItemData("Trinkets", itemData)
	end
	for k, v in pairs(extraData) do
		fullData[k] = v
	end
	
	return fullData
end

function InventoryClient:ShowUpgrade(itemData)
	self:HideUpgrade()
	
	itemData = self:GetFullItemData(itemData, self.SelectedTab)
	
	local frame = self.DetailsFrame.MaterialsFrame:Clone()
	frame.Name = "UpgradeFrame"
	frame.Parent = self.DetailsFrame
	self.UpgradeFrame = frame
	
	local upgrades = itemData.Upgrades or 0
	local maxUpgrades = itemData.MaxUpgrades or Configuration.MaxUpgrades
	
	if upgrades < maxUpgrades then
		local upgradeData = self:GetService("WeaponService"):GetUpgradeData(itemData, self.Inventory)
		for _, req in pairs(upgradeData) do
			local material = frame.Template:Clone()
			material.Name = "Material"
			material.Visible = true
			material.Icon.Image = req.Material.Image
			material.NameText.Text = req.Material.Name
			material.AmountText.Text = req.Held.."/"..req.Amount
			material.AmountText.TextColor3 = (req.Held >= req.Amount) and Color3.new(1, 1, 1) or Color3.new(1, 0, 0)
			material.Parent = frame
		end
	
		frame.Size = UDim2.new(UDim.new(0, #upgradeData * frame.Template.Size.X.Offset), frame.Size.Y)
	else
		local label = frame.Template:Clone()
		label.Name = "Material"
		label.Visible = true
		label.Icon.Image = itemData.Image
		label.NameText.Text = "MAX\nUPGRADES"
		label.AmountText.Text = "+"..upgrades
		label.Parent = frame
		
		frame.Size = UDim2.new(label.Size.X, frame.Size.Y)
	end
	frame.Visible = true
end

function InventoryClient:Upgrade(itemData)
	itemData = self:GetFullItemData(itemData, self.SelectedTab)
	local upgradeData = self:GetService("WeaponService"):GetUpgradeData(itemData, self.Inventory)
	local canUpgrade = true
	for _, req in pairs(upgradeData) do
		if req.Held < req.Amount then
			canUpgrade = false
			break
		end
	end
	
	local button = self.DetailsFrame.ButtonsFrame.UpgradeButton
	if canUpgrade then
		self:HideUpgrade()
		
		-- request genuine upgrade
		self:FireRemote("ItemUpgraded", self.SelectedTab, self.SelectedIndex)
		
		button.Active = false
		delay(0.5, function()
			button.Active = true
		end)
	else
		-- failure, flash red!
		button.Active = false
		local color = button.BorderColor3
		button.BorderColor3 = Color3.new(1, 0, 0)
		delay(0.5, function()
			button.Active = true
			button.BorderColor3 = color
		end)
	end
end

function InventoryClient:HideUpgrade()
	if not self.UpgradeFrame then return end
	
	self.UpgradeFrame:Destroy()
	self.UpgradeFrame = nil
end

function InventoryClient:ShowSalvage(itemData)
	itemData = self:GetFullItemData(itemData, self.SelectedTab)
	
	local frame = self.DetailsFrame.MaterialsFrame:Clone()
	frame.Name = "SalvageFrame"
	frame.Parent = self.DetailsFrame
	self.SalvageFrame = frame
	
	local salvageData = self:GetService("WeaponService"):GetSalvageData(itemData)
	for _, req in pairs(salvageData) do
		local material = frame.Template:Clone()
		material.Name = "Material"
		material.Visible = true
		material.Icon.Image = req.Material.Image
		material.NameText.Text = req.Material.Name
		material.AmountText.Text = "+"..req.Amount
		material.Parent = frame
	end
	
	frame.Size = UDim2.new(UDim.new(0, #salvageData * frame.Template.Size.X.Offset), frame.Size.Y)
	frame.Visible = true
end

function InventoryClient:HideSalvage()
	if not self.SalvageFrame then return end
	
	self.SalvageFrame:Destroy()
	self.SalvageFrame = nil
end

function InventoryClient:GetItemName(itemData)
	return self:GetService("ItemService"):GetItemNameByItemData(itemData)
end

function InventoryClient:EquipAbility(index)
	local prompt = self.Storage.UI.HotbarPromptFrame:Clone()
	local hotbar = self.Gui.HotbarFrame
	
	local event = Instance.new("BindableEvent")
	
	for slotNumber = 1, 10 do
		local button = prompt.ButtonsFrame["Slot"..slotNumber]
		local slot = hotbar["Ability"..slotNumber]
		
		button.KeyboardButtonLabel.Text = slot.KeyboardButtonLabel.Text
		button.Icon.Image = slot.Icon.Image
		button.Activated:Connect(function()
			self:FireRemote("AbilityEquipped", index, slotNumber)
			event:Fire()
		end)
	end
	
	prompt.CancelButton.Activated:Connect(function()
		event:Fire()
	end)
	
	prompt.Parent = self.Gui
	
	event.Event:Wait()
	
	prompt:Destroy()
end

function InventoryClient:InitItemDetails()
	self.DetailsFrame = self.Frame:WaitForChild("DetailsFrame")
	self.DetailsNameLabel = self.DetailsFrame:WaitForChild("NameLabel")
	self.DetailsDescriptionLabel = self.DetailsFrame:WaitForChild("DescriptionLabel")
	self.DetailsTypeLabel = self.DetailsFrame:WaitForChild("TypeLabel")
	
	self.DetailsEquipButton = self.DetailsFrame:WaitForChild("ButtonsFrame"):WaitForChild("EquipButton")
	self.DetailsEquipButton2 = self.DetailsFrame.ButtonsFrame:WaitForChild("EquipButton2")
	self.DetailsEquipButton3 = self.DetailsFrame.ButtonsFrame:WaitForChild("EquipButton3")
	self.DetailsEquipButton.Activated:Connect(function()
		if self.SelectedTab == "Weapons" then
			self:FireRemote("WeaponEquipped", self.SelectedIndex)
		
		elseif self.SelectedTab == "Abilities" then
			self:EquipAbility(self.SelectedIndex)
			
		elseif self.SelectedTab == "Trinkets" then
			self:FireRemote("TrinketEquipped", self.SelectedIndex, 1)
			
		end
		
		self.ItemEquipped:Fire()
	end)
	self.DetailsEquipButton2.Activated:Connect(function()
		if self.SelectedTab == "Weapons" then
			self:FireRemote("WeaponOffhanded", self.SelectedIndex)
		elseif self.SelectedTab == "Trinkets" then
			self:FireRemote("TrinketEquipped", self.SelectedIndex, 2)
		end
		
		self.ItemEquipped:Fire()
	end)
	self.DetailsEquipButton3.Activated:Connect(function()
		if self.SelectedTab == "Trinkets" then
			self:FireRemote("TrinketEquipped", self.SelectedIndex, 3)
		end
		
		self.ItemEquipped:Fire()
	end)
	
	self.DetailsUpgradeButton = self.DetailsFrame.ButtonsFrame:WaitForChild("UpgradeButton")
	
	local function showUpgrade()
		self:ShowUpgrade(self.Inventory[self.SelectedTab][self.SelectedIndex])
	end
	local function hideUpgrade()
		self:HideUpgrade()
	end
	self.DetailsUpgradeButton.MouseEnter:Connect(showUpgrade)
	self.DetailsUpgradeButton.MouseLeave:Connect(hideUpgrade)
	self.DetailsUpgradeButton.SelectionGained:Connect(showUpgrade)
	self.DetailsUpgradeButton.SelectionLost:Connect(hideUpgrade)
	
	self.DetailsUpgradeButton.Activated:Connect(function()
		self:Upgrade(self.Inventory[self.SelectedTab][self.SelectedIndex])
		
		self.ItemUpgraded:Fire()
	end)
	
	self.DetailsSalvageButton = self.DetailsFrame.ButtonsFrame:WaitForChild("SalvageButton")
	
	local function showSalvage()
		self:ShowSalvage(self.Inventory[self.SelectedTab][self.SelectedIndex])
	end
	local function hideSalvage()
		self:HideSalvage()
	end
	self.DetailsSalvageButton.MouseEnter:Connect(showSalvage)
	self.DetailsSalvageButton.MouseLeave:Connect(hideSalvage)
	self.DetailsSalvageButton.SelectionGained:Connect(showSalvage)
	self.DetailsSalvageButton.SelectionLost:Connect(hideSalvage)
	
	self.DetailsSalvageButton.Activated:Connect(function()
		local itemData = self.Inventory[self.SelectedTab][self.SelectedIndex]
		if self.SelectedTab == "Weapons" then
			itemData = self:GetService("WeaponService"):GetWeaponData(itemData)
		elseif self.SelectedTab == "Abilities" then
			itemData = self:GetService("AbilityService"):GetAbilityData(itemData.Id, self:GetPlayerLevel())
		elseif self.SelectedTab == "Trinkets" then
			itemData = self:GetService("ItemService"):GetItemData("Trinkets", itemData)
		end
		local promptText = string.format("Are you sure you want to salvage your %s?", self:GetItemName(itemData))
		
		local result = self:GetService("GuiClient"):ShowPrompt(promptText)
		if not result then return end
		
		self:FireRemote("ItemSalvaged", self.SelectedTab, self.SelectedIndex)
		
		if GuiService.SelectedObject then
			GuiService.SelectedObject = self.ContentFrame:FindFirstChildOfClass("ImageButton")
		end
	end)
	
	self.DetailsFavoriteButton = self.DetailsFrame.ButtonsFrame:WaitForChild("FavoriteButton")
	
	self.DetailsFavoriteButton.Activated:Connect(function()
		self:FireRemote("ItemFavorited", self.SelectedTab, self.SelectedIndex)
	end)
	
	-- Kensai666 was here
	-- next to the definition for the discard button
	-- at home next to the trash can where he belongs
	
	self.DetailsDiscardButton = self.DetailsFrame.ButtonsFrame:WaitForChild("DiscardButton")
	self.DetailsDiscardButton.Activated:Connect(function()
		local itemData = self.Inventory[self.SelectedTab][self.SelectedIndex]
		
		if self.SelectedTab == "Materials" then
			local name = self:GetService("MaterialService"):GetMaterialData(itemData.Id).Name
			
			local prompt = self:CreateNew"AmountPromptGui"{
				DefaultValue = 1,
				MinValue = 1,
				MaxValue = itemData.Amount,
				PromptText = string.format("How many of \"%s\" would you like to discard?", name),
				ConfirmText = "Confirm",
				CancelText = "Cancel",
				Parent = self.Gui,
			}
			
			local result, amount = prompt.Completed:Wait()
			if not result then return end
			
			self:FireRemote("MaterialDiscarded", self.SelectedIndex, amount)
		else
			if self.SelectedTab == "Weapons" then
				itemData = self:GetService("WeaponService"):GetWeaponData(itemData)
			elseif self.SelectedTab == "Abilities" then
				itemData = self:GetService("AbilityService"):GetAbilityData(itemData.Id, self:GetPlayerLevel())
			elseif self.SelectedTab == "Trinkets" then
				itemData = self:GetService("ItemService"):GetItemData("Trinkets", itemData)
			end
			
			local promptText = string.format("Are you sure you want to discard your %s?", self:GetItemName(itemData))
			
			local result = self:GetService("GuiClient"):ShowPrompt(promptText)
			if not result then return end
			
			if self.SelectedTab == "Weapons" then
				self:FireRemote("WeaponDiscarded", self.SelectedIndex)
				
			elseif self.SelectedTab == "Abilities" then
				self:FireRemote("AbilityDiscarded", self.SelectedIndex)
				
			elseif self.SelectedTab == "Trinkets" then
				self:FireRemote("TrinketDiscarded", self.SelectedIndex)
			end
		end
		
		if GuiService.SelectedObject then
			GuiService.SelectedObject = self.ContentFrame:FindFirstChildOfClass("ImageButton")
		end
	end)
	
	self:ClearItemDetails()
end

function InventoryClient:ClearItemDetails()
	self.DetailsNameLabel.Text = ""
	self.DetailsTypeLabel.Text = ""
	self.DetailsDescriptionLabel.Text = ""
	self.DetailsEquipButton.Visible = false
	self.DetailsEquipButton2.Visible = false
	self.DetailsEquipButton3.Visible = false
	self.DetailsUpgradeButton.Visible = false
	self.DetailsDiscardButton.Visible = false
	self.DetailsSalvageButton.Visible = false
	self.DetailsFavoriteButton.Visible = false
end

function InventoryClient:IsMouseInsideGui(gui)
	local guiPosition = gui.AbsolutePosition
	local guiSize = gui.AbsoluteSize
	local mousePosition = UIS:GetMouseLocation() + Vector2.new(0, -36)
	
	local inX = (mousePosition.X > guiPosition.X) and (mousePosition.X < guiPosition.X + guiSize.X)
	local inY = (mousePosition.Y > guiPosition.Y) and (mousePosition.Y < guiPosition.Y + guiSize.Y)
	
	return inX and inY
end

function InventoryClient:GetPlayerLevel()
	return self:GetClass("GuiClient").Level
end

function InventoryClient:ShowItemDetails(index, slotData)
	self:ClearItemDetails()
	
	local itemData
	if self.SelectedTab == "Materials" then
		itemData = self:GetService("MaterialService"):GetMaterialData(slotData.Id)
	elseif self.SelectedTab == "Weapons" then
		itemData = self:GetService("WeaponService"):GetWeaponData(slotData)
	elseif self.SelectedTab == "Abilities" then
		itemData = self:GetService("AbilityService"):GetAbilityData(slotData.Id, self:GetPlayerLevel())
	elseif self.SelectedTab == "Trinkets" then
		itemData = self:GetService("ItemService"):GetItemData("Trinkets", slotData)
	end
	for key, val in pairs(slotData) do
		itemData[key] = val
	end
	
	self.DetailsNameLabel.TextColor3 = Color3.new(1, 1, 1)
	self.DetailsNameLabel.Text = self:GetItemName(itemData)
	
	self.DetailsFavoriteButton.Text = itemData.Favorited and "Unfavorite\n🌟" or "Favorite\n⭐"
	
	if self.SelectedTab == "Weapons" then
		local weaponClass = self:GetClass(itemData.Class):Extend()
		weaponClass.Data = itemData
		if itemData.Args then
			for key, val in pairs(itemData.Args) do
				weaponClass[key] = val
			end
		end
		self.DetailsTypeLabel.Text = string.format([[%s | %s]], weaponClass.DisplayName, weaponClass.PrimaryStatName)
		local description = weaponClass:GetDescription(self:GetPlayerLevel(), itemData)
		
		if (index ~= self.Inventory.EquippedWeaponIndex) and (index ~= self.Inventory.OffhandWeaponIndex) then
			self.DetailsEquipButton.Visible = true
			self.DetailsEquipButton2.Visible = true
			self.DetailsDiscardButton.Visible = true
			self.DetailsSalvageButton.Visible = (itemData.UpgradeMaterials ~= nil) and (not itemData.SalvageDisabled)
		end
		
		self.DetailsUpgradeButton.Visible = (itemData.UpgradeMaterials ~= nil)
		self.DetailsFavoriteButton.Visible = true
		
		if itemData.Rarity == "Rare" then
			self.DetailsNameLabel.TextColor3 = Colors.Rare
		elseif itemData.Rarity == "Mythic" then
			self.DetailsNameLabel.TextColor3 = Colors.Mythic
		elseif itemData.Rarity == "Legendary" then
			self.DetailsNameLabel.TextColor3 = Colors.Legendary
		end
		
		if itemData.Perks then
			for _, perk in pairs(itemData.Perks) do
				local s
				if typeof(perk) == "function" then
					s = perk(weaponClass)
				else
					s = perk
				end
				description = description.."\n🔶 "..s
			end
		end
		
		self.DetailsDescriptionLabel.Text = description
	
	elseif self.SelectedTab == "Abilities" then
		local abilityClass = self:GetClass(itemData.Class):Extend()
		abilityClass.Data = itemData
		
		self.DetailsTypeLabel.Text = abilityClass:GetTypeString().." Ability"
		self.DetailsDescriptionLabel.Text = abilityClass:GetDescription()
		
		self.DetailsEquipButton.Visible = true
		
		local indices = self.Inventory.EquippedAbilityIndices
		if table.find(indices, index) == nil then
			self.DetailsSalvageButton.Visible = (itemData.UpgradeMaterials ~= nil) and (not itemData.SalvageDisabled)
			self.DetailsDiscardButton.Visible = true	
		end
		
		self.DetailsUpgradeButton.Visible = (itemData.UpgradeMaterials ~= nil)
		self.DetailsFavoriteButton.Visible = true
		
	elseif self.SelectedTab == "Trinkets" then
		self.DetailsTypeLabel.Text = "Trinket"
		
		local trinket = self:CreateNew"Trinket"{Data = itemData}
		self.DetailsDescriptionLabel.Text = trinket:GetDescription()
		
		local indices = self.Inventory.EquippedTrinketIndices
		local isEquipped = (table.find(indices, index) ~= nil)
		self.DetailsEquipButton.Visible = not isEquipped
		self.DetailsEquipButton2.Visible = not isEquipped
		self.DetailsEquipButton3.Visible = not isEquipped
		self.DetailsDiscardButton.Visible = not isEquipped
		self.DetailsSalvageButton.Visible = (itemData.UpgradeMaterials ~= nil) and (not itemData.SalvageDisabled) and (not isEquipped)
		
		self.DetailsUpgradeButton.Visible = (itemData.UpgradeMaterials ~= nil)
		self.DetailsFavoriteButton.Visible = true
	
	elseif self.SelectedTab == "Materials" then
		self.DetailsTypeLabel.Text = "Material"
		self.DetailsDescriptionLabel.Text = itemData.Description
		
		self.DetailsDiscardButton.Visible = true
	end
	
	if itemData.Favorited then
		self.DetailsSalvageButton.Visible = false
		self.DetailsDiscardButton.Visible = false
	end
	
	-- upgrade hover?
	local upgradeButton = self.DetailsUpgradeButton
	if upgradeButton.Visible and self:IsMouseInsideGui(upgradeButton) then
		self:ShowUpgrade(itemData)
	end
end

function InventoryClient:OnAlignmentUpdated(alignment)
	local frame = self.Frame:WaitForChild("AlignmentFrame")
	for name, amount in pairs(alignment) do
		frame:WaitForChild(name.."Frame"):WaitForChild("AmountLabel").Text = amount
	end
end

function InventoryClient:OnInventoryUpdated(inventory)
	self.Inventory = inventory
	
	if not self.SelectedTab then
		self:SelectTab("Weapons")
	end
	
	local gamepadEnabled = GuiService.SelectedObject ~= nil
	
	self:ClearContent()
	self:ClearItemDetails()
	self:ShowContent()
	
	local selectedContent
	for content, itemIndex in pairs(self.ItemIndexByContent) do
		if itemIndex == self.SelectedIndex then
			selectedContent = content
			break
		end
	end
	if selectedContent then
		self:SelectContent(selectedContent)
	end
	
	if self.Frame.Visible and gamepadEnabled then
		GuiService.SelectedObject = selectedContent
	end
	
	CAS:UnbindAction("GamepadExitDetailsButtons")
	GuiService:RemoveSelectionGroup("GamepadDetailsButtons")
	
	self.Gui.GoldFrame.AmountLabel.Text = inventory.Gold
	
	self:UpdateQuickSwitch()
end

function InventoryClient:UpdateQuickSwitch()
	if not self.WeaponIcon then
		self.WeaponIcon = self.Gui:WaitForChild("WeaponFrame"):WaitForChild("Icon")
	end
	
	local slotData = self.Inventory.Weapons[self.Inventory.EquippedWeaponIndex]
	local itemData = self:GetService("ItemService"):GetItemData("Weapons", slotData)
	self.WeaponIcon.Image = itemData.Image
end

function InventoryClient:ToggleVisibility(visible)
	if visible ~= nil then
		self.Frame.Visible = visible
	else
		self.Frame.Visible = not self.Frame.Visible
	end
	self.Toggled:Fire(visible)
end

local Singleton = InventoryClient:Create()
return Singleton