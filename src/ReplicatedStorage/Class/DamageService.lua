local Super = require(script.Parent)
local DamageService = Super:Extend()

DamageService.HealingEffectiveness = 1

DamageService.DamageTypes = {
	"Slashing",
	"Piercing",
	"Bludgeoning",
	"Heat",
	"Cold",
	"Internal",
	"Disintegration",
	"Psychic",
	"Electrical",
}

function DamageService:DoesDamageHaveTag(damage, tag)
	if damage.Tags then
		return table.find(damage.Tags, tag) ~= nil
	end
	
	return false
end

function DamageService:IsDamagePhysical(damage)
	return not self:DoesDamageHaveTag(damage, "Magical")
end

function DamageService:Damage(damage)
	if not damage.Amount then error("Tried to call DamageService:Damage() without Amount") end
	if not damage.Target then error("Tried to call DamageService:Damage() without Target") end
	if not damage.Type then error("Tried to call DamageService:Damage() without Type") end
	if not table.find(self.DamageTypes, damage.Type) then error(string.format([[Unrecognized damage type "%s"]], damage.Type)) end
	
	local target = damage.Target
	local source = damage.Source
	
	if target.Invulnerable > 0 then return end
	
	-- big meme
	if
		(damage.Type == "Psychic") and
		target:IsA(self:GetClass("Legend")) and
		target.Player.UserId == 5905025
	then
		damage.Amount *= 1.50
	end
	-- done with big meme
	
	-- apply resistances
	local resistance = target.Resistances[damage.Type]:Get()

	local isMagical = self:DoesDamageHaveTag(damage, "Magical")
	if isMagical then
		resistance += target.Resistances.Magical:Get()
	else
		resistance += target.Resistances.Physical:Get()
	end
	
	local damageAmountBeforeResistance = damage.Amount
	
	damage.Amount *= (1 - resistance)
	
	local resistanceStatus = "None"
	if damage.Amount > damageAmountBeforeResistance then
		resistanceStatus = "Weak"
	elseif damage.Amount < damageAmountBeforeResistance then
		resistanceStatus = "Resistant"
	end
	
	-- calculate power increasing damage
	if source then
		local power = math.max(-0.8, source.Power:Get())
		damage.Amount += (damage.Amount * power)
	end
	
	-- calculate armor reducing damage
	local armor = math.clamp(target.Armor:Get(), -0.95, 0.95)
	damage.Amount -= (damage.Amount * armor)
	
	-- exit out early if the damage has been nullified
	if damage.Amount <= 0 then
		return damage
	end
	
	-- trigger on will deal damage events
	if source and source.OnWillDealDamage then
		source:OnWillDealDamage(damage)
	end
	
	-- trigger on will take damage events
	if target.OnWillTakeDamage then
		target:OnWillTakeDamage(damage)
	end
	
	-- after all is said and done, process shields
	for _, status in pairs(target.Statuses) do
		if status.IsShield then
			local reduction = math.min(status.Amount, damage.Amount)
			damage.Amount -= reduction
			status.Amount -= reduction
			
			if status.Amount <= 0 then
				status:Stop()
			end
		end
		
		if damage.Amount <= 0 then
			break
		end
	end
	
	-- actually reduce target health
	target.Health = target.Health - damage.Amount
	
	-- log the damage
	self:GetService("LogService"):AddEvent{Type = "damageDealt", Source = damage.Source, Target = damage.Target, Amount = damage.Amount}
	
	-- trigger on damaged events
	if target.OnDamaged then
		target:OnDamaged(damage)
	end
	
	-- trigger on dealt damage events
	if source and source.OnDealtDamage then
		source:OnDealtDamage(damage)
	end
	
	-- damage indicator
	self:FireRemoteAll("DamageIndicatorRequested", {
		Source = damage.Source.Root,
		Target = damage.Target.Root,
		Amount = damage.Amount,
		Type = damage.Type,
		ResistanceStatus = resistanceStatus,
	})
	
	return damage
end

function DamageService:Heal(heal)
	if self.HealingEffectiveness <= 0 then return end
	
	if heal.Source.OnWillHeal then
		heal.Source:OnWillHeal(heal)
	end
	
	local target = heal.Target
	local source = heal.Source
	
	local amount = heal.Amount
	
	amount *= (1 + source.HealingPower:Get())
	
	local missingHealth = target.MaxHealth:Get() - target.Health
	local healingDone = math.min(amount, missingHealth)
	
	heal.WastedHealing = heal.Amount - healingDone
	target.Health += healingDone
	
	if heal.Source.OnHealed then
		heal.Source:OnHealed(heal)
	end
	
	self:GetService("LogService"):AddEvent{Type = "healed", Source = heal.Source, Target = heal.Target, Amount = healingDone}
end

local Singleton = DamageService:Create()
return Singleton