local Super = require(script.Parent)
local AbilityDistantBlessing = Super:Extend()

AbilityDistantBlessing.Type = "Utility"

AbilityDistantBlessing.ManaCost = 70
AbilityDistantBlessing.UsesMana = true

function AbilityDistantBlessing:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 5
end

function AbilityDistantBlessing:GetRange()
	return self:Lerp(32, 64, self:GetUpgrades() / 10)
end

function AbilityDistantBlessing:GetDescription(level, itemData)
	return string.format(
		"Call upon the Distant Goddess to heal yourself and allies with %4.1f range for %d health. Costs %d mana.",
		self:GetRange(),
		self:GetHealing(),
		self.ManaCost
	)
end

function AbilityDistantBlessing:GetHealing()
	return self:GetPowerHelper("Compassion") * 0.5
end

function AbilityDistantBlessing:OnActivatedServer()
	if not self.Legend:CanUseMana(self.ManaCost) then return false end
	self.Legend:UseMana(self.ManaCost)
	
	local range = self:GetRange(self.Data)
	local rangeSq = range ^ 2
	local position = self.Legend:GetFootPosition()
	
	local allies = self:GetService("TargetingService"):GetMortals()
	for _, ally in pairs(allies) do
		local delta = (ally:GetPosition() - position)
		local distanceSq = delta.X ^ 2 + delta.Z ^ 2
		if distanceSq <= rangeSq then
			self:GetService("DamageService"):Heal{
				Source = self.Legend,
				Target = ally,
				Amount = self:GetHealing()
			}
		end
	end
	
	self.Legend:AnimationPlay("Pray", nil, nil, 4)
	self.Legend:SoundPlayByObject(self.Storage.Sounds.HealingBurst2)
	
	local duration = 1
	local partArgs = {
		Material = Enum.Material.Neon,
		BrickColor = BrickColor.new("Gold"),
		Transparency = 0.75,
	}
	
	local effectsService = self:GetService("EffectsService")
	effectsService:RequestEffectAll("GodRay", {
		PartArgs = partArgs,
		Position = position,
		Radius = range / 2,
		Duration = duration,
	})
	effectsService:RequestEffectAll("Shockwave", {
		PartArgs = partArgs,
		CFrame = CFrame.new(position),
		EndSize = Vector3.new(range * 2, 4, range * 2),
		Duration = duration,
	})
	
	return true
end

return AbilityDistantBlessing