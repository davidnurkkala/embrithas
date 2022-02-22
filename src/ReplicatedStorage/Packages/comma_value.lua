local function comma_value(amount, shorthand)
	local formatted = amount
	local suffix = ""
	if shorthand then
		if amount > 1000000 then
			formatted = amount / 1000000
			formatted = math.floor(formatted * 100) / 100
			suffix = "M"
		elseif amount >= 1000 then
			formatted = amount / 1000
			formatted = math.floor(formatted * 100) / 100
			suffix = "k"
		end
	end
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	return formatted .. suffix
end

return comma_value
