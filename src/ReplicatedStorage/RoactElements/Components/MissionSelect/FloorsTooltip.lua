--[[
	Shows a mission's floors in detail as a tooltip.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local BaseTooltip = require(main.Components.Base.BaseTooltip)
local DefaultHeader = require(main.Components.Tooltip.DefaultHeader)
local BodyBulletPoints = require(main.Components.Tooltip.BodyBulletPoints)

local RecommendedTooltip = Roact.PureComponent:extend("RecommendedTooltip")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Mission = t.interface({
		Level = t.integer,
	}),
})

function RecommendedTooltip:init(props)
	assert(typecheck(props))
end

function RecommendedTooltip:render()
	local props = self.props
	local mission = props.Mission
	local floors = mission.Floors

	local floorText = {}
	for i, floor in ipairs(floors) do
		local name

		if floor.Type == "Granular" then
			local size = floor.Args.SizeInChunks
			if size then
				local area = size.X * size.Y
				local sizeType = "Small"
				if area > 4 then
					sizeType = "Medium"
				elseif area > 9 then
					sizeType = "Large"
				elseif area > 16 then
					sizeType = "Huge"
				elseif area > 25 then
					sizeType = "Gargantuan"
				end
				name = floor.Name.." ("..sizeType.." "..floor.Args.Theme..")"
			else
				name = floor.Name.." ("..floor.Args.Theme..")"
			end
		else
			name = floor.Name
		end

		floorText[i] = name
	end

	return Roact.createElement(BaseTooltip, {
		RenderHeader = function()
			return Roact.createElement(DefaultHeader, {
				Title = "Mission Floors",
			})
		end,

		RenderBody = function(layout)
			return Roact.createFragment({
				Floors = Roact.createElement(BodyBulletPoints, {
					LayoutOrder = layout(),
					Entries = floorText,
				}),
			})
		end,
	})
end

return RecommendedTooltip
