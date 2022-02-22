local Super = require(script.Parent)
local AttackPattern = Super:Extend()

function AttackPattern:OnCreated()
	-- format the pattern
	local pattern = {}
	local index = 1
	while index <= #self.Pattern do
		local name = self.Pattern[index]
		local count = 1
		if (typeof(self.Pattern[index + 1]) == "number") then
			count = self.Pattern[index + 1]
			index = index + 1
		end
		index = index + 1
		table.insert(pattern, {name, count})
	end
	self.Pattern = pattern
	
	-- initialize
	self.Index = 1
	self.Repetitions = 0
end

function AttackPattern:Randomize()
	self.Index = math.random(1, #self.Pattern)
end

function AttackPattern:Reset()
	self.Index = 1
	self.Repetitions = 0
end

function AttackPattern:Get()
	return self.Pattern[self.Index][1]
end

function AttackPattern:Next()
	self.Repetitions = self.Repetitions + 1
	if self.Repetitions >= self.Pattern[self.Index][2] then
		self.Index = self.Index + 1
		self.Repetitions = 0
		if self.Index > #self.Pattern then
			self.Index = 1
		end
	end
end

return AttackPattern