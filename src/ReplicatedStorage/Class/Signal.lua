local Super = require(script.Parent)
local Signal = Super:Extend()

function Signal:OnCreated()
	self.Connections = {}
end

function Signal:Connect(callback)
	local connection = {}
	connection.Disconnect = function(connection)
		table.remove(self.Connections, table.find(self.Connections, connection))
	end
	connection.Callback = callback
	table.insert(self.Connections, connection)
	return connection
end

function Signal:Fire(...)
	for _, connection in pairs(self.Connections) do
		connection.Callback(...)
	end
end

return Signal
