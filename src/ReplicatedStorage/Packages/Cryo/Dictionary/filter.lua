--[[
	Create a copy of a list with only values for which `callback` returns true.
	Calls the callback with (value, index).
]]
local function filter(list, callback)
	local new = {}

	for key, value in pairs(list) do
		if callback(value, key) then
			new[key] = value
		end
	end

	return new
end

return filter