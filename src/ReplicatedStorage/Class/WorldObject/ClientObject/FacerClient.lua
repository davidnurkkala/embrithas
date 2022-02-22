local UIS = game:GetService("UserInputService")

local Super = require(script.Parent)
local FacerClient = Super:Extend()

function FacerClient:OnCreated()
	self:ConnectRemote("FacePartCalled", self.OnFacePartCalled, false)
	self:ConnectRemote("FaceDirectionCalled", self.OnFaceDirectionCalled, false)
	
	self:GetWorld():AddObject(self)
end

function FacerClient:GetCharacter()
	local player = game.Players.LocalPlayer
	if not player then return end
	
	return player.Character
end

function FacerClient:GetRoot()
	local character = self:GetCharacter()
	if not character then return end
	
	return character:FindFirstChild("HumanoidRootPart")
end

function FacerClient:GetHumanoid()
	local character = self:GetCharacter()
	if not character then return end
	
	return character:FindFirstChild("Humanoid")
end

function FacerClient:TrySetAutoRotate(bool)
	local humanoid = self:GetHumanoid()
	if not humanoid then return end
	
	humanoid.AutoRotate = bool
end

function FacerClient:TwistWaist(override)
	local char = self:GetCharacter()
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local upperTorso = char:FindFirstChild("UpperTorso")
	if not upperTorso then return end
	local lowerTorso = char:FindFirstChild("LowerTorso")
	if not lowerTorso then return end
	local waist = upperTorso:FindFirstChild("Waist")
	if not waist then return end
	local twist = lowerTorso:FindFirstChild("Root")
	if not twist then return end
	local animate = char:FindFirstChild("Animate")
	if not animate then return end
	local speedValue = animate:FindFirstChild("Speed")
	if not speedValue then return end
	
	if not self.WaistC0 then
		self.WaistC0 = waist.C0
	end
	if not self.TwistC0 then
		self.TwistC0 = twist.C0
	end
	if not self.WaistAngle then
		self.WaistAngle = 0
		self.WaistAngleGoal = 0
	end
	
	-- tothetix was here 12/11/2020
	-- A11Noob was here 12/11/2020
	-- tothetix was here 12/11/2020
	local function setAngle(angle)
		while angle < 0 do
			angle += math.pi * 2
		end
		self.WaistAngleGoal = angle
	end
	
	if override then
		setAngle(override)
	elseif humanoid.MoveDirection:FuzzyEq(Vector3.new()) then
		setAngle(0)
	else
		local vector = root.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
		local angle = math.atan2(-vector.Z, vector.X) - (math.pi / 2)
		setAngle(angle)
	end
	
	-- angle
	local angle do
		local backwards = false
		local goal = self.WaistAngleGoal
		if (goal > math.pi * 0.5) and (goal < math.pi * 1.5) then
			goal += math.pi
			backwards = true
		end
		
		angle = goal

		twist.C0 = self.TwistC0 * CFrame.Angles(0, angle, 0)
		waist.C0 = self.WaistC0 * CFrame.Angles(0, -angle, 0)
		
		speedValue.Value = backwards and -1 or 1
	end
end

function FacerClient:OnUpdated(dt)
	self:TrySetAutoRotate(false)
	
	local root = self:GetRoot()
	if not root then return end
	
	local y = root.Position.Y - 2.5
	
	local mouseLocation = UIS:GetMouseLocation()
	local ray = workspace.CurrentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

	local t = (ray.Origin.Y - y) / ray.Direction.Y
	local x = ray.Origin.X - ray.Direction.X * t
	local z = ray.Origin.Z - ray.Direction.Z * t
	
	local position = Vector3.new(x, y, z)
	
	self:FireRemote("AimPositionUpdated", position)
	
	if root.Parent and root.Parent:FindFirstChild("IsDead") then return end
	
	if self.DirectionTimeline or self.Timeline then
		self:TwistWaist(0)
		return
	end
	
	local direction = (position - root.Position).Unit
	local up = Vector3.new(0, 1, 0)
	local right = direction:Cross(up)
	local forward = right:Cross(up)
	local p = root.Position

	root.CFrame = CFrame.new(
		p.X, p.Y, p.Z,
		right.X, up.X, forward.X,
		right.Y, up.Y, forward.Y,
		right.Z, up.Z, forward.Z
	)
	
	self:TwistWaist()
end

function FacerClient:OnFaceDirectionCalled(direction, duration)
	if self.DirectionTimeline then
		self.DirectionTimeline.Direction = direction
		self.DirectionTimeline:Restart(duration)
	else
		self.DirectionTimeline = self:CreateNew"Timeline"{
			Time = duration,
			Direction = direction,
			
			SetCFrame = function(t)
				local root = self:GetRoot()
				if not root then return end
				
				local up = Vector3.new(0, 1, 0)
				local right = t.Direction:Cross(up)
				local forward = right:Cross(up)
				local p = root.Position
				
				root.CFrame = CFrame.fromMatrix(p, right, up, forward)
			end,
			OnStarted = function(t)
				self:TrySetAutoRotate(false)
				t:SetCFrame()
			end,
			OnTicked = function(t, dt)
				t:SetCFrame()
			end,
			OnEnded = function(t)
				self:TrySetAutoRotate(true)
				self.DirectionTimeline = nil
			end,
		}
		self.DirectionTimeline:Start()
	end
end

function FacerClient:OnFacePartCalled(part, duration)
	if not part then
		if self.Timeline then
			self.Timeline:Stop()
		end
		
		return
	end
	
	if self.Timeline then
		self.Timeline.Part = part
		self.Timeline:Restart(duration)
	else
		self.Timeline = self:CreateNew"Timeline"{
			Time = duration,
			Part = part,
			SetCFrame = function(t)
				local root = self:GetRoot()
				if not root then return end
				
				local direction = (t.Part.Position - root.Position).unit
				local up = Vector3.new(0, 1, 0)
				local right = direction:Cross(up)
				local forward = right:Cross(up)
				local p = root.Position
				
				root.CFrame = CFrame.new(
					p.X, p.Y, p.Z,
					right.X, up.X, forward.X,
					right.Y, up.Y, forward.Y,
					right.Z, up.Z, forward.Z
				)
			end,
			OnStarted = function(t)
				self:TrySetAutoRotate(false)
				t:SetCFrame()
			end,
			OnTicked = function(t, dt)
				t:SetCFrame()
			end,
			OnEnded = function(t)
				self:TrySetAutoRotate(true)
				self.Timeline = nil
			end,
		}
		self.Timeline:Start()
	end
end

local Singleton = FacerClient:Create()
return Singleton