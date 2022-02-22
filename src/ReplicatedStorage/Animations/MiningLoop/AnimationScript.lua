return function(track, animator)
	local pickaxe = animator.Parent:FindFirstChild("Pickaxe") or animator.Parent:FindFirstChild("Maul")
	local sound = pickaxe:FindFirstChild("Sound")
	
	if not sound then return end
	
	local connections
	connections = {
		track:GetMarkerReachedSignal("Hit"):Connect(function()
			sound:Play()
		end),
		track.Stopped:Connect(function()
			for _, connection in pairs(connections) do
				connection:Disconnect()
			end
		end),
	}
end