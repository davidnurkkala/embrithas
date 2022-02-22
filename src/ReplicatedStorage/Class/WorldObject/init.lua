local Super = require(script.Parent)
local WorldObject = Super:Extend()

WorldObject.Active = true

function WorldObject:OnCreated()
	self.Destroyed = self:CreateNew"Event"()
end

function WorldObject:Deactivate()
	self.Deactivating = true
end

function WorldObject:OnUpdated(dt)
	--do nothing
end

function WorldObject:OnDestroyed()
	--do nothing
end

return WorldObject
