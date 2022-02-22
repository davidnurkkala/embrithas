return function(projectile)
	local model = projectile.Model
	model.Root:Destroy()
	local ball = model.Effect
	local duration = ball.EmitterAttachment.Emitter.Lifetime.Max
	
	ball.Parent = workspace.Effects
	ball.Anchored = true
	ball.Transparency = 1
	ball.CanCollide = false
	ball.EmitterAttachment.Emitter.Enabled = false
	game:GetService("Debris"):AddItem(ball, duration)
	
	projectile:TweenNetwork{
		Object = ball.PointLight,
		Goals = {Range = 0},
		Duration = duration,
		Style = Enum.EasingStyle.Linear,
	}
	
	model:Destroy()
end