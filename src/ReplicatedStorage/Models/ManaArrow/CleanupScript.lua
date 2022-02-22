return function(projectile)
	local model = projectile.Model
	local part = projectile.LastPartHit
	
	if not part then
		model:Destroy()
		return
	end
	
	local arrow = model.Root
	arrow.Anchored = false
	arrow.Trail.Enabled = false
	arrow.Parent = workspace.Effects
	local w = Instance.new("WeldConstraint")
	w.Part0 = part
	w.Part1 = arrow
	w.Parent = arrow
	projectile:Tween(arrow, {Transparency = 1}, 1, Enum.EasingStyle.Linear)
	game:GetService("Debris"):AddItem(arrow, 1)
	
	model:Destroy()
end