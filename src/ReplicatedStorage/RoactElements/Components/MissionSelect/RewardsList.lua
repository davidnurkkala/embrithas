--[[
	Shows a list of rewards for a mission.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local RewardItem = require(main.Components.MissionSelect.RewardItem)

local RewardsList = Roact.PureComponent:extend("RewardsList")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Rewards = t.table,
	LayoutOrder = t.optional(t.integer),
	Claimed = t.optional(t.boolean),
})

RewardsList.defaultProps = {
	LayoutOrder = 1,
	Claimed = false,
}

function RewardsList:init(props)
	assert(typecheck(props))
end

function RewardsList:render()
	local props = self.props

	local rewardIcons = {}
	for num, entry in ipairs(props.Rewards) do
		rewardIcons[num] = Roact.createElement(RewardItem, {
			LayoutOrder = num,
			Reward = entry,
			Claimed = props.Claimed,
		})
	end

	return Roact.createElement("Frame", {
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.new(1, 0, 0, 100),
		BackgroundTransparency = 1,
	}, {
		Layout = Roact.createElement("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),

		Rewards = Roact.createFragment(rewardIcons),
	})
end

return RewardsList
