local Super = require(script.Parent)
local TrapDart = Super:Extend()

function TrapDart:OnCreated()
	self.Character = self:CreateNew"Character"{
		Model = self.Model,
		Name = "a dart trap",
	}
	
	self.DartPart = self.Model.__DartPart
	
	self:FireProjectile()
end

function TrapDart:FireProjectile()
	if self.Room.State == "Completed" then return end
	
	self:GetClass"Projectile".CreateHostileProjectile{
		CFrame = self.DartPart.CFrame,
		Speed = self.ProjectileSpeed,
		Width = self.ProjectileWidth,
		Model = self.Storage.Models:FindFirstChild(self.ProjectileName),
		OnHitTarget = function(legend)
			self:GetService("DamageService"):Damage{
				Source = self.Character,
				Target = legend,
				Amount = legend.MaxHealth:Get() * self.Damage,
				Type = "Piercing",
			}
		end,
	}
	
	delay(1 / self.FireRate, function()
		self:FireProjectile()
	end)
end

return TrapDart