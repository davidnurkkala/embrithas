local Super = require(script.Parent)
local EnemyStoneCorruption = Super:Extend()

EnemyStoneCorruption.HeaveRange = 30
EnemyStoneCorruption.HeaveCooldownTime = 2
EnemyStoneCorruption.HeaveInaccuracy = 16
EnemyStoneCorruption.HeaveRadius = 12
EnemyStoneCorruption.HeaveTravelTime = 0.5

function EnemyStoneCorruption:OnCreated()
	self.HeaveCooldown = self:CreateNew"Cooldown"{Time = self.HeaveCooldownTime}
	
	Super.OnCreated(self)
end

function EnemyStoneCorruption:CreateStateMachine()
	Super.CreateStateMachine(self)
	
	self.StateMachine:AddState{
		Name = "Chasing",
		OnStateChanged = function()
			self:AnimationPlay(self.RunAnimation, nil, nil, 2)
		end,
		
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			self:MoveTo(targetPosition)
			
			if self.HeaveCooldown:IsReady() and distance < self.HeaveRange then
				machine:ChangeState("Heaving")
				
			elseif distance < self.AttackRange then
				machine:ChangeState("Attacking")
				
			elseif distance > self.DetectionRange then
				self.Target = nil
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop(self.RunAnimation)
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Heaving",
		
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			self.HeaveCooldown:Use()
			
			local duration = 0.5
			
			self:AnimationPlay("StoneCorruptionHeave", nil, nil, 1 / duration)
			
			local targetPosition = self.Target:GetFootPosition()
			local theta = math.pi * 2 * math.random()
			local r = self.HeaveInaccuracy * math.random()
			targetPosition += Vector3.new(
				math.cos(theta) * r,
				0,
				math.sin(theta) * r
			)
			
			self:AttackCircle{
				Position = targetPosition,
				Radius = self.HeaveRadius,
				Duration = duration + self.HeaveTravelTime,
				OnHit = function(legend)
					self:GetService"DamageService":Damage{
						Source = self,
						Target = legend,
						Amount = self.Damage,
						Type = "Bludgeoning",
					}
				end,
				Sound = self.EnemyData.Sounds.Rock,
			}
			
			delay(duration, function()
				self:GetService("EffectsService"):RequestEffectAll("LobProjectile", {
					Start = self.Model.RightHand.Position,
					Finish = targetPosition,
					Height = 12,
					Duration = self.HeaveTravelTime,
					Model = self.Storage.Models.CorruptedEarthStrike,
				})
			end)
			
			machine:ChangeState("Resting", {
				Duration = duration,
				NextState = "Waiting",
			})
		end
	}
end

return EnemyStoneCorruption