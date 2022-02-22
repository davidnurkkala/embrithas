--[[
	Shows a list of small reward icons seen in a Tooltip.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local ItemData = require(game.ReplicatedStorage.ItemData)
local FactionData = require(game.ReplicatedStorage.FactionData)
local ProductData = require(game.ReplicatedStorage.ProductData)
local RarityColors = require(game.ReplicatedStorage.RarityColors)

local BodyRewards = Roact.PureComponent:extend("BodyRewards")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Rewards = t.table,
	LayoutOrder = t.optional(t.integer),
})

function BodyRewards:init(props)
	assert(typecheck(props))
end

function BodyRewards:renderReward(reward, xPos, yPos)
	local item
	if reward.Type == "Weapon" then
		item = ItemData.Weapons[reward.Id]
	elseif reward.Type == "Ability" then
		item = ItemData.Abilities[reward.Id]
	elseif reward.Type == "Trinket" then
		item = ItemData.Trinkets[reward.Id]
	elseif reward.Type == "Material" then
		item = ItemData.Materials[reward.Id]
	elseif reward.Type == "Alignment" then
		local faction = reward.Faction
		local image = FactionData[faction].Image
		item = {Image = image}
	elseif reward.Type == "Product" then
		local product = ProductData[reward.Category][reward.Id]
		item = {Image = product.Image}
	end

	return Roact.createElement("ImageLabel", {
		BackgroundColor3 = Color3.new(0.2, 0.2, 0.2),
		Position = UDim2.fromOffset(xPos, yPos),
		BorderSizePixel = 0,
		Image = item.Image,
		Size = UDim2.fromOffset(88, 88),
	}, {
		NumberLabel = reward.Amount ~= nil and Roact.createElement("TextLabel", {
			Position = UDim2.fromScale(1, 1),
			AnchorPoint = Vector2.new(1, 1),
			Size = UDim2.fromScale(0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			Text = reward.Amount,
			Font = Enum.Font.GothamSemibold,
			TextSize = 24,
			TextColor3 = reward.Amount > 0 and Color3.new() or Color3.new(1, 1, 1),
			BackgroundColor3 = reward.Amount > 0 and Color3.new(1, 1, 1) or Color3.new(1, 0, 0),
			BorderSizePixel = 0,
		}, {
			Padding = Roact.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 5),
				PaddingBottom = UDim.new(0, 5),
				PaddingLeft = UDim.new(0, 5),
				PaddingRight = UDim.new(0, 5),
			}),
		}) or nil,

		RarityBar = item.Rarity ~= nil and RarityColors[item.Rarity] ~= nil
			and Roact.createElement("Frame", {
			Size = UDim2.new(0, 4, 1, -10),
			Position = UDim2.new(0, 6, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = RarityColors[item.Rarity],
			BorderSizePixel = 0,
		}) or nil,
	})
end

function BodyRewards:render()
	local props = self.props

	local rewardIcons = {}
	local xPos = 0
	local yPos = 0
	local cells = 0
	local maxCells = 5
	local height = 88
	for num, entry in ipairs(props.Rewards) do
		if cells == maxCells then
			cells = 0
			xPos = 0
			yPos = yPos + 88 + 5
			height = height + 88 + 5
		end
		rewardIcons[num] = self:renderReward(entry, xPos, yPos)
		cells = cells + 1
		xPos = xPos + 88 + 5
	end

	return Roact.createElement("Frame", {
		LayoutOrder = props.LayoutOrder,
		--AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
	}, {
		RewardIcons = Roact.createFragment(rewardIcons),
	})
end

return BodyRewards
