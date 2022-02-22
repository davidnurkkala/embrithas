local Model = script.Parent
local Humanoid = Model:WaitForChild("Humanoid")

local IdleTrack = Humanoid:LoadAnimation(script:WaitForChild("Idle"))
IdleTrack:Play()

local WalkTrack = Humanoid:LoadAnimation(script:WaitForChild("Walk"))
local RunTrack = Humanoid:LoadAnimation(script:WaitForChild("Run"))
local CurrentSpeed = 0

local SpeedValue = script:WaitForChild("Speed")
SpeedValue.Changed:Connect(function()
	WalkTrack:AdjustSpeed(SpeedValue.Value)
	RunTrack:AdjustSpeed(SpeedValue.Value)
end)

local function onRunning(speed)
	CurrentSpeed = speed
	
	if speed == 0 then
		if WalkTrack.IsPlaying then
			WalkTrack:Stop()
		end
		if RunTrack.IsPlaying then
			RunTrack:Stop()
		end
	
	elseif speed <= 16 then
		if not WalkTrack.IsPlaying then
			WalkTrack:Play()
		end
		if not RunTrack.IsPlaying then
			RunTrack:Play()
		end
		local weight = speed / 16
		WalkTrack:AdjustWeight(weight)
		RunTrack:AdjustWeight(0)
		
	elseif speed > 16 then
		if not WalkTrack.IsPlaying then
			WalkTrack:Play()
		end
		if not RunTrack.IsPlaying then
			RunTrack:Play()
		end
		local weight = (speed - 16) / 16
		RunTrack:AdjustWeight(weight)
		WalkTrack:AdjustWeight(1 - weight)
	end
end
Humanoid.Running:Connect(onRunning)

Humanoid.StateChanged:Connect(function(oldState)
	if oldState == Enum.HumanoidStateType.Running then
		onRunning(0)
	end
end)

local function reloadAnimations()
	WalkTrack:Stop()
	RunTrack:Stop()
	
	WalkTrack = Humanoid:LoadAnimation(script.Walk)
	RunTrack = Humanoid:LoadAnimation(script.Run)
	
	onRunning(CurrentSpeed)
end
script.Walk.Changed:Connect(reloadAnimations)
script.Run.Changed:Connect(reloadAnimations)
