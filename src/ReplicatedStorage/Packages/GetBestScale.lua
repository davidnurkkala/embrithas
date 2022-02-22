-- Returns the best scale

local function GetBestScale()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local height = viewportSize.Y
	local width = viewportSize.X
	local heightScale = height / 1080
	local widthScale = width / 1920
	local bestScale
	if widthScale > heightScale then
		bestScale = heightScale
	else
		bestScale = widthScale
	end
	return math.min(bestScale, 1)
end

return GetBestScale
