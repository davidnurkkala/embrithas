local Lighting = game:GetService("Lighting")

local Super = require(script.Parent)
local Modifier = Super:Extend()

Modifier.LightingSettings = {
	FogColor = Color3.new(0.278431, 0.129412, 0.352941),
	FogStart = 16,
	FogEnd = 64,
}

function Modifier:OnStarted()
	self.PreviousLightingSettings = {}
	for setting, value in pairs(self.LightingSettings) do
		self.PreviousLightingSettings[setting] = Lighting[setting]
		Lighting[setting] = value
	end
	
	self.Character = self:CreateNew"Character"{
		Model = workspace,
		Name = "the draining miasma",
	}
	
	local dps = self:GetClass("Legend").GetMaxHealthFromLevel(75) / (60 * 5)
	
	self.Timeline = self:CreateNew"Timeline"{
		Infinite = true,
		Interval = 1,
		
		OnTicked = function(t, dt)
			for _, legend in pairs(self:GetClass("Legend").Instances) do
				self:GetService("DamageService"):Damage{
					Source = self.Character,
					Target = legend,
					Amount = dps * dt,
					Type = "Internal",
					Unblockable = true,
				}
			end
		end
	}
	self.Timeline:Start()
	
	self:GetService("DamageService").HealingEffectiveness -= 1
end

function Modifier:OnEnded()
	self:GetService("DamageService").HealingEffectiveness += 1
	self.Timeline:Stop()
	for setting, value in pairs(self.PreviousLightingSettings) do
		Lighting[setting] = value
	end
end

return Modifier