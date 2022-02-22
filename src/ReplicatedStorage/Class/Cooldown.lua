local Super = require(script.Parent)
local Cooldown = Super:Extend()

Cooldown.Time = 1
Cooldown.TimeOverride = 0
Cooldown.Last = 0

function Cooldown:Now()
	return tick()
end

function Cooldown:GetLastTime()
	if self.LastTime then
		return self.LastTime
	else
		return self.Time
	end
end

function Cooldown:Save()
	return {
		LastTime = self.LastTime,
		TimeOverride = self.TimeOverride,
		Last = self.Last,
	}
end

function Cooldown:Load(save)
	self.LastTime = save.LastTime
	self.TimeOverride = save.TimeOverride
	self.Last = save.Last
end

function Cooldown:IsReady()
	return self:Now() - self.Last >= self.Time
end

function Cooldown:GetRemaining()
	return math.max(0, self.Last + self.Time - self:Now())
end

function Cooldown:GetRatio()
	return self:GetRemaining() / self.Time
end

function Cooldown:ReduceBy(amount)
	self.Last -= amount
end

function Cooldown:Use(override)
	if override then
		self.LastTime = override
		self.TimeOverride = override
		self.Last = self:Now() - self.Time + override
	else
		self.LastTime = self.Time
		self.TimeOverride = 0
		self.Last = self:Now()
	end
end

function Cooldown:UseMinimum(override)
	if override <= self:GetRemaining() then return end
	self:Use(override)
end

return Cooldown