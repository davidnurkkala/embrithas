local Super = require(script.Parent)
local Event = Super:Extend()

function Event:OnCreated()
	self.BindableEvent = Instance.new("BindableEvent")
end

function Event:Connect(callback)
	return self.BindableEvent.Event:Connect(callback)
end

function Event:Fire(...)
	self.BindableEvent:Fire(...)
end

function Event:Wait(...)
	return self.BindableEvent.Event:Wait(...)
end

function Event:WaitFor(valueToWaitFor)
	local event = Instance.new("BindableEvent")
	local conn = self:Connect(function(value)
		event:Fire(value)
	end)
	repeat
		local value = event.Event:Wait()
	until value == valueToWaitFor
	return valueToWaitFor
end

return Event
