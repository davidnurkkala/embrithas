local speed = 64

local model = script.Parent
local riserParts = model.Risers:GetChildren()

local risers = {}
for _, riserPart in pairs(riserParts) do
	local height = riserPart.Size.Y
	local startHeight = riserPart.Position.Y
	local a = riserPart
	local b = riserPart:Clone()
	b.Position -= Vector3.new(0, height, 0)
	b.Parent = riserPart.Parent
	
	table.insert(risers, {
		Height = height,
		StartHeight = startHeight,
		PartA = a,
		PartB = b,
	})
end

local function updateRiser(riser, dt)
	for _, part in pairs{riser.PartA, riser.PartB} do
		part.Position += Vector3.new(0, speed * dt, 0)
		if part.Position.Y > riser.StartHeight + riser.Height then
			part.Position -= Vector3.new(0, riser.Height * 2, 0)
		end
	end
end

local progress = model:WaitForChild("Progress")

local gui = script.CustomProgressFrame:Clone()

local function updateGui()
	gui.Bar.Size = UDim2.new(progress.Value, 0, 1, 0)
end
updateGui()

gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Gui")

local connection
local function update(dt)
	if not model.Parent then
		gui:Destroy()
		return connection:Disconnect()
	end
	updateGui()
	for _, riser in pairs(risers) do
		updateRiser(riser, dt)
	end
end
connection = game:GetService("RunService").Heartbeat:Connect(update)

return {}