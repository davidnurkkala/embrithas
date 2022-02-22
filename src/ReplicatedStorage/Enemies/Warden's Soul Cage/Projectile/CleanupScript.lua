return function(projectile)
	local model = projectile.Model
	local ball = model.Root
	local duration = ball.EmitterAttachment.Emitter.Lifetime.Max
	
	ball.Parent = workspace.Effects
	ball.Anchored = true
	ball.Transparency = 1
	ball.CanCollide = false
	ball.EmitterAttachment.Emitter.Enabled = false
	game:GetService("Debris"):AddItem(ball, duration)
	
	projectile:TweenNetwork{
		Object = ball.Light,
		Goals = {Range = 0},
		Duration = duration,
		Style = Enum.EasingStyle.Linear,
	}
	
	model:Destroy()
end