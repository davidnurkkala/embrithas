local Super = require(script.Parent)
local Stat = Super:Extend()

Stat.Base = 100
Stat.Bonus = 0
Stat.Percent = 0
Stat.Flat = 0

function Stat:Get()
	return (self.Base + self:GetBonus()) * (1 + self:GetPercent()) + self:GetFlat()
end

function Stat:ModBonus(amount)
	self.Bonus = self.Bonus + amount
end

function Stat:ModPercent(amount)
	self.Percent = self.Percent + amount
end

function Stat:ModFlat(amount)
	self.Flat = self.Flat + amount
end

function Stat:GetBonus()
	local total = self.Bonus
	if self.NamedBonuses then
		for _, bonus in pairs(self.NamedBonuses) do
			total += bonus
		end
	end
	return total
end

function Stat:GetPercent()
	local total = self.Percent
	if self.NamedPercents then
		for _, percent in pairs(self.NamedPercents) do
			total += percent
		end
	end
	return total
end

function Stat:GetFlat()
	local total = self.Flat
	if self.NamedFlats then
		for _, flat in pairs(self.NamedFlats) do
			total += flat
		end
	end
	return total
end

function Stat:SetNamedBonus(name, amount)
	if not self.NamedBonuses then
		self.NamedBonuses = {}
	end
	self.NamedBonuses[name] = amount
end

function Stat:GetNamedBonus(name)
	if self.NamedBonuses then
		return self.NamedBonuses[name]
	else
		return nil
	end
end

function Stat:SetNamedPercent(name, amount)
	if not self.NamedPercents then
		self.NamedPercents = {}
	end
	self.NamedPercents[name] = amount
end

function Stat:GetNamedPercent(name)
	if self.NamedPercents then
		return self.NamedPercents[name]
	else
		return nil
	end
end

function Stat:SetNamedFlat(name, amount)
	if not self.NamedFlats then
		self.NamedFlats = {}
	end
	self.NamedFlats[name] = amount
end

function Stat:GetNamedFlat(name)
	if self.NamedFlats then
		return self.NamedFlats[name]
	else
		return nil
	end
end

return Stat
