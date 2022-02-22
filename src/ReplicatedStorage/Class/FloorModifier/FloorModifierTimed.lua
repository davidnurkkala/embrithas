local Super = require(script.Parent)
local Modifier = Super:Extend()

function Modifier:OnStarted()
	self.Timeline = self:CreateNew"Timeline"{
		Time = self.Time,
		Interval = 0.5,
		OnTicked = function(t, dt)
			self:FireRemoteAll("TimerUpdated", {Type = "Update", Text = self:FormatTime(math.floor(t.Time))})
		end,
		OnEnded = function(t)
			if (t.Time <= 0) and (self.Run.State == "Running") then 
				self:GetRun():Defeat()
			end
		end
	}
	self.Timeline:Start()
end

function Modifier:OnEnded()
	self.Timeline.OnEnded = function() end
	self.Timeline:Stop()
	self:FireRemoteAll("TimerUpdated", {Type = "Hide"})
end

return Modifier