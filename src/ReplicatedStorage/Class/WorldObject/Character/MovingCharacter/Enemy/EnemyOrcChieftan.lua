local Super = require(script.Parent)
local EnemyOrcChieftan = Super:Extend()

EnemyOrcChieftan.Resilient = true

function EnemyOrcChieftan:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"WarCry",
		"Basic", 2,
		"Clamp",
		"Basic", 2,
		"Jump",
		"Basic",
		"Clamp", 2,
		"Basic",
		"Clamp", 3,
		"Jump",
	}}
	
	Super.OnCreated(self)
	
	self:AnimationPlay("OrcChieftanIdle")
	self:GetService("MusicService"):PlayPlaylist{"Primal Fear"}
	
	self.Speed.Base = 24
end

function EnemyOrcChieftan:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	self.StateMachine:Run(dt)
end

EnemyOrcChieftan.RangeByAttack = {
	Basic = 12,
	WarCry = 128,
	Clamp = 128,
	Jump = 128,
}

EnemyOrcChieftan.WalkAnimation = "OrcChieftanWalk"

EnemyOrcChieftan.DetectionRange = 128

EnemyOrcChieftan.Frustration = 0
EnemyOrcChieftan.FrustrationLimit = 2

function EnemyOrcChieftan:AirBlast(args)
	if not self.Active then return end
	
	local speed = args.Speed
	local width = args.Width
	local cframe = args.CFrame
	local range = args.Range

	local crescent = self.Storage.Models.Crescent:Clone()
	crescent.Size = Vector3.new(width, 0, 4)

	local model = Instance.new("Model")
	crescent.Parent = model
	model.Name = "AirSlice"
	model.PrimaryPart = crescent

	local projectile = self:CreateNew"Projectile"{
		Model = model,
		CFrame = cframe,
		Velocity = cframe.LookVector * speed,
		FaceTowardsVelocity = true,
		Range = range,
		Victims = {},

		OnTicked = function(p)
			local here = p.LastCFrame.Position
			local there = p.CFrame.Position
			local delta = (there - here)
			local length = delta.Magnitude
			local midpoint = (here + there) / 2
			local cframe = CFrame.new(midpoint, there)

			for _, legend in pairs(self:GetClass("Legend").Instances) do
				local delta = cframe:PointToObjectSpace(legend:GetPosition())
				if math.abs(delta.X) <= (width / 2) and math.abs(delta.Z) <= (length / 2) and (not table.find(p.Victims, legend)) then
					self:DamageFunc(0.5, "Slashing")(legend)
					table.insert(p.Victims, legend)
				end
			end
		end,
	}
	self:GetWorld():AddObject(projectile)

	local effects = self:GetService("EffectsService")
	effects:RequestEffectAll("ShowProjectile", {
		Projectile = projectile.Model,
		Width = width,
	})
	
	if args.Sound then
		effects:RequestEffectAll("Sound", {
			Position = cframe.Position,
			Sound = args.Sound,
		})
	end
end

function EnemyOrcChieftan:Shockwave(args)
	local position = args.Position
	local count = args.Count
	
	local angle = args.BaseAngle or (math.pi * 2 * math.random())
	
	for step = 0, count - 1 do
		local theta = angle + (math.pi * 2 / count) * step
		local cframe = CFrame.new(position) * CFrame.Angles(0, theta, 0)
		self:AirBlast({
			Width = args.Width,
			Speed = args.Speed,
			Range = args.Range,
			CFrame = cframe,
		})
	end
end

function EnemyOrcChieftan:QuickShockwave(argsIn)
	local args = {
		Count = 12,

		Range = 32,
		Speed = 14,
		Width = 6,
	}
	for key, val in pairs(argsIn) do
		args[key] = val
	end
	
	self:Shockwave(args)
end

function EnemyOrcChieftan:GetOverdrive()
	if self.Health < (self.MaxHealth:Get() / 2) then
		return 1.1
	else
		return 0.8
	end
end

function EnemyOrcChieftan:AttackJump()
	local speed = 1 * self:GetOverdrive()
	
	local duration = 1 / speed
	local jumpTime = (14/30) / speed
	
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local cframe = CFrame.new(here, here + delta) + delta
	
	local length = 40
	local width = 20
	
	local landingPosition = (cframe * CFrame.new(0, 0, length / 2)).Position
	if not self:DoesPointHaveFloor(landingPosition, 4) then return end
	
	self:AttackSquare{
		CFrame = cframe,
		Length = length,
		Width = width,
		Duration = duration,
		OnHit = self:DamageFunc(5, "Slashing"),
	}
	
	delay(jumpTime, function()
		local cframe = self.Root.CFrame
		local jumpDelta = (landingPosition - cframe.Position) * Vector3.new(1, 0, 1)
		cframe += jumpDelta
		
		self:TweenNetwork{
			Object = self.Root,
			Goals = {CFrame = cframe},
			Duration = duration - jumpTime,
			Style = Enum.EasingStyle.Linear,
		}
	end)
	
	self:AnimationPlay("OrcChieftanAttackJump")
	
	self.StateMachine:ChangeState("Resting", {
		Duration = duration + 0.25,
		NextState = "Waiting",
	})
