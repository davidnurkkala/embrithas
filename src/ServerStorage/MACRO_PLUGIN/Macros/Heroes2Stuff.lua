local CHS = game:GetService("ChangeHistoryService")

local createSizer = {
	Type = "Button",
	Text = "Create Sizers",
	Activate = function()
		CHS:SetWaypoint("willCreateSizers")
		for _, model in pairs(game.Selection:Get()) do
			local content = Instance.new("Model")
			for _, child in pairs(model:GetChildren()) do
				if child.Name ~= "Extra" then
					child:Clone().Parent = content
				end
			end
			local cframe, size = content:GetBoundingBox()
			
			size = Vector3.new(
				(math.ceil(size.X / 4) + 1) * 4,
				2,
				(math.ceil(size.Z / 4) + 1) * 4
			)
			
			local extra = model:FindFirstChild("Debris")
			if not extra then
				extra = Instance.new("Model")
				extra.Name = "Debris"
				extra.Parent = model
			end
			local sizer = extra:FindFirstChild("Sizer")
			if not sizer then
				sizer = Instance.new("Part")
				sizer.Anchored = true
				sizer.CanCollide = false
				sizer.Name = "Sizer"
				sizer.TopSurface = "Smooth"
				sizer.BottomSurface = "Smooth"
				sizer.Color = Color3.new(1, 0, 1)
				sizer.Transparency = 1
				sizer.Parent = extra
			end
			sizer.Size = size
			sizer.CFrame = cframe
		end
		CHS:SetWaypoint("didCreateSizers")
	end	
}

return {
	Init = function()
		
	end,
	Items = {
		createSizer,
	}
}