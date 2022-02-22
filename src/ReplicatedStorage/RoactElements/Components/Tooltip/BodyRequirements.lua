--[[
	Default requirements list for a Tooltip.
	Shows a mission's requirements and status.
]]

local ProductData = require(game.ReplicatedStorage.ProductData)
local Roact = require(game.ReplicatedStorage.Packages.Roact)
local Cryo = require(game.ReplicatedStorage.Packages.Cryo)

local main = game.ReplicatedStorage.RoactElements
local AutomaticSize = require(main.Components.Base.AutomaticSize)
local GuiObjectContext = require(main.Contexts.GuiObjectContext)

local BodyRequirements = Roact.PureComponent:extend("BodyRequirements")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Requirements = t.table,
	UnmetRequirements = t.table,
	Mission = t.interface({
		RequiredExpansion = t.optional(t.integer),
	}),
	Alignment = t.table,
	CurrentLevel = t.optional(t.integer),
	LayoutOrder = t.optional(t.integer),
})

BodyRequirements.defaultProps = {
	LayoutOrder = 1,
	CurrentLevel = 0,
}

function BodyRequirements:getRequirementText(requirement)
	local LobbyClient = GuiObjectContext:GetLobbyClient(self)
	if requirement.Type == "Mission" then
		local missionName = LobbyClient:GetMissionNameFromId(requirement.Id)
		return string.format([[Complete Mission <b>"%s"</b>]], missionName)
	elseif requirement.Type == "Alignment" then
		local factionName = LobbyClient:GetFactionName(requirement.Faction)
		return string.format([[Minimum %s Alignment: <b>%i</b>]], factionName, requirement.Amount)
	elseif requirement.Type == "Level" then
		return string.format([[Minimum Level: <b>%i</b>]], requirement.Level)
	elseif requirement.Type == "Expansion" then
		return string.format([[<b>%s</b>]], requirement.Name)
	end
end

function BodyRequirements:getFailureText(requirement)
	local props = self.props
	if requirement.Type == "Mission" then
		return "Mission Not Completed"
	elseif requirement.Type == "Alignment" then
		local alignment = props.Alignment[requirement.Faction]
		return string.format([[Current Alignment: <b>%i</b>]], alignment)
	elseif requirement.Type == "Level" then
		return string.format([[Current Level: <b>%i</b>]], props.CurrentLevel)
	elseif requirement.Type == "Expansion" then
		return "Expansion Not Owned"
	end
end

function BodyRequirements:renderUnmetRequirement(requirement, layout)
	local text = self:getRequirementText(requirement)
	local failureText = self:getFailureText(requirement)
	return Roact.createFragment({
		Label = Roact.createElement("TextLabel", {
			LayoutOrder = layout(),
			Text = text,
			RichText = true,
			TextWrapped = true,
			Font = Enum.Font.GothamSemibold,
			TextSize = 24,
			TextColor3 = Color3.fromRGB(255, 0, 0),
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			AutomaticSize = Roact.createElement(AutomaticSize),
			Padding = Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 35),
			}),

			Mark = Roact.createElement("TextLabel", {
				Text = "🟥",
				TextSize = 24,
				Font = Enum.Font.GothamSemibold,
				AutomaticSize = Enum.AutomaticSize.XY,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromOffset(-10, 0),
				BackgroundTransparency = 1,
			}),
		}),

		FailureText = Roact.createElement("TextLabel", {
			LayoutOrder = layout(),
			Text = "• " .. failureText,
			RichText = true,
			TextWrapped = true,
			Font = Enum.Font.GothamSemibold,
			TextSize = 24,
			TextColor3 = Color3.fromRGB(255, 0, 0),
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			AutomaticSize = Roact.createElement(AutomaticSize),
			Padding = Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 35),
			}),
		}),
	})
end

function BodyRequirements:renderMetRequirement(requirement, layout)
	local text = self:getRequirementText(requirement)
	return Roact.createFragment({
		Label = Roact.createElement("TextLabel", {
			LayoutOrder = layout(),
			Text = string.format("<s>%s</s>", text),
			RichText = true,
			TextWrapped = true,
			Font = Enum.Font.GothamSemibold,
			TextSize = 24,
			TextColor3 = Color3.fromRGB(34, 139, 34),
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			AutomaticSize = Roact.createElement(AutomaticSize),
			Padding = Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 35),
			}),

			Mark = Roact.createElement("TextLabel", {
				Text = "✅",
				TextSize = 24,
				Font = Enum.Font.GothamSemibold,
				AutomaticSize = Enum.AutomaticSize.XY,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromOffset(-10, 0),
				BackgroundTransparency = 1,
			}),
		}),
	})
end

function BodyRequirements:init(props)
	assert(typecheck(props))
end

function BodyRequirements:render()
	local GuiObject = GuiObjectContext:Get(self)
	local LobbyClient = GuiObject:GetService("LobbyClient")

	local props = self.props
	local requirements = props.Requirements
	local unmetRequirements = props.UnmetRequirements

	local mission = props.Mission
	if mission.RequiredExpansion then
		local name = ProductData.Expansion[mission.RequiredExpansion].Name
		requirements = Cryo.List.join(requirements, {
			{
				Type = "Expansion",
				Name = name,
			},
		})
		if not LobbyClient:IsExpansionOwned(mission.RequiredExpansion) then
			unmetRequirements = Cryo.List.join(unmetRequirements, {
				{
					Type = "Expansion",
					Name = name,
				},
			})
		end
	end

	local metRequirements = Cryo.List.filter(requirements, function(value)
		for _, item in ipairs(unmetRequirements) do
			local isEqual = true
			for k, v in pairs(item) do
				if value[k] ~= v then
					isEqual = false
					break
				end
			end
			if isEqual then
				return false
			end
		end
		return true
	end)

	local layoutOrder = 0
	local layout = function()
		layoutOrder = layoutOrder + 1
		return layoutOrder
	end

	local entries = {}
	local num = 1
	for _, entry in ipairs(metRequirements) do
		entries[num] = self:renderMetRequirement(entry, layout)
		num = num + 1
	end

	for _, entry in ipairs(unmetRequirements) do
		entries[num] = self:renderUnmetRequirement(entry, layout)
		num = num + 1
	end

	return Roact.createElement("Frame", {
		LayoutOrder = props.LayoutOrder,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
	}, {
		Layout = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
		}),

		Entries = Roact.createFragment(entries),
	})
end

return BodyRequirements
