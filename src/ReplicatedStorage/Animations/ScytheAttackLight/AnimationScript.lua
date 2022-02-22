return function(track, animator)
	local trail = animator.Parent.Scythe.Trail
	
	local connections
	connections = {
		track:GetMarkerReachedSignal("TrailStart"):Connect(function()
			trail.Enabled = true
		end),
		track:GetMarkerReachedSignal("TrailStop"):Connect(function()
			trail.Enabled = false
			
			for _, connection in pairs(connections) do
				connection:Disconnect()
			end
		end),
	}
end