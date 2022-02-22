local Players = game:GetService("Players")

local Super = require(script.Parent)
local BossStatusGui = Super:Extend()

function BossStatusGui:OnCreated()
	Super.OnCreated(self)
	
	local function onPlayerAdded(player)
		self:FireRemoteAll("BossStatusGuiUpdated", {Type = "Show"})
	end
	
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	self:AddConnection(Players.PlayerAdded:Connect(onPlayerAdded))
	
	self:OnUpdated()
	self:GetWorld():AddObject(self)
end

function BossStatusGui:Destroy()
	self.Active = false
end

function BossStatusGui:OnUpdated()
	self:FireRemoteAll("BossStatusGuiUpdated", {
		Type = "Update", 
		Name = self.Enemy.Name,
		Ratio = self.Enemy.Health / self.Enemy.MaxHealth:Get(),
	})
end

function BossStatusGui:OnDestroyed()
	self:FireRemoteAll("BossStatusGuiUpdated", {Type = "Hide"})
	self:CleanConnections()
end

return BossStatusGui