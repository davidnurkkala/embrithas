local Super = require(script.Parent)
local AbilityWarCry = Super:Extend()

AbilityWarCry.Type = "Utility"

function AbilityWarCry:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 8
end

function AbilityWarCry:PushEnemies(position, range)
	for _, enemy in pairs(self:GetService("TargetingService"):GetEnemies()) do
		if (not enemy.Resilient) and enemy:IsPointInRange(position, range) then
			enemy:AddStatus("StatusStunned", {
				Time = 1,
			})
			
			local delta = (enemy:GetPosition() - position) * Vector3.new(1, 0, 1)
			local _, point = enemy:Raycast(Ray.new(enemy:GetPosition(), delta.Unit * (range - delta.Magnitude)))
			delta = point - enemy.Root.CFrame.Position
			
			self:TweenNetwork{
				Object = enemy.Root,
				Goals = {CFrame = enemy.Root.CFrame + delta},
				Duration = 0.5,
			}
		end
	end
end

function AbilityWarCry:GetRange()
	return 16 + self:GetStatValue("Strength") / 15
end

function AbilityWarCry:GetDescription(level)
	return string.format(
		"Bellow out an intimidating war cry, pushing enemies up to %d feet away from you and cancelling their attacks. Does not affect resilient targets like bosses.",
		self:GetRange()
	)
end

function AbilityWarCry:OnActivatedServer()
	self.Legend:AnimationPlay("WarCry", 0, nil, 4)
	
	local range = self:GetRange()
	local position = self.Legend:GetPosition()
	
	self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
		Position = position,
		Radius = range,
		Duration = 0.5,
		Style = Enum.EasingStyle.Quint,
	})
	self:PushEnemies(position, range)
	
	return true
end

return AbilityWarCry