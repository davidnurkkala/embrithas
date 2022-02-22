local Super = require(script.Parent)
local TrapBomb = Super:Extend()

TrapBomb.Radius = 8
TrapBomb.RadiusSq = TrapBomb.Radius ^ 2
TrapBomb.Delay = 0.6
TrapBomb.Damage = 0.5

function TrapBomb:OnCreated()
	self.Model = self.Storage.Models.PowderKeg:Clone()
	Super.OnCreated(self)
	self.Model:SetPrimaryPartCFrame(self.StartCFrame * CFrame.new(0, 1.5, 0))
	
	self.Character = self:CreateNew"Character"{
		Model = self.Model,
		Name = "an explosive trap",
	}
end

function TrapBomb:OnTriggered(legend)
	if not self.Active then return end
	self.Active = false
	
	local position = self.StartCFrame.Position
	
	self:GetService("EffectsService"):RequestEffectAll("TelegraphCircle", {
		Position = position,
		Radius = self.Radius,
		Duration = self.Delay,
	})
	
	delay(self.Delay, function()
		local root = self.Model.Root
		root.Explode:Play()
		root.Attachment:Destroy()
		root.Transparency = 1
		
		game:GetService("Debris"):AddItem(self.Model, root.Explode.TimeLength)
		
		local targets = self:GetService("TargetingService"):GetMortals()
		for _, target in pairs(targets) do
			if target:DistanceToSquared(position) < self.RadiusSq then
				self:GetService("DamageService"):Damage{
					Source = self.Character,
					Target = target,
					Amount = target.MaxHealth:Get() * self.Damage,
					Type = "Bludgeoning",
				}
			end
		end
	end)
end

return TrapBomb
