local Super = require(script.Parent)
local AbilityTaunt = Super:Extend()

AbilityTaunt.Type = "Utility"

function AbilityTaunt:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = self:GetDuration() + 5
end

function AbilityTaunt:GetDuration()
	local a = Vector2.new(1, 5)
	local b = Vector2.new(100, 20)
	local slope = (b.Y - a.Y) / (b.X - a.X)
	local intercept = a.Y - (slope * a.X)
	return self:GetLevel() * slope + intercept
end

function AbilityTaunt:GetDescription()
	return string.format(
		"Force all nearby enemies to target you for the next %4.2f seconds. If an affected enemy can't see you or is too far away, the effect ends early.",
		self:GetDuration()
	)
end

function AbilityTaunt:OnActivatedServer()
	self.Legend:AnimationPlay("WarCry", 0, nil, 4)
	
	local range = 64
	local maxDistanceSq = 96 ^ 2
	local position = self.Legend:GetPosition()
	
	self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
		Position = position,
		Radius = range,
		Duration = 0.5,
		Style = Enum.EasingStyle.Quint,
		Color = Color3.new(1, 0, 0),
	})
	
	local duration = self:GetDuration()
	local legend = self.Legend
	for _, enemy in pairs(self:GetService("TargetingService"):GetEnemies()) do
		if enemy:IsPointInRange(position, range) then
			repeat
				local status = enemy:GetStatusByType("Taunted")
				if status then
					status:Stop()
				end
			until not status
			
			enemy:AddStatus("Status", {
				Type = "Taunted",
				Time = duration,
				OnStarted = function(status)
					local a0 = Instance.new("Attachment", status.Character.Root)
					local a1 = Instance.new("Attachment", legend.Root)
					local beam = self.Storage.Models.SparseArrowBeam:Clone()
					beam.Color = ColorSequence.new(Color3.new(1, 0, 0))
					beam.Attachment0 = a0
					beam.Attachment1 = a1
					beam.Parent = workspace.Effects
					status.Effects = {a0, a1, beam}
				end,
				OnTicked = function(status)
					if not (legend and legend.Active) then return end
					if not status.Character:CanSeePoint(legend:GetPosition()) then
						return status:Stop()
					end
					if status.Character:DistanceToSquared(legend:GetPosition()) > maxDistanceSq then
						return status:Stop()
					end
					
					status.Character.Target = legend
				end,
				OnEnded = function(status)
					for _, effect in pairs(status.Effects) do
						effect:Destroy()
					end
				end
			})
		end
	end
	
	return true
end

return AbilityTaunt