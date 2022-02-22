local Super = require(script.Parent)
local World = Super:Extend()

function World:OnCreated()
	self.Objects = {}
	
	local function onHeartbeat(dt)
		self:OnUpdated(dt)
	end
	local heartbeat = game:GetService("RunService").Heartbeat
	heartbeat:Connect(onHeartbeat)
end

function World:AddObject(object)
	table.insert(self.Objects, object)
end

function World:OnUpdated(dt)
	for index = #self.Objects, 1, -1 do
		local object = self.Objects[index]
		if object then
			if object.Active then
				object:OnUpdated(dt)
			end
			
			if (not object.Active) or (object.Deactivating) then
				object.Active = false
				table.remove(self.Objects, index)
				
				object:OnDestroyed()
				object.Destroyed:Fire()
			end
		end
	end
end

function World:Clear()
	for _, object in pairs(self.Objects) do
		object.Active = false
	end
end

local Singleton = World:Create()
return Singleton
