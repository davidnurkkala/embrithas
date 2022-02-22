local Super = require(script.Parent)
local AbilityHoldFast = Super:Extend()

AbilityHoldFast.Type = "Utility"

function AbilityHoldFast:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 6
end

function AbilityHoldFast:GetDuration()
	local bonus = (self:GetStatValue("Constitution") ^ 0.7) / 50
	return 0.5 + bonus
end

function AbilityHoldFast:GetDescription()
	return string.format(
		"Brace yourself, reducing incoming damage by 90%% for %4.2f seconds.",
		self:GetDuration()
	)
end

function AbilityHoldFast:OnActivatedServer()
	local duration = self:GetDuration(self.Legend.Level)
	
	local speed = self.Legend.Speed
	local armor = self.Legend.Armor
	
	local dSpeed = -0.75
	local dArmor = 0.9
	
	self.Legend:AddStatus("Status", {
		Time = duration,
		OnStarted = function()
			speed.Percent += dSpeed
			armor.Base += dArmor
		end,
		OnEnded = function()
			speed.Percent -= dSpeed
			armor.Base -= dArmor
		end,
	})
	
	self.Legend:AnimationPlay("HoldFast", 0, nil, 1 / duration)
	self:GetService("EffectsService"):RequestEffectAll("Shockwave", {
		CFrame = CFrame.new(self.Legend:GetFootPosition()),
		StartSize = Vector3.new(16, 0, 16),
		EndSize = Vector3.new(0, 16, 0),
		Duration = 0.1,
		PartArgs = {
			Color = Color3.new(1, 1, 1),
		}
	})
	self.Legend:SoundPlayByObject(self.Storage.Sounds.AdrenalineRush)
	
	return true
end

return AbilityHoldFast