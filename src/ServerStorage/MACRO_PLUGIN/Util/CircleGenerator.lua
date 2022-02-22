local module = {}

function module:Generate(radius, width, height, sides)
	local model = Instance.new("Model")
	model.Name = "Ring"
	
	local part_len =  math.tan(math.pi / sides) * radius * 2
	
	for i = 1,sides do
		local part = Instance.new("Part")
		part.Anchored = true
		part.FormFactor = "Custom"
		part.Size = Vector3.new(width,height,part_len)
		part.CFrame = CFrame.Angles(0,math.pi*2/sides*i,0) * CFrame.new(radius - width/2, width*2,0)
		part.Parent = model
	end	

	model.Parent = workspace
	return model
end

return module
