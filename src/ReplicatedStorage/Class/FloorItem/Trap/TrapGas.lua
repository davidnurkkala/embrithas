local Super = require(script.Parent)
local TrapGas = Super:Extend()

TrapGas.Radius = 8
TrapGas.Delay = 1
TrapGas.ActiveDuration = 5
TrapGas.RestDuration = 3
TrapGas.Damage = 0.1

function TrapGas:OnCreated()
	self.Model = self.Storage.Models.GasGrate:Clone()
	Super.OnCreated(self)
	self.Model:SetPrimaryPartCFrame(self.StartCFrame * CFrame.new(0, 0.6, 0))
	
	self.Character = self:CreateNew"Character"{
		Model = self.Model,
		Name = "poisonous gas",
		Telegraphs = {},
	}
	
	delay(self.RestDuration * math.random(), function()
		self:Cycle()
	end)
end

function TrapGas:Cycle()
	if self.Room.State == "Completed" then return end
	
	self:GetClass("Enemy").AttackActiveCircle(self.Character, {
		Position = self.StartCFrame.Position,
		Radius = self.Radius,
		Delay = self.Delay,
		Duration = self.ActiveDuration,
		Interval = 0.2,
		
		OnHit = function(legend, dt)
			self:GetService("DamageService"):Damage{
				Source = self.Character,
				Target = legend,
				Amount = legend.MaxHealth:Get() * self.Damage * dt,
				Type = "Internal",
			}
		end,
		
		OnStarted = function()
			self.Model.Root.Emitter.Enabled = true
		end,
		
		OnCleanedUp = function()
			self.Model.Root.Emitter.Enabled = false
		end,
	})
	
	delay(self.ActiveDuration + self.RestDuration, function()
		self:Cycle()
	end)
end

return TrapGas
