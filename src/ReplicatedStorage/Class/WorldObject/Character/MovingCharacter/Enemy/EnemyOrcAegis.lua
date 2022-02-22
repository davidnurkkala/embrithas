local Super = require(script.Parent)
local EnemyOrcAegis = Super:Extend()

function EnemyOrcAegis:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Jump",
		"Charge", 3,
		"WarCry",	
	}}
	
	Super.OnCreated(self)
	
	self.Speed.Base = 18
end

function EnemyOrcAegis:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyOrcAegis.DetectionRange = 128

EnemyOrcAegis.JumpLength = 48
EnemyOrcAegis.JumpWidth = 8
EnemyOrcAegis.JumpRange = 64
EnemyOrcAegis.JumpDelay = 1
EnemyOrcAegis.JumpFrustrationLimit = 2
EnemyOrcAegis.JumpFrustration = 0

EnemyOrcAegis.ChargeRange = 32

EnemyOrcAegis.WarCryRange = 20
EnemyOrcAegis.WarCryRadius = 40
EnemyOrcAegis.WarCryDelay = 1.5

EnemyOrcAegis.AirBlastSpeed = 40
EnemyOrcAegis.AirBlastWidth = 8
EnemyOrcAegis.AirBlastRange = 20

function EnemyOrcAegis:AirBlast()
	if not self.Active then return end
	
	local width = self.AirBlastWidth

	local crescent = self.Storage.Models.Crescent:Clone()
	crescent.Size = Vector3.new(width, 0, 4)

	local model = Instance.new("Model")
	crescent.Parent = model
	model.Name = "AirSlice"
	model.PrimaryPart = crescent

	local function launchProjectile()
		local projectile = self:CreateNew"Projectile"{
			Model = model,
			CFrame = self.Root.CFrame * CFrame.new(0, 0, -4),
			Velocity = self.Root.CFrame.LookVector * (self.AirBlastSpeed + self.Root.Velocity.Magnitude),
			FaceTowardsVelocity = true,
			Range = self.AirBlastRange,
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
						self:DamageFunc(1/3, "Slashing")(legend)
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
		effects:RequestEffectAll("Sound", {
			Position = self:GetPosition(),
			Sound = self.EnemyData.Sounds.Bash,
		})
	end
	
	launchProjectile()
end

function EnemyOrcAegis:AttackJump()
	local targetPosition = self.Target:GetFootPosition()
	
	local position
	self:Attempt(8, function()
		local theta = math.pi * 2 * math.random()
		local dx = math.cos(theta) * self.JumpWidth
		local dz = math.sin(theta) * self.JumpWidth
		position = Vector3.new(
			targetPosition.X + dx,
			0,
			targetPosition.Z + dz
		)
		return self:DoesPointHaveFloor(position, 2)
	end)
	
	local here = self:GetFootPosition()
	local delta = (position - here) * Vector3.new(1, 0, 1)
	
	local cframe = CFrame.new(here + delta, here)
	
	self:AttackSquare{
		CFrame = cframe * CFrame.Angles(0, math.pi / 4, 0),
		Length = self.JumpLength,
		Width = self.JumpWidth,
		Duration = self.JumpDelay,
		OnHit = self:DamageFunc(1, "Bludgeoning")
	}
	self:AttackSquare{
		CFrame = cframe * CFrame.Angles(0, -math.pi / 4, 0),
		Length = self.JumpLength,
		Width = self.JumpWidth,
		Duration = self.JumpDelay,
		OnHit = self:DamageFunc(1, "Bludgeoning"),
	}
	
	self:FaceTowards(position)
	
	delay(self.JumpDelay - (24/30), function()
		self:AnimationPlay("OrcHeavyBulwarkJump")
		
		wait(14/30)
		
		self:TweenNetwork{
			Object = self.Root,
			Goals = {CFrame = self.Root.CFrame + delta},
			Duration = (10/30),
			Direction = Enum.EasingDirection.In,
			Style = Enum.EasingStyle.Quint,
		}
		
		wait(12/30)
		
		self:AirBlast()
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = self.JumpDelay + 0.1,
		NextState = "Waiting",
	})
end

function EnemyOrcAegis:AttackCharge()
	local duration = 2.3
	
	self:AnimationPlay("OrcHeavyBulwarkCharge")
	
	local here = self:GetPosition()
	local there = self.Target:GetPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local direction = delta.Unit
	
	self:CreateNew"Timeline"{
		Time = duration,
		OnTicked = function()
			local ray = Ray.new(self:GetPosition(), direction * 4)
			local part, _, normal = self:Raycast(ray)
			if part then
				self:MoveStop()
			else
				self:MoveTo(self:GetPosition() + direction * 16)
			end
		end
	}:Start()
	
	local function getCFrame()
		local here = self:GetFootPosition() + direction * 4
		return CFrame.new(here, here + direction)
	end
	self:TelegraphDirectional{
		Duration = 25/30,
		CFrame = getCFrame(),
		Length = 4,
		Width = 8,
		OnTicked = function(t)
			t:UpdateCFrame(getCFrame())
		end,
		Callback = function()
			self:AirBlast()
			wait(13/30)
			self:AirBlast()
			wait(12/30)
			self:AirBlast()
		end
	}
	
	self.StateMachine:ChangeState("Resting", {
		Duration = duration,
		NextState = "Waiting",
	})
end

function EnemyOrcAegis:AttackWarCry()
	self:AttackCircle{
		Position = self:GetFootPosition(),
		Radius = self.WarCryRadius,
		Duration = self.WarCryDelay,
		Color = Color3.new(1, 1/3, 0),
		OnHit = function(character)
			character:AddStatus("StatusSlowed", {
				Time = 2.5,
				Percent = 0.33,
			})
		end,
	}
	
	local animWindup = 11/30
	delay(self.WarCryDelay - animWindup, function()
		self:AnimationPlay("OrcHeavyBulwarkShout")
		wait(animWindup)
		self:SoundPlay("Scream")
		self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
			Position = self:GetFootPosition(),
			Radius = self.WarCryRadius,
			Duration = 0.25,
			Color = Color3.new(1, 1, 1),
		})
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = self.WarCryDelay + 0.5,
		NextState = "Waiting",
	})
end

function EnemyOrcAegis:Flinch()
	-- don't
end

function EnemyOrcAegis:IsTargetValid()
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

function EnemyOrcAegis:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if self:IsTargetValid() then
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
			self:AnimationPlay("RunSingleWeapon")
			self.JumpFrustration = 0
		end,
		
		Run = function(state, machine, dt)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			self:MoveTo(targetPosition)
			
			self.JumpFrustration = self.JumpFrustration + dt
			if self.JumpFrustration > self.JumpFrustrationLimit then
				self.AttackPattern:Reset()
				self.JumpFrustration = 0
			end
			
			local attack = self.AttackPattern:Get()
			local range
			if attack == "Jump" then
				range = self.JumpRange
			elseif attack == "Charge" then
				range = self.ChargeRange
			elseif attack == "WarCry" then
				range = self.WarCryRange
			end
			
			if distance < range then
				self["Attack"..attack](self)
				self.AttackPattern:Next()
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop("RunSingleWeapon")
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

return EnemyOrcAegis