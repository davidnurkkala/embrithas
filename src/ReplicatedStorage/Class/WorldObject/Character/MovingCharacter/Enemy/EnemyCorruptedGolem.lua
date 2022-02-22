local Super = require(script.Parent)
local EnemyCorruptedGolem = Super:Extend()

EnemyCorruptedGolem.Resilient = true

function EnemyCorruptedGolem:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Slam",
		"Shockwave", 2,
		"Roll",
		"Shockwave", 2,
		"Boulders",
		"Slam",
		"Shockwave", 2,
		"Roll",
		"Shockwave", 2,
		"Roll",
		"Shockwave",
		"Boulders",
		"Shockwave",
		"Boulders",
		"Summon",
	}}
	
	Super.OnCreated(self)
	
	self:GetService("MusicService"):PlayPlaylist{"BossFightTheme"}
end

function EnemyCorruptedGolem:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	self.StateMachine:Run(dt)
end

EnemyCorruptedGolem.DetectionRange = 128
EnemyCorruptedGolem.AttackRange = 12
EnemyCorruptedGolem.Name = "Corrupted Golem"

EnemyCorruptedGolem.Frustration = 0
EnemyCorruptedGolem.FrustrationMax = 2

function EnemyCorruptedGolem:Telegraph(args)
	self:AttackCircle{
		Position = args.Position,
		Radius = args.Radius,
		Duration = args.Duration,
		OnHit = args.OnHit or function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage,
				Type = "Bludgeoning",
			}
		end,
		Sound = args.Sound or self.EnemyData.Sounds.Hit,
	}
end

function EnemyCorruptedGolem:AttackBoulders()
	for _, target in pairs(self:GetClass("Legend").Instances) do
		local position = target:GetFootPosition()
		local duration = 1
		
		self:Telegraph{
			Position = position,
			Radius = 12,
			Duration = duration,
			Sound = self.EnemyData.Sounds.Rumble,
		}
		self:GetService("EffectsService"):RequestEffectAll("DropBoulder", {
			Duration = duration,
			Position = position
		})
		
		self:AnimationPlay("WarCry", nil, nil, 2)
		
		self.StateMachine:ChangeState("Resting", {
			NextState = "Chasing",
			Duration = 0.5,
		})
	end
end

function EnemyCorruptedGolem:AttackShockwave()
	self:AnimationPlay("GolemPunchRight", nil, nil, 1 / 0.75)
	
	local here = self:GetFootPosition()
	local there =
		self.Target:GetFootPosition() +
		self.Target.Root.Velocity * 1.5
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local direction = delta.Unit
	
	self:FaceTowards(there)
	
	for step = 0, 3 do
		local position = here + direction * 12 * step
		local pause = step * 0.1
		
		delay(pause, function()
			self:Telegraph{
				Position = position,
				Radius = 8,
				Duration = 0.75,
			}
		end)
	end
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Chasing",
		Duration = 1.25
	})
end

function EnemyCorruptedGolem:AttackRoll()
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local midpoint = here + (delta / 2)
	local cframe = CFrame.new(midpoint, here)
	local width = 8
	local length = delta.Magnitude
	
	local speed = 128
	local rollTime = length / speed
	
	local duration = 1
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Chasing",
		Duration = duration + rollTime + 0.1,
	})
	
	self:FaceTowards(there)
	
	self:AnimationPlay("GolemRoll", nil, nil, 3)
	
	self:AttackSquare{
		CFrame = cframe,
		Width = width,
		Length = length,
		Duration = duration,
		OnHit = function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage,
				Type = "Bludgeoning",
			}
		end,
		Sound = self.EnemyData.Sounds.Smash,
	}
	
	delay(duration, function()
		self:TweenNetwork{
			Object = self.Root,
			Goals = {CFrame = self.Root.CFrame + delta},
			Duration = rollTime,
			Style = Enum.EasingStyle.Linear,
		}
		wait(rollTime)
		self:AnimationStop("GolemRoll")
	end)
end

function EnemyCorruptedGolem:GetRandomPointInArena()
	local dungeon = self:GetService("GameService").CurrentRun.Dungeon
	local center = dungeon.Model.Center.Position
	
	local radius = 60
	local radiusSq = radius ^ 2
	local delta
	repeat
		local dx = -radius + radius * 2 * math.random()
		local dz = -radius + radius * 2 * math.random()
		delta = Vector3.new(dx, 0, dz)
		local distanceSq = dx ^ 2 + dz ^ 2
	until distanceSq <= radiusSq
	
	return center + delta
end

function EnemyCorruptedGolem:RockfallDropBoulder()
	local duration = 1.5
	local position = self:GetRandomPointInArena()
	
	self:Telegraph{
		Position = position,
		Radius = 8,
		Duration = duration,
		Sound = self.EnemyData.Sounds.Smash2,
	}
	self:GetService("EffectsService"):RequestEffectAll("DropBoulder", {
		Duration = duration,
		Position = position
	})
end
function EnemyCorruptedGolem:RockfallLoop(count)
	spawn(function()
		for _ = 1, count do
			wait(0.3 * math.random())
			self:RockfallDropBoulder()
		end
	end)
end

function EnemyCorruptedGolem:AttackSlam()
	local duration = 2
	
	self:AnimationPlay("GolemSmash", nil, nil, 1 / duration)
	
	self:Telegraph{
		Position = self:GetFootPosition(),
		Duration = duration,
		Radius = 32,
		Sound = self.EnemyData.Sounds.Rumble2,
	}
	
	delay(duration, function()
		self:RockfallLoop(32)
	end)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Chasing",
		Duration = duration,
	})
end

function EnemyCorruptedGolem:AttackSummon()
	local crystal = self:CreateNew"Enemy"{
		Name = "Corruption Crystal",
		EnemyData = self.Storage.Enemies["Corruption Crystal"],
		StartCFrame = CFrame.new(self:GetRandomPointInArena()),
	}
	crystal.Model.Beam.Attachment1 = self.Model.PrimaryCrystal.Attachment
	
	local onUpdated = crystal.OnUpdated
	crystal.OnUpdated = function(crystal, dt)
		onUpdated(crystal, dt)
		self.Health = math.clamp(self.Health + 20 * dt, 0, self.MaxHealth:Get())
	end
	
	crystal.Destroyed:Connect(function()
		if not (crystal.Model and crystal.Model:FindFirstChild("Beam")) then return end
		crystal.Model.Beam:Destroy()
	end)
	
	self:GetWorld():AddObject(crystal)
	
	local effects = self:GetService("EffectsService")
	effects:RequestEffectAll("Sound", {
		Position = crystal:GetPosition(),
		Sound = self.EnemyData.Sounds.Cast,
	})
	effects:RequestEffectAll("AirBlast", {
		Position = crystal:GetPosition(),
		Color = Color3.fromRGB(61, 21, 133),
		Radius = 32,
		Duration = 1,
	})
end

function EnemyCorruptedGolem:Flinch()
	-- don't
end

function EnemyCorruptedGolem:IsTargetValid()
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

function EnemyCorruptedGolem:CreateStateMachine()
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
			self:AnimationPlay("GolemRoll", nil, nil, 1)
		end,
		
		Run = function(state, machine, dt)
			self.Frustration = self.Frustration + dt
			if self.Frustration > self.FrustrationMax then
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
			
			if attack == "Slam" or attack == "Roll" then
				range = 32
			elseif attack == "Boulders" or attack == "Shockwave" then
				range = 64
			elseif attack == "Summon" then
				range = 128
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
			self:AnimationStop("GolemRoll")
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

return EnemyCorruptedGolem