local Super = require(script.Parent)
local ShopClient = Super:Extend()

local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Configuration = require(game:GetService("ReplicatedStorage"):WaitForChild("Configuration"))

function ShopClient:OnCreated()
	self.SelectedTab = nil
	
	self.Gui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Gui")
	
	self.Frame = self.Gui:WaitForChild("ShopFrame")
	
	-- set up the toggle button
	self.ToggleButton = self.Gui:WaitForChild("ShopButton")
	local function onToggleButtonActivated()
		self:ToggleVisibility()
	end
	self.ToggleButton.Activated:Connect(onToggleButtonActivated)
	self.Frame:WaitForChild("ClickOutButton").Activated:Connect(onToggleButtonActivated)
		
	self:InitContent()
	self:InitTabButtons()
	self:InitGamepad()
	
	self:InitPromos()
	self:ConnectRemote("PromoSubmitted", self.OnPromoSubmitted, false)
	
	self:ConnectRemote("CosmeticsUpdated", self.OnCosmeticsUpdated, false)
	spawn(function()
		self:OnCosmeticsUpdated(self.Storage:WaitForChild("Remotes"):WaitForChild("GetPlayerCosmetics"):InvokeServer())
	end)
end

function ShopClient:InitPromos()
	self.PromoFrame = self.Frame:WaitForChild("PromoFrame")
	
	local function onSubmitted()
		self:FireRemote("PromoSubmitted", self.PromoFrame.TextBox.Text)
	end
	self.PromoFrame.SubmitButton.Activated:Connect(onSubmitted)
	self.PromoFrame.TextBox.FocusLost:Connect(function(submitted)
		if submitted then
			onSubmitted()
		end
	end)
end

function ShopClient:OnPromoSubmitted()
	local title = self.PromoFrame.Title
	title.Text = "Invalid Code"
	delay(2, function()
		title.Text = "Promo Codes"
	end)
end

function ShopClient:OnCosmeticsUpdated(cosmetics)
	self.Cosmetics = cosmetics
	
	if not self.SelectedTab then
		self:SelectTab("Animations")
	end
	
	self:ClearContent()
	self:ShowContent()
end

