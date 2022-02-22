local Super = require(script.Parent)
local NoClimbingClient = Super:Extend()

function NoClimbingClient:OnCreated()
	self.Player = game:GetService("Players").LocalPlayer
	
	self:GetWorld():AddObject(self)
end

function NoClimbingClient:OnUpdated()
	local character = self.Player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		end
	end
end

local Singleton = NoClimbingClient:Create()
return Singleton