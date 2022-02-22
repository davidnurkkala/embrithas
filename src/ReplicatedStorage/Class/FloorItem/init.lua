local Super = require(script.Parent)
local FloorItem = Super:Extend()

function FloorItem:CreateHitSphere(radius)
	local sphere = Instance.new("Part")
	sphere.TopSurface = Enum.SurfaceType.Smooth
	sphere.BottomSurface = Enum.SurfaceType.Smooth
	sphere.Anchored = true
	sphere.CanCollide = false
	sphere.Color = Color3.new(1, 1, 1)
	sphere.Transparency = 1
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Vector3.new(2, 2, 2) * radius
	
	game:GetService("CollectionService"):AddTag(sphere, "InvisibleWall")
	
	return sphere
end

return FloorItem