local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function savePlayer(player)
	local char = player.Character
	if not char then return end
	
	local root = char.PrimaryPart
	if not root then return end
	
	if root.Position.Y < -150 then
		root.CFrame += Vector3.new(0, 150, 0)
		
		for _, desc in pairs(char:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Velocity = Vector3.new(0, 0, 0)
			end
		end
	end
end

local function onUpdated()
	for _, player in pairs(Players:GetPlayers()) do
		savePlayer(player)
	end
end

RunService.Heartbeat:Connect(onUpdated)