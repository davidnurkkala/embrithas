local Super = require(script.Parent)
local FloorModifier = Super:Extend()

function FloorModifier:OnCreated()
	self:OnStarted()
end

function FloorModifier:OnStarted()
	print("Base floor modifier OnStarted called.")
end

function FloorModifier:OnEnded()
	print("Base floor modifier OnEnded called.")
end

return FloorModifier