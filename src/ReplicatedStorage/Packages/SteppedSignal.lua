local RunService = game:GetService("RunService")
local Signal = require(game.ReplicatedStorage.Packages.Signal)

local SteppedSignal = Signal.new()

RunService.Stepped:Connect(function(_, dt)
	SteppedSignal:Fire(math.min(0.1, dt))
end)

return SteppedSignal
