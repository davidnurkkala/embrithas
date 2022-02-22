local Super = require(script.Parent)
local EnemyForgottenShadows = Super:Extend()

EnemyForgottenShadows.Resilient = true

function EnemyForgottenShadows:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
			"Shockwave", 3,
			"Spin",
			"Shockwave", 3,
			"Earthquake",
			"Shockwave", 3,
			"Entrap",
	}}
	
	Super.OnCreated(self)
	
	self:AnimationPlay("ShadowBossIdle")
	self:GetService("MusicService"):PlayPlaylist{"Long Dark Shadow"}
end

function EnemyForgottenShadows:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	self.StateMachine:Run(dt)
end

EnemyForgottenShadows.DetectionRange = 128
EnemyForgottenShadows.AttackRange = 12

EnemyForgottenShadows.Frustration = 0
EnemyForgottenShadows.FrustrationLimit = 2

function EnemyForgottenShadows:AttackShockwave()
	local count = 6
	local radius = 6
	local duration = 0.8
	
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition() + self.Target:GetFlatVelocity() * duration
	local delta = (there - here) * Vector3.new(1, 0, 1)
	
	for number = 0, count - 1 do
		delay(0.1 * number, function()
			local position = here + delta.Unit * radius * 1.5 * number
			
			self:AttackCircle{
				Position = position,
				Radius = radius + (number * 0.5),
				Duration = duration,
				OnHit = function(legend)
					self:GetService"DamageService":Damage{
						Source = self,
						Target = legend,
						Amount = self.Damage,
						Type = "Bludgeoning",
					}
				end,
				Sound = (number == 0) and self.EnemyData.Sounds.Hit or self.Storage.Sounds.Silence
			}
		end)
	end
	
	self:FaceTowards(there)
	self:AnimationPlay("ShadowBossAttack0", nil, nil, 1 / duration)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = duration + 0.25,
		NextState = "Waiting",
	})
end

function EnemyForgottenShadows:AttackSpin()
	local radius = 40
	local duration = 3
	
	self:AttackCircle{
		Position = self:GetFootPosition(),
		Radius = radius,
		Duration = duration,
		OnHit = function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage * 4,
				Type = "Bludgeoning",
			}
		end,
	}
	
	delay(duration - 1, function()
		self:AnimationPlay("ShadowBossAttackSpin")
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = duration + 1,
		NextState = "Waiting",
	})
end

function EnemyForgottenShadows:AttackEarthquake()
	local pause = 1
	local duration = 10
	local radius = 12
	
	local function quake(target)
		local dust = self.EnemyData.EmitterPart:Clone()
		local position = target:GetFootPosition()
		
		self:AttackActiveCircle{
			Position = position,
			Radius = radius,
			Delay = pause,
			Duration = duration,
			Interval = 0.2,
			
			OnHit = function(legend, dt)
				self:GetService"DamageService":Damage{
					Source = self,
					Target = legend,
					Amount = self.Damage * 0.2 * dt,
					Type = "Bludgeoning",
					Tags = {"Magical"},
				}
			end,
			
			OnStarted = function(t)
				dust.Position = position + Vector3.new(0, 4, 0)
				dust.Parent = workspace.Effects
				dust.Sound:Play()
			end,
			
			OnCleanedUp = function(t)
				dust.Emitter.Enabled = false
				game:GetService("Debris"):AddItem(dust, dust.Emitter.Lifetime.Max)
			end
		}
	end
	
	local targets = self:GetClass("Legend").Instances
	if #targets == 0 then return end
	
	self:Shuffle(targets)
	
	for index = 1, math.min(10, #targets) do
		quake(targets[index])
	end
	
	self:AnimationPlay("ShadowBossAttackSlam", nil, nil, 1 / pause)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = pause,
		NextState = "Waiting",
	})
end

