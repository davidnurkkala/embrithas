function ragdoll(Character)
	local Humanoid = Character:WaitForChild("Humanoid")
	
	local Root = Character:WaitForChild("HumanoidRootPart")
	local LowerTorso = Character:WaitForChild("LowerTorso")
	local RootMotor = LowerTorso:WaitForChild("Root")
	
	local VectorsByDirection = {
		Up = Vector3.new(0, 1, 0),
		Down = Vector3.new(0, -1, 0),
		Left = Vector3.new(-1, 0, 0),
		Right = Vector3.new(1, 0, 0),
		Forward = Vector3.new(0, 0, -1),
		Back = Vector3.new(0, 0, 1),
	}
	
	--this order is in expanding order from the root part
	--ensures that we always get the same "direction"
	--on joints (necessary for saddle joint constructs)
	local PartNamesInOrder = {
		"HumanoidRootPart",
		"LowerTorso",
		"UpperTorso",
		"RightUpperLeg",
		"LeftUpperLeg",
		"Head",
		"RightUpperArm",
		"LeftUpperArm",
		"RightLowerLeg",
		"LeftLowerLeg",
		"RightLowerArm",
		"LeftLowerArm",
		"RightFoot",
		"LeftFoot",
		"RightHand",
		"LeftHand",
	}
	
	local function makeAttachment(parent, name, position, primaryAxisDirection, secondaryAxisDirection)
		local attachment = Instance.new("Attachment")
		attachment.Name = name
		
		attachment.Axis = VectorsByDirection[primaryAxisDirection]
		attachment.SecondaryAxis = VectorsByDirection[secondaryAxisDirection]
		attachment.Position = position
		
		attachment.Parent = parent
		
		return attachment
	end
	
	local function iterateParts(callback)
		for index = 1, #PartNamesInOrder do
			local partName = PartNamesInOrder[index]
			local part = Character[partName]
			callback(part)
		end
	end
	
	local function getJointAttachments(jointName)
		local attachments = {}
		iterateParts(function(part)
			local attachment = part:FindFirstChild(jointName.."RigAttachment")
			if attachment then
				table.insert(attachments, attachment)
			end
		end)
		return attachments
	end
	
	local function makeHinge(jointName, primaryAxisDirection, secondaryAxisDirection, lowerAngle, upperAngle)
		local attachments = {}
		for _, attachment in pairs(getJointAttachments(jointName)) do
			local part = attachment.Parent
			table.insert(
				attachments,
				makeAttachment(part, part.Name..jointName.."RagdollAttachment", attachment.Position, primaryAxisDirection, secondaryAxisDirection)
			)
		end
		
		local hinge = Instance.new("HingeConstraint")
		hinge.Name = jointName.."RagdollHinge"
		hinge.Attachment0 = attachments[1]
		hinge.Attachment1 = attachments[2]
		hinge.LimitsEnabled = true
		hinge.UpperAngle = upperAngle
		hinge.LowerAngle = lowerAngle
		hinge.Parent = Character
	end
	
	local function makeSocket(jointName, primaryAxisDirection, secondaryAxisDirection, angle)
		local attachments = {}
		for _, attachment in pairs(getJointAttachments(jointName)) do
			local part = attachment.Parent
			table.insert(
				attachments,
				makeAttachment(part, part.Name..jointName.."RagdollAttachment", attachment.Position, primaryAxisDirection, secondaryAxisDirection)
			)
		end
		
		local socket = Instance.new("BallSocketConstraint")
		socket.Name = jointName.."RagdollBallSocket"
		socket.Attachment0 = attachments[1]
		socket.Attachment1 = attachments[2]
		socket.LimitsEnabled = true
		socket.UpperAngle = angle
		socket.Parent = Character
	end
	
	local function findCharacterAttachment(name)
		local retAttachment
		
		iterateParts(function(part)
			local attachment = part:FindFirstChild(name)
			if attachment and attachment:IsA("Attachment") then
				retAttachment = attachment
			end
		end)
		
		return retAttachment
	end
	
	local function iterateAccessories(callback)
		for _, object in pairs(Character:GetChildren()) do
			if object:IsA("Accessory") then
				callback(object)
			end
		end
	end
	
	local function fixAccessories()
		iterateAccessories(function(accessory)
			local handle = accessory:FindFirstChild("Handle")
			if not handle then return end
			handle.Size = Vector3.new()
			
			local attachment = handle:FindFirstChildOfClass("Attachment")
			if not attachment then return end
			
			local otherAttachment = findCharacterAttachment(attachment.Name)
			if not otherAttachment then return end
			
			local w = Instance.new("Weld")
			w.Part0 = otherAttachment.Parent
			w.Part1 = handle
			w.C0 = otherAttachment.CFrame
			w.C1 = attachment.CFrame
			w.Parent = w.Part0
		end)
	end
	
	local function fixRootPart()
		Root.CanCollide = false
		
		local w = Instance.new("Weld")
		w.Part0 = LowerTorso
		w.Part1 = Root
		w.C0 = RootMotor.C0
		w.C1 = RootMotor.C1
		w.Parent = w.Part0
		
		local function onCanCollideChanged()
			if Root.CanCollide then
				Root.CanCollide = false
			end
		end
		local signal = Root:GetPropertyChangedSignal("CanCollide")
		signal:connect(onCanCollideChanged)
	end
	
	if not Root:IsDescendantOf(workspace) then return end
	
	Character:BreakJoints()
	
	fixRootPart()
	
	makeSocket("Neck", "Up", "Forward", 45)
	
	makeSocket("RightShoulder", "Right", "Up", 90)
	makeSocket("LeftShoulder", "Left", "Up", 90)
	
	makeSocket("RightWrist", "Down", "Right", 20)
	makeSocket("LeftWrist", "Down", "Left", 20)
	
	makeHinge("Waist", "Right", "Up", -90, 90)
	
	makeHinge("RightElbow", "Right", "Down", 0, 135)
	makeHinge("LeftElbow", "Left", "Down", -135, 0)
	
	makeHinge("RightKnee", "Right", "Down", -135, 0)
	makeHinge("LeftKnee", "Left", "Down", 0, 135)
	
	makeSocket("RightHip", "Down", "Right", 20)
	makeSocket("LeftHip", "Down", "Left", 20)
	
	makeSocket("RightAnkle", "Down", "Right", 20)
	makeSocket("LeftAnkle", "Down", "Left", 20)
	
	makeSocket("Root", "Right", "Forward", 90)
	
	fixAccessories()
	
	local function die(state)
		if state ~= Enum.HumanoidStateType.Dead then
			Humanoid.Health = -100
			Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
		end
	end
	local heartbeat do
		heartbeat = game:GetService("RunService").Heartbeat:Connect(function()
			if Humanoid.Parent then
				die()
			else
				heartbeat:Disconnect()
			end
		end)
	end
	
	local sign = (math.random(1, 2) == 1) and -1 or 1
	Root.RotVelocity = Vector3.new(0, math.random(0, 360) * sign, 0)
end

return ragdoll