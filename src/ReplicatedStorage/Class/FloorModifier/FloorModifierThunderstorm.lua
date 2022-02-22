local Super = require(script.Parent)
local Modifier = Super:Extend()

function Modifier:OnStarted()
	self.EffectIds = {}
	
	local function onPlayerAdded(player)
		self:OnPlayerAdded(player)
	end
	self:AddConnection(game:GetService("Players").PlayerAdded:Connect(onPlayerAdded))
	for _, player in pairs(game:GetService("Players"):GetPlayers()) do
		onPlayerAdded(player)
	end
end

function Modifier:OnPlayerAdded(player)
	table.insert(self.EffectIds, self:GetService("EffectsService"):RequestEffect(player, "Thunderstorm", {}))
end

function Modifier:OnEnded()
	for _, effectId in pairs(self.EffectIds) do
		self:GetService("EffectsService"):CancelEffect(effectId)
	end
	self:CleanConnections()
end

return Modifier