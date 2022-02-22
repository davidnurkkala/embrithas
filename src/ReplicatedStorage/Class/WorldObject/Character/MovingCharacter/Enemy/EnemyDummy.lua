local Super = require(script.Parent)
local EnemyDummy = Super:Extend()

function EnemyDummy:Ragdoll()
	self.Model:BreakJoints()
end

return EnemyDummy