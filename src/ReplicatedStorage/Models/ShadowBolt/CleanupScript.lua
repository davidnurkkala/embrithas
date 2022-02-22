return function(projectile)
	local model = projectile.Model
	
	local ball = model.Root
	ball.Parent = workspace.Effects
	ball.Anchored = true
	ball.Transparency = 1
	ball.CanCollide = false
	ball.EmitterAttachment.Emitter.Enabled = false
	game:GetService("Debris"):AddItem(ball, ball.EmitterAttachment.Emitter.Lifetime.Max)
	
	model:Destroy()
end