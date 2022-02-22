local Super = require(script.Parent)
local EnemyCryptkeeper = Super:Extend()

EnemyCryptkeeper.Resilient = true

function EnemyCryptkeeper:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Spin",
		"Basic", 3,
		"Summon",
		"Return",
		"Resonance",
		"Spin",
		"Basic", 3,
		"Totem",
		"Basic", 3,
		"Spin",
		"Return",
		"Slam",
	}}
	
	Super.OnCreated(self)
	
	self:AnimationPlay("CryptkeeperIdle")
	self:GetService("MusicService"):PlayPlaylist{"Symphony of the Countless Dead"}
end

function EnemyCryptkeeper:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	self.StateMachine:Run(dt)
end

EnemyCryptkeeper.DetectionRange = 128
EnemyCryptkeeper.AttackRange = 12

EnemyCryptkeeper.Frustration = 0
EnemyCryptkeeper.FrustrationLimit = 2

function EnemyCryptkeeper:AttackSummon()
	local targets = self:GetService("TargetingService"):GetMortals()
	
	local function summon(position)
		local duration = 3
		
		self:AttackCircle{
			Position = position,
			Radius = 6,
			Duration = duration,
			Sound = self.EnemyData.Sounds.Cast,
		}
		
		self:Channel(duration, nil, function()
			local enemyService = self:GetService("EnemyService")
			local enemy = enemyService:CreateEnemy("Skeleton Berserker", self.Level, false){
				StartCFrame = CFrame.new(position) + Vector3.new(0, 6, 0)
			}
			enemyService:ApplyDifficultyToEnemy(enemy)
			self:GetWorld():AddObject(enemy)
		end)
	end
	
	for _, target in pairs(targets) do
		summon(target:GetFootPosition())
	end
	
	self:AnimationPlay("CryptkeeperSummon")
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 2,
	})
end

function EnemyCryptkeeper:Resonate()
	local initial = 4
	local count = 6
	local pause = 1.5
	
	local areas = self:GetRun().Dungeon.Model.ResonanceAreas:GetChildren()
	
	local function wave(duration, volume)
		for _, area in pairs(areas) do
			self:AttackSquare{
				CFrame = area.CFrame,
				Length = area.Size.Z,
				Width = area.Size.X,
				Duration = duration,
				OnHit = function(legend)
					self:GetService("DamageService"):Damage{
						Source = self,
						Target = legend,
						Amount = self.Damage,
						Type = "Bludgeoning",
					}
				end,
				Sound = self.Storage.Sounds.Silence,
			}
		end
		
		delay(duration, function()
			local sound = self.EnemyData.Sounds.Bell1:Clone()
			sound.Volume = volume
			sound.Parent = workspace
			sound:Play()
			game:GetService("Debris"):AddItem(sound, sound.TimeLength / sound.PlaybackSpeed)
		end)
	end
	
	wave(initial, 1)
	for step = 0, count - 1 do
		local t = initial + (pause * step)
		local v = 1 - (step + 1) * 0.1
		delay(t, function()
			wave(pause, v)
		end)
	end
end

function EnemyCryptkeeper:FaceForward()
	self:FaceTowards(Vector3.new(256, 0, 0))
end

function EnemyCryptkeeper:AttackResonance()
	self:FaceForward()
	self:AnimationPlay("CryptkeeperRinging")
	
	local function ring(duration, radius, sound)
		self:AttackCircle{
			Position = self:GetFootPosition(),
			Radius = radius,
			Duration = duration,
			OnHit = function(legend)
				self:GetService("DamageService"):Damage{
					Source = self,
					Target = legend,
					Amount = self.Damage,
					Type = "Bludgeoning",
				}
			end,
			Sound = sound,
		}
		wait(duration)
	end
	
	spawn(function()
		ring(1.5, 20)
		ring(1.5, 25)
		self:Resonate()
		ring(1.5, 30)
		ring(1.5, 35)
		ring(0.3, 40, self.EnemyData.Sounds.Rumble)
	end)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 7,
	})
end

