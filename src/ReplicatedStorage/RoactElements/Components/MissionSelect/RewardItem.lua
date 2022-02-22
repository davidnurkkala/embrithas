--[[
	Shows a single reward in a RewardsList.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local ItemData = require(game.ReplicatedStorage.ItemData)
local FactionData = require(game.ReplicatedStorage.FactionData)
local ProductData = require(game.ReplicatedStorage.ProductData)
local RarityColors = require(game.ReplicatedStorage.RarityColors)

local main = game.ReplicatedStorage.RoactElements
local RewardTooltip = require(main.Components.MissionSelect.RewardTooltip)

local RewardItem = Roact.PureComponent:extend("RewardItem")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Reward = t.table,
	LayoutOrder = t.optional(t.integer),
	Claimed = t.optional(t.boolean),
})

RewardItem.defaultProps = {
	LayoutOrder = 1,
	Claimed = false,
}

function RewardItem:init(props)
	assert(typecheck(props))
	self.state = {
		hovered = false,
	}

	self.mouseEnter = function()
		self:setState({
			hovered = true,
		})
	end

	self.mouseLeave = function()
		self:setState({
			hovered = false,
		})
	end
end

function RewardItem:render()
	local props = self.props
	local reward = props.Reward

	local state = self.state
	local hovered = state.hovered

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
		LayoutOrder = props.LayoutOrder,
		BorderSizePixel = 0,
		Image = item.Image,
		Size = UDim2.fromOffset(100, 100),
		[Roact.Event.MouseEnter] = self.mouseEnter,
		[Roact.Event.MouseLeave] = self.mouseLeave,
	}, {
		NumberLabel = reward.Amount ~= nil and Roact.createElement("TextLabel", {
			Position = UDim2.fromScale(1, 1),
			AnchorPoint = Vector2.new(1, 1),
			Size = UDim2.fromScale(0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			Text = reward.Amount,
			Font = Enum.Font.GothamSemibold,
			TextSize = 28,
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

		ClaimedIcon = props.Claimed and Roact.createElement("TextLabel", {
			ZIndex = 2,
			Text = "✅",
			TextSize = 24,
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(1, -10, 0, 10),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		}),

		RarityBar = item.Rarity ~= nil and RarityColors[item.Rarity] ~= nil
			and Roact.createElement("Frame", {
			Size = UDim2.new(0, 6, 1, -10),
			Position = UDim2.new(0, 6, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = RarityColors[item.Rarity],
			BorderSizePixel = 0,
		}) or nil,

		Tooltip = hovered and Roact.createElement(RewardTooltip, {
			Reward = reward,
			Claimed = props.Claimed,
		}),
	})
end

return RewardItem