function EnemyForgottenShadows:AttackEntrap()
	local pause = 2
	local duration = 10
	local size = 12
	
	local function entrap(target)
		local here = self:GetFootPosition()
		local there = target:GetFootPosition()
		local delta = (there - here) * Vector3.new(1, 0, 1)
		local cframe = CFrame.new(there, there - delta)
		
		local height = 8
		local width = 1
		
		local left = self.EnemyData.ShadowWall:Clone()
		left.Size = Vector3.new(width, height, size + width)
		left.CFrame = cframe * CFrame.new(-size / 2, height / 2, 0)
		
		local right = self.EnemyData.ShadowWall:Clone()
		right.Size = Vector3.new(width, height, size + width)
		right.CFrame = cframe * CFrame.new(size / 2, height / 2, 0)
		
		local back = self.EnemyData.ShadowWall:Clone()
		back.Size = Vector3.new(size - width, height, width)
		back.CFrame = cframe * CFrame.new(0, height / 2, size / 2)
		
		local parts = {left, right, back}
		
		for _, part in pairs(parts) do
			local cframe = part.CFrame
			part.CFrame = part.CFrame * CFrame.new(0, -part.Size.Y, 0)
			part.Parent = self:GetService("GameService").CurrentRun.Dungeon.Model
			self:TweenNetwork{
				Object = part,
				Goals = {CFrame = cframe},
				Duration = 0.25,
			}
			delay(duration, function()
				self:TweenNetwork{
					Object = part,
					Goals = {CFrame = part.CFrame * CFrame.new(0, -part.Size.Y, 0)},
					Duration = 0.25
				}.Completed:Connect(function()
					part:Destroy()
				end)
			end)
		end
		
		self:AttackSquare{
			CFrame = cframe,
			Width = size,
			Length = size,
			Duration = pause,
			OnHit = function(legend)
				self:GetService"DamageService":Damage{
					Source = self,
					Target = legend,
					Amount = self.Damage,
					Type = "Slashing",
					Tags = {"Magical"},
				}
			end,
		}
	end
	
	local targets = self:GetClass("Legend").Instances
	if #targets == 0 then return end
	
	self:Shuffle(targets)
	
	for index = 1, math.min(5, #targets) do
		entrap(targets[index])
	end
	
	self:AnimationPlay("ShadowBossAttackSlam")
	
	self.StateMachine:ChangeState("Resting", {
		Duration = 1,
		NextState = "Waiting",
	})
end

function EnemyForgottenShadows:Flinch()
	-- don't
end

function EnemyForgottenShadows:IsTargetValid()
	if not self.Target then
		return false
	end
	
	if not self:IsPointInRange(self.Target:GetPosition(), self.DetectionRange) then
		return false
	end
	
	if not self:CanSeePoint(self.Target:GetPosition()) then
		return false
	end
	
	return true
end

function EnemyForgottenShadows:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if self:IsTargetValid() then
				machine:ChangeState("Chasing")
			end
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Chasing",
		OnStateChanged = function()
			self:AnimationPlay("ShadowBroWalk")
		end,
		
		Run = function(state, machine, dt)
			self.Frustration = self.Frustration + dt
			if self.Frustration > self.FrustrationLimit then
				self.Frustration = 0
				self.Target = self:GetNearestTarget(self.DetectionRange)
			end
			
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			self:MoveTo(targetPosition)
			
			local attack = self.AttackPattern:Get()
			local range = self.AttackRange
			
			if attack == "Shockwave" then
				range = 40
			elseif attack == "Spin" then
				range = 32
			elseif attack == "Earthquake" then
				range = self.DetectionRange
			elseif attack == "Entrap" then
				range = 64
			end
			
			if distance < range then
				self["Attack"..attack](self)
				self.AttackPattern:Next()
			
			elseif distance > self.DetectionRange then
				self.Target = nil
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function()
			self.Frustration = 0
			self:MoveStop()
			self:AnimationStop("ShadowBroWalk")
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Resting",
		Run = function(state, machine, dt)
			state.Duration = state.Duration - dt
			if state.Duration <= 0 then
				machine:ChangeState(state.NextState)
			end
		end
	}
end

return EnemyForgottenShadows