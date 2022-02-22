local Super = require(script.Parent)
local PlayerCharacter = Super:Extend()

function PlayerCharacter:OnCreated()
	Super.OnCreated(self)
	
	assert(self.Player)
	
	self:SetCollisionGroup("Player")
end

return PlayerCharacter
