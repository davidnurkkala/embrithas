return function(track, animator)
	local trailA = animator.Parent.SaberRight.Trail
	local trailB = animator.Parent.SaberLeft.Trail
	
	local connections
	connections = {
		track:GetMarkerReachedSignal("TrailStart"):Connect(function()
			trailA.Enabled = true
			trailB.Enabled = true
		end),
		track:GetMarkerReachedSignal("TrailStop"):Connect(function()
			trailA.Enabled = false
			trailB.Enabled = false
			
			for _, connection in pairs(connections) do
				connection:Disconnect()
			end
		end),
	}
end