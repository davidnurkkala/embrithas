--[[
	Create a copy of a list where each value is transformed by `callback`
]]
local function map(list, callback)
	local new = {}
	
	for key, value in pairs(list) do
		new[key] = callback(value, key)
	end

	return new
end

return map