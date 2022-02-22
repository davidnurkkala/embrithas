local Super = require(script.Parent)
local EnemyZombie = Super:Extend()

function EnemyZombie:OnCreated()
	Super.OnCreated(self)
	
	local injuries = self.Model.Injuries:GetChildren()
	self:Shuffle(injuries)
	
	for index = 1, math.random(1, 4) do
		injuries[index].Transparency = 0
	end
	
	self.ToxicCooldown = self:CreateNew"Cooldown"{Time = 2}
end

function EnemyZombie:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.ToxicCooldown:IsReady() then
		self.ToxicCooldown:Use()
		
		local cloud = self.EnemyData.EmitterPart:Clone()
		local position = self:GetFootPosition()
		
		self:AttackActiveCircle{
			Position = position,
			Radius = 6,
			Delay = 0.5,
			Duration = 6,
			Interval = 0.2,
			
			OnHit = function(legend, dt)
				self:GetService"DamageService":Damage{
					Source = self,
					Target = legend,
					Amount = self.Damage * 0.5 * dt,
					Type = "Internal",
				}
			end,
			
			OnStarted = function(t)
				cloud.Position = position
				cloud.Parent = workspace.Effects
			end,
			
			OnCleanedUp = function(t)
				cloud.Attachment.Emitter.Enabled = false
				game:GetService("Debris"):AddItem(cloud, cloud.Attachment.Emitter.Lifetime.Max)
			end
		}
	end
end

return EnemyZombie