end

function EnemyOrcChieftan:AttackClamp()
	local speed = 1 * self:GetOverdrive()
	
	local duration = 1 / speed
	
	local target = self:GetFurthestTarget(self.DetectionRange)
	if not target then return end
	
	local here = self:GetFootPosition()
	local there = target:GetFootPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local cframe = CFrame.new(here, here + delta)
	
	self:AnimationPlay("OrcChieftanAttackClamp", nil, nil, speed)
	
	local length = 32
	local width = 16
	local tilt = math.pi / 6
	
	local center = cframe * CFrame.new(0, 0, -length / 2)
	
	local cframes = {
		center * CFrame.new( width / 3, 0, 0) * CFrame.Angles(0,  tilt, 0),
		center * CFrame.new(-width / 3, 0, 0) * CFrame.Angles(0, -tilt, 0),
	}
	
	for _, cframe in pairs(cframes) do
		self:AttackSquare{
			CFrame = cframe,
			Length = length,
			Width = width,
			Duration = duration,
			OnHit = self:DamageFunc(1, "Slashing"),
			Sound = self.EnemyData.Sounds.AirSlice,
		}
	end
	
	delay(duration, function()
		local angle = math.pi / 2
		local count = 5
		
		for step = 0, count - 1 do
			local theta = (-angle / 2) + (angle / count) * (step + 0.5)
			self:AirBlast{
				CFrame = cframe * CFrame.Angles(0, theta, 0) + Vector3.new(0, 2, 0),
				Width = 10,
				Speed = 32,
				Range = 128,
			}
		end
	end)
	
	local pause = 0.25
	
	local hopSpeed = 64 * speed
	local hopDuration = 0.5 / speed
	local hopExtra = 0.2

	delay(duration + pause, function()
		self:Dash(self.Root.CFrame.LookVector * hopSpeed, hopDuration)
		self:AnimationPlay("OrcChieftanSlide", nil, nil, 1 / (hopDuration + hopExtra))
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = duration + hopDuration + pause + 0.25,
		NextState = "Waiting",
	})
end

function EnemyOrcChieftan:AttackWarCry()
	local speed = 1 * self:GetOverdrive()
	
	local duration = 2 / speed
	local count = 3
	
	self:AnimationPlay("OrcChieftanWarCry", nil, nil, speed)
	
	delay(duration / 2, function()
		self:SoundPlay("Scream")
		
		local t = duration / 2
		local tStep = t / count
		for step = 0, count - 1 do
			wait(tStep)
			
			local c = 24
			local a = (math.pi * 2) / 24
			
			self:QuickShockwave{
				Position = self:GetFootPosition() + Vector3.new(0, 2, 0),
				Range = 128,
				Count = c,
				BaseAngle = a / 2 * (step % 2),
			}
		end
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = duration + 0.5,
		NextState = "Waiting",
	})
end

function EnemyOrcChieftan:AttackBasic()
	local speed = 0.7 * self:GetOverdrive()
	
	local duration = 0.5 / speed
	local radius = 10
	
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local cframe = CFrame.new(here, here + delta)
	
	self:AnimationPlay("OrcChieftanAttackDouble", nil, nil, speed)
	
	local function attack(cframe)
		self:AttackCircle{
			Position = cframe.Position,
			Radius = radius,
			Duration = duration,
			OnHit = self:DamageFunc(0.5, "Slashing"),
		}
		
		local length = radius * 2
		local width = length * 0.6
		local offset = (radius - 2) + (length / 2)
		
		self:AttackSquare{
			CFrame = cframe * CFrame.new(0, 0, -offset),
			Length = length,
			Width = width,
			Duration = duration,
			OnHit = self:DamageFunc(0.5, "Slashing"),
		}
	end
	
	cframe *= CFrame.new(0, 0, -radius)
	attack(cframe)
	delay(duration, function()
		attack(cframe)
		wait(duration)
		self:QuickShockwave{Position = cframe.Position + Vector3.new(0, 2, 0)}
	end)
	
	local hopSpeed = 32 * speed
	local hopDuration = 0.5 / speed
	local hopExtra = 0.2
	
	delay(duration * 2, function()
		self:Dash(-self.Root.CFrame.LookVector * hopSpeed, hopDuration)
		self:AnimationPlay("OrcChieftanSlide", nil, nil, 1 / (hopDuration + hopExtra))
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = duration * 2 + hopDuration + hopExtra,
		NextState = "Waiting",
	})
end

function EnemyOrcChieftan:Flinch()
	-- don't
end

function EnemyOrcChieftan:IsTargetValid()
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

function EnemyOrcChieftan:CreateStateMachine()
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
			self:AnimationPlay(self.WalkAnimation, nil, nil, 1)
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
			local range = self.RangeByAttack[attack]
			
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
			self:AnimationStop(self.WalkAnimation)
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

return EnemyOrcChieftan