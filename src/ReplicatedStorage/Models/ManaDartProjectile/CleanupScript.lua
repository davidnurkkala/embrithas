return function(projectile)
	local model = projectile.Model
	local root = model.Root
	
	projectile:Tween(root.PointLight, {Range = 0}, 1)
	projectile:Tween(root, {Transparency = 1}, 1)
	root.EmitterAttachment.Emitter.Enabled = false
	root.Trail.Enabled = false
	
	game:GetService("Debris"):AddItem(root, 5)
end