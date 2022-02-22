local Super = require(script.Parent)
local StateMachine = Super:Extend()

function StateMachine:OnCreated()
	self.States = {}
	self.StateCount = 0
end

function StateMachine:AddState(state)
	self.States[state.Name] = state
	
	if self.StateCount == 0 then
		self.State = state
	end
	self.StateCount = self.StateCount + 1
end

function StateMachine:Run(dt)
	self.State:Run(self, dt)
end

function StateMachine:ChangeState(stateName, stateArgs, force)
	local state = self.States[stateName]
	if (not force) and (self.State == state) then return end
	
	if self.State.OnStateWillChange then
		self.State:OnStateWillChange(self, stateName)
	end
	
	if stateArgs then
		for k, v in pairs(stateArgs) do
			state[k] = v
		end
	end
	
	self.State = state
	
	if self.State.OnStateChanged then
		self.State:OnStateChanged(self)
	end
end

return StateMachine