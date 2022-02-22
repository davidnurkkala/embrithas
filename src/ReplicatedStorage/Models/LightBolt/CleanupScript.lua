return function(projectile)
	local model = projectile.Model
	
	local ball = model.Root
	ball.Parent = workspace.Effects
	ball.Anchored = true
	ball.Transparency = 1
	ball.CanCollide = false
	ball.EmitterAttachment.Emitter.Enabled = false
	game:GetService("Debris"):AddItem(ball, ball.EmitterAttachment.Emitter.Lifetime.Max)
	
	projectile:TweenNetwork{
		Object = ball.PointLight,
		Goals = {Range = 0},
		Duration = 1,
		Style = Enum.EasingStyle.Linear,
	}
	
	model:Destroy()
end