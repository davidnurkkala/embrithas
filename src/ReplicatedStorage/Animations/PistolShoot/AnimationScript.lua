return function(track, animator)
	local attachment = animator.Parent.Pistol.MuzzleFlashAttachment
	local emitter = attachment.Emitter
	local light = attachment.Light
	
	local connections
	connections = {
		track:GetMarkerReachedSignal("Shot"):Connect(function()
			emitter:Emit(6)
			light.Enabled = true
			delay(0.05, function()
				light.Enabled = false
			end)
			
			for _, connection in pairs(connections) do
				connection:Disconnect()
			end
		end),
	}
end