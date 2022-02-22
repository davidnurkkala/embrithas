local Super = require(script.Parent)
local EnemyDefender = Super:Extend()

EnemyDefender.DefenseRange = 24
EnemyDefender.DefenseCount = 3

function EnemyDefender:OnCreated()
	self.Defended = {}
	self.DefenseRangeSq = self.DefenseRange ^ 2
	
	Super.OnCreated(self)
	
	self:SetUpDefenderGui()
end

function EnemyDefender:SetUpDefenderGui()
	local defenderGui = self.Storage.UI.DefenderGui:Clone()
	defenderGui.Adornee = self.Root
	defenderGui.Parent = self.Model
	
	self.DefenderGui = defenderGui
end

function EnemyDefender:Undefend(defense)
	local character = defense.Character
	character.Untargetable = character.Untargetable - 1
	
	defense.Beam:Destroy()
	defense.Attachment0:Destroy()
	defense.Attachment1:Destroy()
end

function EnemyDefender:IsDefending(character)
	for _, defense in pairs(self.Defended) do
		if defense.Character == character then
			return true
		end
	end
	return false
end

function EnemyDefender:Defend(character)
	if character.Undefendable then return end
	if #self.Defended >= self.DefenseCount then return end
	
	character.Untargetable = character.Untargetable + 1
	
	local defense = {}
	defense.Character = character
	
	local beam = self.Storage.Models.DefenderBeam:Clone()
	local attachment0 = Instance.new("Attachment", character.Root)
	local attachment1 = Instance.new("Attachment", self.Root)
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Parent = self.Model
	
	defense.Beam = beam
	defense.Attachment0 = attachment0
	defense.Attachment1 = attachment1
	
	table.insert(self.Defended, defense)
end

function EnemyDefender:OnDestroyed()
	Super.OnDestroyed(self)
	
	self.DefenderGui:Destroy()
	
	for _, defense in pairs(self.Defended) do
		self:Undefend(defense)
	end
	self.Defended = {}
end

function EnemyDefender:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	for index = #self.Defended, 1, -1 do
		local defense = self.Defended[index]
		local character = defense.Character 
		if
			(not character.Active) or
			(self:DistanceToSquared(character:GetPosition()) > self.DefenseRangeSq)
		then
			self:Undefend(defense)
			table.remove(self.Defended, index)
		end
	end
	
	if self.Active then
		for _, enemy in pairs(self:GetClass("Enemy").Instances) do
			if not enemy:IsA(EnemyDefender) then
				local distanceSq = self:DistanceToSquared(enemy:GetPosition())
				if distanceSq <= self.DefenseRangeSq then
					if not self:IsDefending(enemy) then
						self:Defend(enemy)
					end
				end
			end
		end
	end
end

return EnemyDefender