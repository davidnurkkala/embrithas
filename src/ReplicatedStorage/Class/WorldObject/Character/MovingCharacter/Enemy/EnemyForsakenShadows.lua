local Super = require(script.Parent)
local EnemyForsakenShadows = Super:Extend()

EnemyForsakenShadows.Resilient = true

function EnemyForsakenShadows:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
			"Dash", 3,
			"Slash", 2,
			"Dash", 3,
			"Slash", 2,
			"Assassinate",
	}}
	
	Super.OnCreated(self)
	
	self:GetService("MusicService"):PlayPlaylist{"Long Dark Shadow"}
end

function EnemyForsakenShadows:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	self.StateMachine:Run(dt)
end

EnemyForsakenShadows.DetectionRange = 128
EnemyForsakenShadows.AttackRange = 12

EnemyForsakenShadows.Frustration = 0
EnemyForsakenShadows.FrustrationLimit = 2

EnemyForsakenShadows.DashLength = 40
EnemyForsakenShadows.DashWidth = 8
EnemyForsakenShadows.DashDelay = 0.8

EnemyForsakenShadows.SlashRadius = 10
EnemyForsakenShadows.SlashDelay = 0.8

EnemyForsakenShadows.AssassinateCount = 20
EnemyForsakenShadows.AssassinateLength = 32
EnemyForsakenShadows.AssassinateWidth = 8
EnemyForsakenShadows.AssassinateDelay = 0.8

function EnemyForsakenShadows:AttackDash()
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local part, point = self:Raycast(Ray.new(self:GetPosition(), delta.Unit * self.DashLength))
	there = point
	delta = (there - here) * Vector3.new(1, 0, 1)
	local midpoint = here + delta / 2
	local cframe = CFrame.new(midpoint, here)
	local length = delta.Magnitude
	if part then
		length = length - 2
	end
	
	self:AttackSquare{
		CFrame = cframe,
		Width = self.DashWidth,
		Length = length,
		Duration = self.DashDelay,
		OnHit = function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage,
				Type = "Piercing",
			}
		end,
	}
	
	self:FaceTowards(there)
	
	self:AnimationPlay("ShadowBroDash", nil, nil, 1 / self.DashDelay)
	
	delay(self.DashDelay, function()
		self:TweenNetwork{
			Object = self.Root,
			Goals = {CFrame = self.Root.CFrame + delta.Unit * length},
			Duration = 0.1,
			Style = Enum.EasingStyle.Linear,
		}
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = self.DashDelay + 0.1,
		NextState = "Waiting",
	})
end

function EnemyForsakenShadows:AttackSlash()
	local position = self.Target:GetFootPosition()
	local teleportPosition
	
	self:Attempt(8, function()
		local theta = math.pi * 2 * math.random()
		local dx = math.cos(theta) * self.SlashRadius
		local dz = math.sin(theta) * self.SlashRadius
		teleportPosition = position + Vector3.new(dx, 0, dz)
		return self:DoesPointHaveFloor(teleportPosition, 2)
	end)
	
	self:AttackCircle{
		Position = position,
		Radius = self.SlashRadius,
		Duration = self.SlashDelay,
		OnHit = function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage,
				Type = "Slash",
			}
		end,
	}
	
	local delta = (teleportPosition - self:GetPosition()) * Vector3.new(1, 0, 1)
	
	self:FaceTowards(self:GetPosition() + (position - teleportPosition))
	self:AnimationPlay("ShadowBroSlash", nil, nil, 1 / self.SlashDelay)
	
	self:TweenNetwork{
		Object = self.Root,
		Goals = {CFrame = self.Root.CFrame + delta},
		Duration = 0.1,
		Style = Enum.EasingStyle.Linear,
	}
	
	self.StateMachine:ChangeState("Resting", {
		Duration = self.SlashDelay + 0.1,
		NextState = "Waiting",
	})
end

function EnemyForsakenShadows:AttackAssassinate()
	local function slash()
		local targets = self:GetClass("Legend").Instances
		if #targets == 0 then return end
		local target = targets[math.random(1, #targets)]
		
		local position = target:GetFootPosition()
		local rotation = math.pi * 2 * math.random()
		local cframe = CFrame.new(position) * CFrame.Angles(0, rotation, 0)
		local start = (cframe * CFrame.new(0, 0, self.AssassinateLength / 2)).Position
		local finish = (cframe * CFrame.new(0, 0, -self.AssassinateLength / 2)).Position
		
		self:AttackSquare{
			CFrame = cframe,
			Width = self.AssassinateWidth,
			Length = self.AssassinateLength,
			Duration = self.AssassinateDelay,
			OnHit = function(legend)
				self:GetService"DamageService":Damage{
					Source = self,
					Target = legend,
					Amount = self.Damage,
					Type = "Piercing",
				}
			end,
		}
		
		wait(self.AssassinateDelay)
		
		local delta = (start - self:GetPosition()) * Vector3.new(1, 0, 1)
		self.Root.CFrame = self.Root.CFrame + delta
		self:FaceTowards(finish)
		
		self:SetHidden(false)
		
		self:TweenNetwork{
			Object = self.Root,
			Goals = {CFrame = self.Root.CFrame + (finish - start)},
			Duration = 0.1,
			Style = Enum.EasingStyle.Linear
		}
		
		wait(0.1)
		
		self:SetHidden(true)
	end
	
	local position = self:GetPosition()
	self:SetHidden(true)
	self.Root.Anchored = true
	self:AnimationPlay("ShadowBroDashPoseLoop")
	
	local pause = 0.15
	
	for slashNumber = 0, self.AssassinateCount - 1 do
		delay(pause * slashNumber, function()
			slash()
		end)
	end
	
	local totalTime = self.AssassinateDelay + pause * self.AssassinateCount + 0.5 
	
	delay(totalTime, function()
		local delta = position - self.Root.Position
		self.Root.CFrame = self.Root.CFrame + delta
		self:SetHidden(false)
		self.Root.Anchored = false
		self:AnimationStop("ShadowBroDashPoseLoop")
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = totalTime + 2,
		NextState = "Waiting",
	})
end

function EnemyForsakenShadows:Flinch()
	-- don't
end

function EnemyForsakenShadows:IsTargetValid()
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

function EnemyForsakenShadows:CreateStateMachine()
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
			
			if attack == "Dash" then
				range = 40
			elseif attack == "Slash" then
				range = 20
			elseif attack == "Assassinate" then
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

return EnemyForsakenShadows