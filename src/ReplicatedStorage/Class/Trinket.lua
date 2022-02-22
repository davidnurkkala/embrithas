local Super = require(script.Parent)
local Trinket = Super:Extend()

function Trinket:OnCreated()
	assert(self.Data)
	
	if self.Data.Args then
		for key, val in pairs(self.Data.Args) do
			self[key] = val
		end
	end
	self.Upgrades = self.Data.Upgrades or 0
end

function Trinket:GetDescription()
	return self.Data.Description
end

function Trinket:Equip()
	-- do nothing
end

function Trinket:Unequip()
	-- also do nothing
end

return Trinket