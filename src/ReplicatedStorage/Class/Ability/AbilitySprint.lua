local Super = require(script.Parent)
local AbilitySprint = Super:Extend()

AbilitySprint.Type = "Movement"

function AbilitySprint:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = self:GetDuration(self.Legend.Level) + 12
end

function AbilitySprint:GetDuration()
	return 2 + self:GetLevel() * 0.2
end

function AbilitySprint:OnActivatedServer()
	local delta = 0.5
	
	self.Legend:AddStatus("Status", {
		Time = self:GetDuration(self.Legend.Level),
		Type = "Sprinting",
		
		Category = "Good",
		ImagePlaceholder = "SPRNT",
		
		OnStarted = function(s)
			self.Legend.Speed.Percent += delta
			
			local trail = self.Legend.SprintTrail:Clone()
			trail.Color = ColorSequence.new(Color3.fromRGB(61, 113, 165))
			trail.Enabled = true
			trail.Parent = self.Legend.Root
			s.Trail = trail
		end,
		OnEnded = function(s)
			self.Legend.Speed.Percent -= delta
			
			local trail = s.Trail
			trail.Enabled = false
			game:GetService("Debris"):AddItem(trail, 5)
		end,
	})
	
	return true
end

function AbilitySprint:GetDescription()
	return string.format(
		"Sprint for %4.1f seconds, dramatically increasing your movement speed.",
		self:GetDuration()
	)
end

return AbilitySprint