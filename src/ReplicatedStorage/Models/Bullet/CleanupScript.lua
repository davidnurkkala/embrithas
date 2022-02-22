return function(projectile)
	local model = projectile.Model
	
	local bullet = model.Root
	bullet.Trail.Enabled = false
	bullet.Parent = workspace.Effects
	projectile:Tween(bullet, {Transparency = 1}, 1, Enum.EasingStyle.Linear)
	game:GetService("Debris"):AddItem(bullet, 1)
	
	model:Destroy()
end