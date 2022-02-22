return function(projectile)
	local model = projectile.Model
	local ball = model.Icicle
	local duration = ball.Emitter.Lifetime.Max
	
	ball.Parent = workspace.Effects
	ball.Anchored = true
	ball.Transparency = 1
	ball.CanCollide = false
	ball.Emitter.Enabled = false
	ball.Trail.Enabled = false
	game:GetService("Debris"):AddItem(ball, duration)
	
	projectile:TweenNetwork{
		Object = ball.PointLight,
		Goals = {Range = 0},
		Duration = duration,
		Style = Enum.EasingStyle.Linear,
	}
	
	model:Destroy()
end