function EnemyCryptkeeper:AttackBasic()
	local radius = 9
	local duration = 1
	
	local length = 30
	local width = 9
	
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition() + (self.Target:GetFlatVelocity() * duration * 0.5)
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local position = here + delta.Unit * radius
	
	self:FaceTowards(position)
	
	local function onHit(legend)
		self:GetService"DamageService":Damage{
			Source = self,
			Target = legend,
			Amount = self.Damage,
			Type = "Slashing",
		}
	end
	
	local function line(angle)
		local dz = (length / 2) + radius - 2
		
		local cframe = CFrame.new(position, position + delta)
		cframe *= CFrame.Angles(0, angle, 0)
		cframe *= CFrame.new(0, 0, -dz) 
		
		self:AttackSquare{
			CFrame = cframe,
			Length = length,
			Width = width,
			Duration = duration,
			OnHit = onHit,
			Sound = self.Storage.Sounds.Silence,
		}
	end
	
	self:AttackCircle{
		Position = position,
		Radius = radius,
		Duration = duration,
		OnHit = onHit,
	}
	
	local count = 7
	for step = 0, count - 1 do
		line(math.pi * 2 / count * step)
	end
	
	self:AnimationPlay("CryptkeeperAttack", nil, nil, 1 / duration)
	delay(duration, function()
		self:SoundPlay("Rumble")
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = duration + 0.5,
		NextState = "Waiting",
	})
end

function EnemyCryptkeeper:AttackRoll()
	local direction = CFrame.Angles(0, math.pi * 2 * math.random(), 0).LookVector
	local velocity = direction * 64
	local duration = 0.5
	self:FaceTowards(self:GetPosition() + velocity)
	self:Dash(velocity, duration)
	self:AnimationPlay("EvrigBossRoll", nil, nil, 1 / duration)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = duration,
		NextState = "Waiting",
	})
end

function EnemyCryptkeeper:AttackReturn()
	self.StateMachine:ChangeState("Returning")
end

function EnemyCryptkeeper:AttackSpin()
	local count = 12
	local length = 64
	local width = 10
	local duration = 1.5
	local radius = 14
	
	local function onHit(legend)
		self:GetService("DamageService"):Damage{
			Source = self,
			Target = legend,
			Amount = self.Damage,
			Type = "Slashing",
		}
	end
	
	local thetaStep = math.pi * 2 / count
	for step = 0, count - 1 do
		local dz = radius + length / 2 - 2
		local theta = thetaStep * step
		local cframe = CFrame.new(self:GetFootPosition()) * CFrame.Angles(0, theta, 0) * CFrame.new(0, 0, -dz)
		self:AttackSquare{
			Length = length,
			Width = width,
			Duration = duration,
			CFrame = cframe,
			OnHit = onHit,
			Sound = self.Storage.Sounds.Silence,
		}
	end
	
	self:AttackCircle{
		Position = self:GetFootPosition(),
		Radius = radius,
		Duration = duration,
		OnHit = onHit,
		Sound = self.Storage.Sounds.Silence,
	}
	
	delay(duration, function()
		self:SoundPlay("AirSlice")
		self:SoundPlay("Slice")
	end)
	
	delay(duration - 1, function()
		self:AnimationPlay("CryptkeeperSpin")
	end)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = duration + 1,
	})
end

function EnemyCryptkeeper:DeployTotems()
	local radius = 24
	local duration = 10
	local deployDelay = 1.5
	
	local center = self:GetFootPosition()
	
	local function totem(position)
		local totem = self.EnemyData.Totem:Clone()
		local root = totem.PrimaryPart
		totem.Parent = workspace.Effects
		
		local cframe = CFrame.new(position) * CFrame.Angles(0, math.pi * 2 * math.random(), 0) + Vector3.new(0, 4, 0)
		root.CFrame = cframe + Vector3.new(0, 64, 0)
		self:TweenNetwork{
			Object = root,
			Goals = {CFrame = cframe},
			Duration = deployDelay,
			Style = Enum.EasingStyle.Quad,
			Direction = Enum.EasingDirection.In,
		}.Completed:Connect(function()
			root.Rumble:Play()
		end)
		
		self:AttackActiveCircle{
			Position = position,
			Radius = radius,
			Delay = deployDelay,
			Duration = duration,
			Interval = 1,
			
			OnTicked = function()
				root.Ring:Play()
			end,
			
			OnHit = function(legend, dt)
				self:GetService"DamageService":Damage{
					Source = self,
					Target = legend,
					Amount = self.Damage * dt,
					Type = "Bludgeoning",
				}
			end,
			
			OnCleanedUp = function(t)
				self:GetService("EffectsService"):RequestEffectAll("FadeModel", {
					Model = totem,
					Duration = 1,
				})
			end
		}
	end
	
	local targets = self:GetService("TargetingService"):GetMortals()
	if #targets == 0 then return end
	self:Shuffle(targets)
	
	local index = 1
	for _ = 1, 5 do
		local target = targets[index]
		delay(self:RandomFloat(0, 2), function()
			totem(target:GetFootPosition())
		end)
		
		index += 1
		if index > #targets then
			index = 1
		end
	end
