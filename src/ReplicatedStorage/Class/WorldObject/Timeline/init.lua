local Super = require(script.Parent)
local Timeline = Super:Extend()

Timeline.Interval = 0
Timeline.DeltaTime = 0
Timeline.Infinite = false
Timeline.TotalTime = 0

function Timeline:OnCreated()
	Super.OnCreated(self)
	
	self.MaxTime = self.Time
	self:OnStarted()
end

function Timeline:OnUpdated(dt)
	self.TotalTime += dt
	self.DeltaTime = self.DeltaTime + dt
	
	if self.DeltaTime > self.Interval then
		self:OnTicked(self.DeltaTime, self.TotalTime)
		
		if not self.Infinite then
			self.Time = self.Time - self.DeltaTime
			if self.Time <= 0 then
				self.Active = false
			end
		end
		
		self.DeltaTime = 0
	end
end

function Timeline:GetProgress()
	if self.Infinite then
		return 1
	end
	
	return 1 - (self.Time / self.MaxTime)
end

function Timeline:MultiplyTime(factor)
	self.Time *= factor
	self.MaxTime *= factor
end

function Timeline:Start()
	self:GetWorld():AddObject(self)
end

function Timeline:Restart(newMaxTime)
	self.MaxTime = newMaxTime or self.MaxTime
	self.Time = self.MaxTime
end

function Timeline:Stop()
	self.Time = 0
	self.Active = false
end

function Timeline:OnDestroyed()
	self:OnEnded()
end

function Timeline:OnStarted()
	--do nothing
end

function Timeline:OnTicked(dt)
	--do nothing
end

function Timeline:OnEnded()
	--do nothing
end

return Timeline