function ShopClient:GamepadToggleVisibility()
	self:ToggleVisibility()
	
	local frame = self.Frame
	if frame.Visible then
		GuiService:AddSelectionParent("GamepadShop", self.ContentFrame)
		GuiService.SelectedObject = frame.ContentFrame:FindFirstChildOfClass("Frame").EquipButton
		
		CAS:BindAction("GamepadCloseShop", function(name, state, input)
			if state ~= Enum.UserInputState.Begin then return end
			self:GamepadToggleVisibility()
		end, false, Enum.KeyCode.ButtonB)
		
		CAS:BindAction("GamepadShopChangeTab", function(name, state, input)
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
		GuiService:RemoveSelectionGroup("GamepadShop")
		GuiService.SelectedObject = nil
		
		CAS:UnbindAction("GamepadCloseShop")
		CAS:UnbindAction("GamepadShopChangeTabs")
	end
end

function ShopClient:InitGamepad()
	CAS:BindAction("GamepadToggleShop", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		self:GamepadToggleVisibility()
		
	end, false, Enum.KeyCode.DPadDown)
	
	self.GamepadTabs = {"Animations", "Accessories", "Effects"}
	self.GamepadTabIndex = 1
end

function ShopClient:GamepadContentActivated()
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

function ShopClient:InitContent()
	self.ContentFrame = self.Frame:WaitForChild("ContentFrame")
	self.ContentTemplate = self.ContentFrame:WaitForChild("TemplateFrame")
end

function ShopClient:ClearContent()
	self.ItemIndexByContent = {}
	for _, child in pairs(self.ContentFrame:GetChildren()) do
		if child.Name == "Frame" then
			child:Destroy()
		end
	end
end

function ShopClient:InitTabButtons()
	local tabsFrame = self.Frame:WaitForChild("TabsFrame")
	self.TabButtons = {
		tabsFrame:WaitForChild("AnimationsButton"),
		tabsFrame:WaitForChild("AccessoriesButton"),
		tabsFrame:WaitForChild("EffectsButton"),
	}
	
	tabsFrame.AnimationsButton.Activated:Connect(function()
		self:SelectTab("Animations")
	end)
	tabsFrame.AccessoriesButton.Activated:Connect(function()
		self:SelectTab("Accessories")
	end)
	tabsFrame.EffectsButton.Activated:Connect(function()
		self:SelectTab("Effects")
	end)
end

function ShopClient:SelectTab(tab)
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
	self:ShowContent()
end

function ShopClient:GetDisplayNameFromCategory(category)
	local displayNameByCategory = {
		DoorkickAnimation = "Doorkick Animation",
		Lantern = "Lantern",
		DoorEffect = "Doorkick Effect",
		HitEffect = "On-hit Effect",
		KillEffect = "On-kill Effect",
		CelebrationAnimation = "Celebration Animation",
		CelebrationEmote = "Celebration Emote",
	}
	
	return displayNameByCategory[category]
end

function ShopClient:ShowContent()
	local tab = self.SelectedTab
	
	-- TODO: replace with server call for real information
	local productInfo = require(self.Storage.ProductData)
	local productCount = 0
	
	local layoutOrder = 0
	
	local function showCategory(categoryName)
		for id, product in ipairs(productInfo[categoryName]) do
			local content = self.Frame.ContentFrame.TemplateFrame:Clone()
			content.Name = "Frame"
			content.Visible = true
			content.NameLabel.Text = product.Name
			content.TypeLabel.Text = self:GetDisplayNameFromCategory(categoryName)
			content.PriceLabel.Text = (product.Price ~= nil) and (product.Price.." R$") or ("")
			content.Icon.Image = product.Image
			content.DescriptionLabel.Text = product.Description
			content.LayoutOrder = layoutOrder
			
			layoutOrder += 1
			
			local debounce = true
			local function onSelectionGained()
				if not debounce then return end
				debounce = false
				GuiService.SelectedObject = content
				GuiService.SelectedObject = content.EquipButton
				debounce = true
			end
			
			local equipButton = content.EquipButton
			equipButton.SelectionGained:Connect(onSelectionGained)
			
			local isEquipped = (self.Cosmetics.Equipped[categoryName] == id)
			local isPurchased = (product.ProductId == nil) or (table.find(self.Cosmetics.Purchased, product.ProductId) ~= nil)
			if isEquipped then
				equipButton.Text = "Equipped"
			else
				if isPurchased then
					equipButton.Text = "Equip"
					
					equipButton.Activated:Connect(function()
						self:FireRemote("CosmeticEquipped", categoryName, id)
					end)
				else
					equipButton.Text = "Buy"
					
					equipButton.Activated:Connect(function()
						MarketplaceService:PromptProductPurchase(Players.LocalPlayer, product.ProductId)
					end)
				end
			end
			
			if product.Offsale and (not isPurchased) then
				content.Visible = false
			end
			
			if isPurchased then
				content.PriceLabel.Visible = false
			end
			
			if product.UnlimitedItem then
				if not self.Cosmetics.IsUnlimited then
					equipButton.Visible = false
				end
			end
			
			content.Parent = self.Frame.ContentFrame
			
			productCount = productCount + 1
		end	
	end
	
	if tab == "Animations" then
		showCategory("DoorkickAnimation")
		showCategory("CelebrationAnimation")
	elseif tab == "Accessories" then
		showCategory("Lantern")
	elseif tab == "Effects" then
		--showCategory("DoorEffect")
		showCategory("HitEffect")
		showCategory("KillEffect")
		showCategory("CelebrationEmote")
	else
		return
	end
	
	local rows = math.ceil(productCount / 2)
	local padding = self.ContentFrame.UIGridLayout.CellPadding.Y.Offset
	local height = rows * (self.ContentFrame.UIGridLayout.CellSize.Y.Offset + padding) - padding
	self.ContentFrame.CanvasSize = UDim2.new(0, 0, 0, height)
	
	return layoutOrder
end

function ShopClient:ToggleVisibility(visible)
	if visible ~= nil then
		self.Frame.Visible = visible
	else
		self.Frame.Visible = not self.Frame.Visible
	end
end

local Singleton = ShopClient:Create()
return Singleton