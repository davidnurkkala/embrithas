local Super = require(script.Parent)
local HumanoidCharacter = Super:Extend()

function HumanoidCharacter:OnCreated()
	Super.OnCreated(self)
	
	self.Humanoid = self.Model.Humanoid
	self.Root = self.Model.HumanoidRootPart
	
	local Stat = self:GetClass"Stat"
	
	self.Speed = Stat:Create{Base = 16}
	self.JumpPower = Stat:Create{Base = 0}
	
	-- get rid of the basic humanoid stuff
	self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	self.Humanoid.BreakJointsOnDeath = false
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	
	self.Root.CanCollide = true
end

function HumanoidCharacter:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	--self.Humanoid.MaxHealth = self.MaxHealth:Get()
	--self.Humanoid.Health = math.max(1, self.Health)
	self.Humanoid.JumpPower = self.JumpPower:Get()
	
	local speed = self.Speed:Get()
	if self:HasStatusType("Stunned") then
		speed = 0
	end
	speed = math.clamp(speed, 0, 128)
	self.Humanoid.WalkSpeed = speed
end

function HumanoidCharacter:AnimationPlay(name, ...)
	if not self.Tracks then
		self.Tracks = {}
	end
	if not self.Tracks[name] then
		local animation = self.Storage.Animations:FindFirstChild(name, true)
		self.Tracks[name] = self.Humanoid:LoadAnimation(animation)
	end
	self.Tracks[name]:Play(...)
end

function HumanoidCharacter:AnimationStop(name, ...)
	if self.Tracks and self.Tracks[name] then
		self.Tracks[name]:Stop(...)
	end
end

function HumanoidCharacter:MoveTo(...)
	self.Humanoid:MoveTo(...)
end

function HumanoidCharacter:MoveStop()
	self.Humanoid:MoveTo(self:GetPosition())
end

function HumanoidCharacter:OnDamaged(damage)
	Super.OnDamaged(self, damage)
	
	self:AnimationPlay("GenericFlinch", 0)
end

function HumanoidCharacter:Ragdoll()
	require(self.Storage.Scripts.GetRagdollFunction)(self.Model)
end

function HumanoidCharacter:FaceTowards(point)
	local direction = (point - self.Root.Position).unit
	local up = Vector3.new(0, 1, 0)
	local right = direction:Cross(up)
	local forward = right:Cross(up)
	local p = self.Root.Position
	
	self.Root.CFrame = CFrame.new(
		p.X, p.Y, p.Z,
		right.X, up.X, forward.X,
		right.Y, up.Y, forward.Y,
		right.Z, up.Z, forward.Z
	)
end

function HumanoidCharacter:SetCollisionGroup(groupName)
	self.CollisionGroup = groupName
	
	local physicsService = game:GetService("PhysicsService")
	for _, object in pairs(self.Model:GetDescendants()) do
		if object:IsA("BasePart") then
			if object == self.Root then
				physicsService:SetPartCollisionGroup(object, groupName)
			else
				physicsService:SetPartCollisionGroup(object, (groupName == "Debris") and "Debris" or "None")
			end
		end
	end
end

return HumanoidCharacter
