local Super = require(script.Parent)
local MovingCharacter = Super:Extend()

local EffectsService = MovingCharacter:GetClass"EffectsService"

function MovingCharacter:OnCreated()
	Super.OnCreated(self)
	
	self.Root = self.Model.PrimaryPart
	self.AnimationController = self.Model.AnimationController
	
	self.Speed = self:CreateNew"Stat"{Base = 16}
	
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e8, 0, 1e8)
	bodyVelocity.Parent = self.Root
	self.BodyVelocity = bodyVelocity
	
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.D /= 4
	bodyGyro.P *= 2
	bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
	bodyGyro.CFrame = self.Root.CFrame
	bodyGyro.Parent = self.Root
	self.BodyGyro = bodyGyro
	
	self.Dashing = false
	self.DashDuration = 0
	self.DashVelocity = Vector3.new()
	
	self.StatusAdded:Connect(function(status)
		if status.Type == "Stunned" then
			self:MoveStop()
		end
	end)
end

function MovingCharacter:InitHitbox()
	local hitboxHeight = 8
	local modelCFrame, modelSize = self.Model:GetBoundingBox()
	local torsoSize = (self.Model:FindFirstChild("UpperTorso") or self.Root).Size
	local hitboxWidth = math.max(torsoSize.X, torsoSize.Y, torsoSize.Z)
	
	local modelBottom = modelCFrame * CFrame.new(0, -modelSize.Y / 2, 0)
	local bottomBeneathRoot = self.Root.CFrame + Vector3.new(0, modelBottom.Position.Y - self.Root.Position.Y, 0)
	local hitboxCFrame = bottomBeneathRoot * CFrame.new(0, hitboxHeight / 2, 0) * CFrame.Angles(0, 0, math.pi / 2)
	
	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Shape = Enum.PartType.Cylinder
	hitbox.Size = Vector3.new(hitboxHeight, hitboxWidth, hitboxWidth)
	hitbox.Massless = true
	hitbox.Transparency = 1
	hitbox.CanCollide = true
	hitbox.TopSurface = Enum.SurfaceType.Smooth
	hitbox.BottomSurface = Enum.SurfaceType.Smooth
	
	local weld = Instance.new("Weld")
	weld.Part0 = self.Root
	weld.Part1 = hitbox
	weld.C0 = self.Root.CFrame:ToObjectSpace(hitboxCFrame)
	weld.Parent = hitbox
	
	hitbox.Parent = self.Model
	self.Hitbox = hitbox
end

function MovingCharacter:GetRootHeight()
	local rootPosition = self.Hitbox.CFrame:PointToObjectSpace(self.Root.Position)
	local hitboxBottom = -self.Hitbox.Size.Y / 2
	return rootPosition.Y - hitboxBottom
end

function MovingCharacter:Dash(velocity, duration)
	self.BodyVelocity.Velocity = self.DashVelocity
	self.DashVelocity = velocity
	self.DashDuration = duration
	self.Dashing = true
end

function MovingCharacter:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Dashing then
		self.BodyVelocity.Velocity = self.DashVelocity
		self.DashDuration = self.DashDuration - dt
		if self.DashDuration <= 0 then
			self.Dashing = false
			self.BodyVelocity.Velocity = Vector3.new()
		end
	else
		if self.Destination then
			local delta = (self.Destination - self.Root.Position) * Vector3.new(1, 0, 1)
			local sqDistance = (delta.X ^ 2 + delta.Z ^ 2)
			if sqDistance <= 1 then
				self.Destination = nil
				self.BodyVelocity.Velocity = Vector3.new()
			else
				local speed = math.max(1, self.Speed:Get())
				self.BodyVelocity.Velocity = (delta / math.sqrt(sqDistance)) * speed
				
				if not self.FacingPoint then
					self.BodyGyro.CFrame = CFrame.new(Vector3.new(), delta)
				end
			end
		else
			self.BodyVelocity.Velocity = Vector3.new()
		end
		
		if self.FacingPoint then
			local here = self:GetPosition()
			local there = self.FacingPoint
			local delta = (there - here) * Vector3.new(1, 0, 1)
			self.BodyGyro.CFrame = CFrame.new(Vector3.new(), delta)
		end
	end
	
	self.BodyVelocity.Velocity = Vector3.new(
		self.BodyVelocity.Velocity.X,
		-4,
		self.BodyVelocity.Velocity.Z
	)
end

function MovingCharacter:AnimationLoad(name)
	local animation = self.Storage.Animations:FindFirstChild(name, true)
	spawn(function() game:GetService("ContentProvider"):PreloadAsync({animation.AnimationId}) end)
end

function MovingCharacter:AnimationPlay(name, ...)
	if not self.Tracks then
		self.Tracks = {}
	end
	if not self.Tracks[name] then
		local animation = self.Storage.Animations:FindFirstChild(name, true)
		self.Tracks[name] = self.AnimationController:LoadAnimation(animation)
	end
	self.Tracks[name]:Play(...)
end

function MovingCharacter:AnimationStop(name, ...)
	if self.Tracks and self.Tracks[name] then
		self.Tracks[name]:Stop(...)
	end
end

function MovingCharacter:MoveTo(position)
	self.Destination = position
end

function MovingCharacter:MoveStop()
	self.Destination = nil
	self.BodyVelocity.Velocity = Vector3.new()
end

function MovingCharacter:Flinch()
	self:AnimationPlay("GenericFlinch", 0)
end

function MovingCharacter:OnDamaged(damage)
	Super.OnDamaged(self, damage)
	
	self:Flinch()
end

function MovingCharacter:Ragdoll()
	local constraints = Instance.new("Folder")
	constraints.Name = "Constraints"
	constraints.Parent = self.Model
	
	for _, desc in pairs(self.Model:GetDescendants()) do
		if desc:IsA("Motor6D") then
			local motor = desc
			
			local attachmentA = Instance.new("Attachment")
			attachmentA.CFrame = motor.C0
			attachmentA.Parent = motor.Part0
			
			local attachmentB = Instance.new("Attachment")
			attachmentB.CFrame = motor.C1
			attachmentB.Parent = motor.Part1
			
			local ballAndSocket = Instance.new("BallSocketConstraint")
			ballAndSocket.Attachment0 = attachmentA
			ballAndSocket.Attachment1 = attachmentB
			ballAndSocket.Parent = constraints
			
			motor:Destroy()
		end
		
		if desc:IsA("BasePart") then
			desc.CanCollide = true
		end
	end
	
	self.BodyVelocity:Destroy()
	self.BodyGyro:Destroy()
	
	self.Root.Velocity = self.Root.CFrame.LookVector * -320
	self.Root.RotVelocity = Vector3.new(0, math.random(90, 360), 0)
end

function MovingCharacter:FaceTowards(point)
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
	self.BodyGyro.CFrame = self.Root.CFrame
end

return MovingCharacter
