--[[
	Shows reward and its details as a tooltip.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local ItemData = require(game.ReplicatedStorage.ItemData)
local FactionData = require(game.ReplicatedStorage.FactionData)
local ProductData = require(game.ReplicatedStorage.ProductData)
local RarityColors = require(game.ReplicatedStorage.RarityColors)

local main = game.ReplicatedStorage.RoactElements
local GuiObjectContext = require(main.Contexts.GuiObjectContext)
local BaseTooltip = require(main.Components.Base.BaseTooltip)
local BodyText = require(main.Components.Tooltip.BodyText)
local BodyBulletPoints = require(main.Components.Tooltip.BodyBulletPoints)
local DefaultHeader = require(main.Components.Tooltip.DefaultHeader)
local BodyHeader = require(main.Components.Tooltip.BodyHeader)

local RewardTooltip = Roact.PureComponent:extend("RewardTooltip")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Reward = t.table,
	Claimed = t.optional(t.boolean),
})

function RewardTooltip:init(props)
	assert(typecheck(props))
end

function RewardTooltip:render()
	local GuiObject = GuiObjectContext:Get(self)

	local props = self.props
	local reward = props.Reward

	local item, itemType, name, description
	if reward.Type == "Alignment" then
		local faction = reward.Faction
		local factionName = FactionData[faction].Name
		itemType = string.format("%s Alignment", factionName)
		description = "Your alignment with this faction will change by "..reward.Amount
		if reward.Reason then
			description = description.." because "..reward.Reason
		else
			description = description.."."
		end
		name = reward.Amount > 0 and "Alignment Increase" or "Alignment Decrease"
	else
		if reward.Type == "Weapon" then
			item = ItemData.Weapons[reward.Id]
			itemType = GuiObject:GetClass(item.Class).DisplayName
		elseif reward.Type == "Ability" then
			item = ItemData.Abilities[reward.Id]
			itemType = "Ability"
		elseif reward.Type == "Trinket" then
			item = ItemData.Trinkets[reward.Id]
			itemType = "Trinket"
		elseif reward.Type == "Material" then
			item = ItemData.Materials[reward.Id]
			itemType = "Material"
		elseif reward.Type == "Product" then
			item = ProductData[reward.Category][reward.Id]
			itemType = "Cosmetic "..GuiObject:GetClass("ShopClient"):GetDisplayNameFromCategory(reward.Category)
		end
		description = item.Description
		name = item.Name
	end

	local entries = {
		string.format("Drop Rate: %s", (reward.Chance and reward.Chance < 1)
			and string.format("%.1f%%", reward.Chance * 100) or "Guaranteed"),
	}
	if reward.Amount and reward.Amount ~= 1 then
		table.insert(entries, string.format("Amount: %i", reward.Amount))
	end

	return Roact.createElement(BaseTooltip, {
		HeaderColor = item and item.Rarity and RarityColors[item.Rarity] or Color3.new(),
		RenderHeader = function()
			return Roact.createElement(DefaultHeader, {
				Title = name,
				Subtitle = itemType,
			})
		end,

		RenderBody = function(layout)
			return Roact.createFragment({
				Claimed = props.Claimed and Roact.createElement(BodyHeader, {
					LayoutOrder = layout(),
					Text = "✅ Already Claimed",
				}),

				Description = Roact.createElement(BodyText, {
					LayoutOrder = layout(),
					Text = description,
				}),

				BulletPoints = Roact.createElement(BodyBulletPoints, {
					LayoutOrder = layout(),
					Entries = entries,
				}),
			})
		end,
	})
end

return RewardTooltip
