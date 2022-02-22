local Super = require(script.Parent)
local PurchaseService = Super:Extend()

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

PurchaseService.ExpansionProductIds = {
	1087064193,
}

function PurchaseService:OnCreated()
	spawn(function()
		require(self.Storage.ProductData)
	end)
	
	local function processReceipt(...)
		return self:ProcessReceipt(...)
	end
	MarketplaceService.ProcessReceipt = processReceipt
	
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(...)
		self:OnPromptGamePassPurchaseFinished(...)
	end)
	
	self:ConnectRemote("CosmeticEquipped", self.OnCosmeticEquipped, true)
end

function PurchaseService:IsProductOffsale(productId)
	local productData = require(self.Storage.ProductData)
	
	for category, products in pairs(productData) do
		for _, product in pairs(products) do
			if product.ProductId == productId then
				if product.Offsale then
					return true
				end
			end
		end
	end
	
	return false
end

function PurchaseService:ProcessReceipt(info)
	self:GetService("AnalyticsService"):ProcessReceiptInfo(info)
	
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then return end
	
	local dataService = self:GetService("DataService")
	local purchases = dataService:GetPlayerPurchases(player)
	if not purchases then return end
	
	if self:IsProductOffsale(info.ProductId) then return end
	
	table.insert(purchases.Products, info.ProductId)
	self:FireRemote("CosmeticsUpdated", player, dataService:GetPlayerCosmetics(player))
	
	if table.find(self.ExpansionProductIds, info.ProductId) then
		self:FireRemote("ExpansionPackThanked", player)
	end
	
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function PurchaseService:OnPromptGamePassPurchaseFinished(player, gamePassId, wasPurchased)
	if not wasPurchased then return end
	
	self:FireRemote("CosmeticsUpdated", player, self:GetService("DataService"):GetPlayerCosmetics(player))
	
	if gamePassId == 11776128 then
		self:FireRemote("UnlimitedThanked", player)
	end
end

function PurchaseService:OnCosmeticEquipped(player, categoryName, id)
	local dataService = self:GetService("DataService")
	local data = dataService:GetPlayerData(player)
	local purchases = dataService:GetPlayerPurchases(player)
	
	local productData = require(self.Storage.ProductData)
	
	local category = productData[categoryName]
	if not category then return end
	
	local product = category[id]
	if not product then return end
	
	local purchased
	if product.UnlimitedItem then
		purchased = MarketplaceService:UserOwnsGamePassAsync(player.UserId, 11776128)
	else
		purchased = (product.ProductId == nil) or (table.find(purchases.Products, product.ProductId) ~= nil)
	end
	if not purchased then return end
	
	data.Cosmetics[categoryName] = id
	self:FireRemote("CosmeticsUpdated", player, dataService:GetPlayerCosmetics(player))
	
	if categoryName == "Lantern" then
		local legend = self:GetClass("Legend").GetLegendFromPlayer(player)
		if legend then
			legend:InitLantern()
		end
	end
end

local Singleton = PurchaseService:Create()
return Singleton