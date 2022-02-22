local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Super = require(script.Parent)
local ExpansionPromptGui = Super:Extend()

function ExpansionPromptGui:OnCreated()
	self.Gui = self.Storage:WaitForChild("UI"):WaitForChild("ExpansionPromptFrame"):Clone()
	
	self.Gui.TitleText.Text = string.format("This mission requires \"%s.\"", self.Product.Name)
	self.Gui.DescriptionText.Text = self.Product.Description
	
	local buttonsFrame = self.Gui.ButtonsFrame
	buttonsFrame.UnlimitedButton.Activated:Connect(function()
		self:Close()
		MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, 11776128)
	end)
	buttonsFrame.PackButton.Activated:Connect(function()
		self:Close()
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, self.Product.ProductId)
	end)
	
	local function close()
		self:Close()
	end
	buttonsFrame.CancelButton.Activated:Connect(close)
	self.Gui.ClickOutButton.Activated:Connect(close)
	
	self.Gui.Parent = self.Parent
end

function ExpansionPromptGui:Close()
	self.Gui:Destroy()
end

return ExpansionPromptGui