end

function EnemyCryptkeeper:AttackTotem()
	local speed = 1
	local windup = 0.5
	
	local radius = 64
	local ringRadius = 16
	local count = 16
	local duration = 1.3 / speed + windup
	
	local center = self:GetFootPosition()
	local thetaStep = math.pi * 2 / count
	for step = 0, count - 1, 2 do
		local theta = thetaStep * step
		local position = center + Vector3.new(math.cos(theta) * radius, 0, math.sin(theta) * radius)
		self:AttackCircle{
			Position = position,
			Radius = ringRadius,
			Duration = duration,
			OnHit = function(legend)
				self:GetService("DamageService"):Damage{
					Source = self,
					Target = legend,
					Amount = self.Damage,
					Type = "Bludgeoning",
				}
			end,
			Sound = self.Storage.Sounds.Silence,
		}
	end
	
	delay(duration, function()
		self:SoundPlay("Hit")
		
		self:DeployTotems()
	end)
	
	delay(0.3 / speed + windup, function()
		local r = radius - 8
		self:PushMortalsAway(center, r, 64)
		self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
			Position = center,
			Radius = r,
			Duration = 0.5,
			Color = Color3.new(1, 1, 1),
		})
		self:SoundPlay("Rumble")
	end)
	
	delay(windup, function()
		self:AnimationPlay("CryptkeeperStompAndSmash", nil, nil, speed)
	end)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 2 / speed,
	})
end

function EnemyCryptkeeper:AttackSlam()
	local targets = self:GetService("TargetingService"):GetMortals()
	local position = Vector3.new()
	local count = 0
	for _, target in pairs(targets) do
		position += target:GetPosition()
		count += 1
	end
	position /= count
	
	self:FaceTowards(position)
	self:AnimationPlay("CryptkeeperSmash")
	
	local here = self:GetFootPosition()
	local delta = (position - here) * Vector3.new(1, 0, 1)
	local cframe = CFrame.new(here, here + delta)
	
	local width = 24
	local widthStep = 16
	local length = 16
	local count = 10
	local windup = 1.5
	local pause = 0.2
	
	for step = 0, count do
		delay(pause * step, function()
			local dz = length / 2 + (length * step)
			self:AttackSquare{
				CFrame = cframe * CFrame.new(0, 0, -dz),
				Width = width + widthStep * step,
				Length = length,
				Duration = windup,
				OnHit = function(legend)
					self:GetService("DamageService"):Damage{
						Source = self,
						Target = legend,
						Amount = self.Damage,
						Type = "Bludgeoning",
					}
				end,
				Sound = self.EnemyData.Sounds.Rumble,
			}
		end)
	end
	
	delay(windup, function()
		self:SoundPlay("Hit")
	end)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = windup + (pause * count),
	})
end

function EnemyCryptkeeper:Flinch()
	-- don't
end

function EnemyCryptkeeper:IsTargetValid()
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

function EnemyCryptkeeper:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if self:IsTargetValid() then
				self:FaceTowards(self.Target:GetPosition())
				machine:ChangeState("Chasing")
			end
			self:StuckCheck(dt)
		end,
		OnStateWillChange = function()
			self:StuckReset()
		end
	}
	
	self.StateMachine:AddState{
		Name = "Chasing",
		OnStateChanged = function()
			self:AnimationPlay("CryptkeeperWalk")
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
			
			if attack == "Summon" then
				range = self.DetectionRange
			elseif attack == "Resonance" then
				range = self.DetectionRange
			elseif attack == "Slam" then
				range = self.DetectionRange
			elseif attack == "Return" then
				range = self.DetectionRange
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
			self:AnimationStop("CryptkeeperWalk")
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Returning",
		OnStateChanged = function()
			self:AnimationPlay("CryptkeeperWalk")
		end,
		Run = function(state, machine, dt)
			local goal = Vector3.new(0, 0, 0)
			
			self:MoveTo(goal)
			
			local delta = (goal - self:GetPosition()) * Vector3.new(1, 0, 1)
			local d = math.max(math.abs(delta.X), math.abs(delta.Z))
			if d < 1 then
				machine:ChangeState("Waiting")
			end
		end,
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop("CryptkeeperWalk")
		end
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

return EnemyCryptkeeper