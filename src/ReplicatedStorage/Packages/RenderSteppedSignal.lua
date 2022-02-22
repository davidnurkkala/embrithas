local RunService = game:GetService("RunService")
local Signal = require(game.ReplicatedStorage.Packages.Signal)

local RenderSteppedSignal = Signal.new()

RunService.RenderStepped:Connect(function(dt)
	RenderSteppedSignal:Fire(math.min(0.1, dt))
end)

return RenderSteppedSignal
