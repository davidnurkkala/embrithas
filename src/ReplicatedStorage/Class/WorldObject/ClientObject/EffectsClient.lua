local Debris = game:GetService("Debris")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")

local Super = require(script.Parent)
local EffectsClient = Super:Extend()

function EffectsClient:OnCreated()
	self.Player = game:GetService("Players").LocalPlayer
	
	self:ConnectRemote("EffectRequested", self.OnEffectRequested, false)
	self:ConnectRemote("EffectCanceled", self.OnEffectCanceled, false)
	self:ConnectRemote("EffectChanged", self.OnEffectChanged, false)
	self.Effects = {}
end

function EffectsClient:OnEffectRequested(name, args)
	local methodName = "Effect"..name
	if not self[methodName] then
		local warning = string.format("Requested an effect that doesn't exist: '%s.'", name)
		warn(warning)
		return
	end
	
	self[methodName](self, args)
end

function EffectsClient:OnEffectCanceled(id)
	self:ForEachWorldObject(self.Effects, function(effect)
		if effect.Id == id then
			self:CancelEffect(effect)
		end
	end)
end

function EffectsClient:CancelEffect(effect)
	effect.Active = false
	
	if effect.OnCanceled then
		effect:OnCanceled()
	end
end

function EffectsClient:OnEffectChanged(id, args)
	self:ForEachWorldObject(self.Effects, function(effect)
		if effect.Id == id then
			self:ChangeEffect(effect, args)
		end
	end)
end

function EffectsClient:ChangeEffect(effect, args)
	if effect.OnChanged then
		effect:OnChanged(args)
	end
end

function EffectsClient:Effect(args)
	local effect = self:CreateNew"Timeline"(args)
	effect:Start()
	table.insert(self.Effects, effect)
	return effect
end

function EffectsClient:GetEffectPart()
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = "Smooth"
	part.BottomSurface = "Smooth"
	part.CastShadow = false
	return part
end

function EffectsClient:ApplyArgs(object, args)
	for key, val in pairs(args) do
		object[key] = val
	end
end

function EffectsClient:EffectActiveCircle(args)
	local position
	
	local part = self.Storage.Models.ActiveCirclePart:Clone()
	part.Size = Vector3.new(2, 0, 2) * args.Radius
	
	local gradient = part.Gui.Circle.Gradient
	
	local bang = self.Storage.Models.TelegraphBang:Clone()
	bang.Size = Vector3.new(1, 0, 1) * args.Radius
	
	local function setBangCFrame()
		local direction = workspace.CurrentCamera.CFrame.upVector
		local up = Vector3.new(0, 1, 0)
		local right = direction:Cross(up)
		local forward = right:Cross(up)
		bang.CFrame = CFrame.new(
			position.X, position.Y, position.Z,
			right.X, up.X, forward.X,
			right.Y, up.Y, forward.Y,
			right.Z, up.Z, forward.Z
		) * CFrame.Angles(0, -math.pi / 2, 0)
	end
	
	local function cleanUp()
		part:Destroy()
		bang:Destroy()
	end
	
	local function setPosition(newPosition)
		position = newPosition
		part.Position = newPosition
		setBangCFrame()
	end
	
	setPosition(args.Position)
	part.Parent = workspace.Effects
	bang.Parent = workspace.Effects
	
	self:Effect{
		Id = args.Id,
		Time = args.Duration,
		Infinite = args.Infinite,
		OnTicked = function(e, dt)
			setBangCFrame()
			
			gradient.Rotation = gradient.Rotation + (360 * dt)
			
			if gradient.Rotation > 360 then
				gradient.Rotation = gradient.Rotation - 360
			end
		end,
		OnEnded = function(e)
			cleanUp()
		end,
		OnChanged = function(e, args)
			if args.Position then
				setPosition(args.Position)
			end
		end,
	}
end

function EffectsClient:EffectChargeIndicator(args)
	local part = self.Storage.Models.ChargeIndicatorPart:Clone()
	local gradient = part.Gui.Circle.Gradient

	local sourcePart = args.SourcePart
	local targetPart = args.TargetPart
	local duration = args.Duration
	local offset = args.Offset
	local id = args.Id

	local function setCFrame()
		local here = (sourcePart.CFrame * offset).Position
		local there = targetPart.Position
		local delta = (there - here) * Vector3.new(1, 0, 1)
		
		part.CFrame = CFrame.new(here, here + delta) * CFrame.Angles(0, -math.pi / 2, 0)
	end

	local function setProgress(p)
		local border = 0.05

		if p == 0 then
			gradient.Transparency = NumberSequence.new(1)
		elseif p == 1 then
			gradient.Transparency = NumberSequence.new(0)
		elseif p < border then
			gradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(p, 1),
				NumberSequenceKeypoint.new(1, 1),
			}
		elseif (1 - p) < border then
			gradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(p, 0),
				NumberSequenceKeypoint.new(1, 1),
			}
		else
			gradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(p, 0),
				NumberSequenceKeypoint.new(p + border, 1),
				NumberSequenceKeypoint.new(1, 1),
			}
		end
	end

	local fadeInTime = 0.1
	part.Gui.Chevron.ImageTransparency = 1
	self:Tween(part.Gui.Chevron, {ImageTransparency = 0}, fadeInTime, Enum.EasingStyle.Linear)

	setCFrame()
	part.Parent = workspace.Effects

	self:Effect{
		Id = id,
		Time = duration,
		OnTicked = function(e)
			setProgress(e:GetProgress())
			setCFrame()
		end,
		OnEnded = function(e)
			setCFrame()
			
			local fadeOutTime = 0.1
			self:Effect{
				Time = fadeOutTime,
				OnTicked = function(e)
					local w = e:GetProgress()
					part.Gui.Chevron.ImageTransparency = w
					part.Gui.Circle.ImageTransparency = w
					setCFrame()
				end,
				OnEnded = function(e)
					part:Destroy()
				end,
			}
		end,
		OnChanged = function(e, args)
			if args.TargetPart then
				targetPart = args.TargetPart
			end
		end
	}
end

function EffectsClient:EffectShowRange(args)
	local model = self.Storage.Models:WaitForChild("RangeVisualizer"):Clone()
	model.Root.Gui.Image.ImageColor3 = args.Color or Color3.new(1, 1, 1)
	model.Root.Gui.Image.ImageTransparency = args.Transparency or 0.5
	model.Root.Size = Vector3.new(2, 0, 2) * args.Range
	
	local function setCFrame()
		if not (model and model.PrimaryPart) then return end
		
		local ray = Ray.new(args.Root.Position, Vector3.new(0, -64, 0))
		local _, point = workspace:FindPartOnRayWithWhitelist(ray, {workspace:FindFirstChild("Dungeon")})
		local cframe = CFrame.new(point)
		model:SetPrimaryPartCFrame(cframe)
	end
	
	local function isShowingRange()
		local options = self:GetClass("OptionsClient").Options
		if options then
			return options.ShowRange
		else
			return false
		end
	end
	
	setCFrame()
	
	model.Parent = workspace.Effects
	
	self:Effect{
		Id = args.Id,
		Infinite = true,
		OnTicked = function()
			setCFrame()
			model.Root.Gui.Enabled = isShowingRange()
		end,
		OnEnded = function()
			model:Destroy()
		end
	}
end

function EffectsClient:EffectTelegraphCircle(args)
	local effect = args.Effect or {
		Type = "Flash",
		Args = {
			CFrame = CFrame.new(args.Position),
			Duration = 0.2,
			EndSize = Vector3.new(2, 2, 2) * (args.Radius + 4)
		}
	}
	
	local part = self.Storage.Models.TelegraphPart:Clone()
	part.Size = Vector3.new(args.Radius * 2, 0, args.Radius * 2)
	
	local movingCircle = part.Gui.MovingCircle
	
	local function setPartCFrame()
		local direction = workspace.CurrentCamera.CFrame.upVector
		local up = Vector3.new(0, 1, 0)
		local right = direction:Cross(up)
		local forward = right:Cross(up)
		part.CFrame = CFrame.new(
			args.Position.X, args.Position.Y, args.Position.Z,
			right.X, up.X, forward.X,
			right.Y, up.Y, forward.Y,
			right.Z, up.Z, forward.Z
		) * CFrame.Angles(0, -math.pi / 2, 0)
	end
	
	local function cleanUp()
		part:Destroy()
	end
	
	if args.Color then
		for _, desc in pairs(part:GetDescendants()) do
			if desc:IsA("ImageLabel") then
				desc.ImageColor3 = args.Color
			end
		end
	end
	
	setPartCFrame()
	part.Parent = workspace.Effects
	
	self:Effect{
		Id = args.Id,
		Time = args.Duration,
		OnTicked = function(e, dt)
			local progress = 1 - e:GetProgress()
			movingCircle.Size = UDim2.new(progress, 0, progress, 0)
			
			setPartCFrame()
		end,
		OnEnded = function(e)
			self:OnEffectRequested(effect.Type, effect.Args)
			cleanUp()
		end,
		OnCanceled = function(e)
			e.OnEnded = function() end
			cleanUp()
		end,
	}
end

function EffectsClient:EffectTelegraphSquare(args)
	local root = args.Root
	local attachmentType = args.AttachmentType
	
	local part = self.Storage.Models.TelegraphSquare:Clone()
	part.Size = Vector3.new(args.Width, 0, args.Length)
	
	local bang = self.Storage.Models.TelegraphBang:Clone()
	bang.Size = Vector3.new(1, 0, 1) * math.min(args.Width, args.Length)
	
	local function getCFrame()
		if attachmentType == "Translate" then
			return CFrame.new(root.Position):ToWorldSpace(args.CFrame)
		else
			return args.CFrame
		end
	end
	
	local effect = args.Effect or {
		Type = "Flash",
		Args = {
			CFrame = getCFrame(),
			Duration = 0.2,
			EndSize = Vector3.new(args.Width + 4, 4, args.Length + 4)
		}
	}
	
	if args.Color then
		for _, desc in pairs(part:GetDescendants()) do
			if desc:IsA("Frame") then
				desc.BackgroundColor3 = args.Color
			end
		end
		bang.Gui.ExclamationPoint.ImageColor3 = args.Color
	end
	
	local isLong = args.Length > args.Width
	
	local function setBangCFrame()
		local direction = workspace.CurrentCamera.CFrame.upVector
		local up = Vector3.new(0, 1, 0)
		local right = direction:Cross(up)
		local forward = right:Cross(up)
		local position = getCFrame().Position
		bang.CFrame = CFrame.new(
			position.X, position.Y, position.Z,
			right.X, up.X, forward.X,
			right.Y, up.Y, forward.Y,
			right.Z, up.Z, forward.Z
		) * CFrame.Angles(0, -math.pi / 2, 0)
	end
	
	local function setPartCFrame()
		part.CFrame = getCFrame()
	end
	
	local function cleanUp()
		part:Destroy()
		bang:Destroy()
	end
	
	setBangCFrame()
	setPartCFrame()
	part.Parent = workspace.Effects
	bang.Parent = workspace.Effects
	
	self:Effect{
		Id = args.Id,
		Time = args.Duration,
		OnTicked = function(e, dt)
			local progress = 1 - e:GetProgress()
			part.Gui.MovingSquare.Size = isLong and UDim2.new(1, 0, progress, 0) or UDim2.new(progress, 0, 1, 0)
			
			setBangCFrame()
			setPartCFrame()
		end,
		OnEnded = function(e)
			self:OnEffectRequested(effect.Type, effect.Args)
			cleanUp()
		end,
		OnCanceled = function(e)
			e.OnEnded = function() end
			cleanUp()
		end,
	}
end

function EffectsClient:EffectTelegraphDirectional(args)
	local id = args.Id
	local cframe = args.CFrame
	local length = args.Length
	local width = args.Width
	local duration = args.Duration
	
	local part = self.Storage.Models.TelegraphDirectional:Clone()
	part.Size = Vector3.new(width, 0, length)
	part.Parent = workspace.Effects
	
	local speed = 2
	local offset = 0.5
	
	self:Effect{
		Id = id,
		Time = duration,
		
		CFrame = cframe,
		SetCFrame = function(e)
			part.CFrame = e.CFrame * CFrame.new(0, 0, -(offset - 0.5) * length)
		end,
		
		OnStarted = function(e)
			e:SetCFrame()
		end,
		OnTicked = function(e, dt)
			e:SetCFrame()
			
			offset += speed * dt
			if offset > 1 then
				offset -= 1
			end
		end,
		OnEnded = function(e, dt)
			part:Destroy()
		end,
		
		OnChanged = function(e, args)
			for key, val in pairs(args) do
				e[key] = val
			end
		end,
	}
end

function EffectsClient:EffectShowProjectile(args)
	local projectile = args.Projectile
	
	local width = args.Width or 4
	
	local part = self.Storage.Models.TelegraphProjectile:Clone()
	part.Size = Vector3.new(width / 2, 0, width)
	part.Parent = workspace.Effects
	
	self:Effect{
		Infinite = true,
		OnTicked = function(e)
			if projectile and projectile.Parent then
				local cframe
				if projectile:IsA("Model") then
					if projectile.PrimaryPart then
						cframe = projectile:GetPrimaryPartCFrame()
					else
						return e:Stop()
					end
				else
					cframe = projectile.CFrame
				end
				
				local ray = Ray.new(cframe.Position, Vector3.new(0, -64, 0))
				local _, point = workspace:FindPartOnRayWithWhitelist(ray, {workspace:FindFirstChild("Dungeon")})
				
				part.CFrame = cframe - cframe.Position + point
			else
				e:Stop()
			end
		end,
		OnEnded = function(e)
			part:Destroy()
		end
	}
end

function EffectsClient:EffectFlash(args)
	self:Effect{
		Time = args.Duration / 2,
		OnStarted = function(e)
			e.Part = self.Storage.Models.Flash:Clone()
			
			if args.PartArgs then
				self:ApplyArgs(e.Part, args.PartArgs)
			end
			
			e.Part.Parent = workspace.Effects
			e:OnTicked(0)
		end,
		OnTicked = function(e, dt)
			local part = e.Part
			part.Size = e:Lerp(
				args.StartSize or Vector3.new(0, 0, 0),
				args.EndSize,
				e:GetProgress()
			)
			part.CFrame = args.CFrame
			part.Transparency = e:Lerp(0, 0.5, e:GetProgress())
		end,
		OnEnded = function(e)
			self:Effect{
				Time = args.Duration / 2,
				Part = e.Part,
				OnTicked = function(e, dt)
					e.Part.Transparency = e:Lerp(0.5, 1, e:GetProgress())
				end,
				OnEnded = function(e)
					e.Part:Destroy()
				end,
			}
		end,
	}
end

function EffectsClient:EffectLinearBlast(args)
	local cframe = args.CFrame
	local length = args.Length
	local width = args.Width
	local duration = args.Duration
	local style = args.Style or Enum.EasingStyle.Linear
	local partArgs = args.PartArgs
	
	local part = self:GetEffectPart()
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(length, width, width)
	part.CFrame = cframe * CFrame.Angles(0, math.pi / 2, 0)
	
	if partArgs then
		self:ApplyArgs(part, partArgs)
	end
	
	part.Parent = workspace.Effects
	self:Tween(part, {Size = Vector3.new(length, 0, 0)}, duration, style).Completed:Connect(function()
		part:Destroy()
	end)
end

function EffectsClient:EffectAirBlast(args)
	local part = self:GetEffectPart()
	part.Color = args.Color or Color3.new(1, 1, 1)
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(2, 2, 2) * (args.StartRadius or 0)
	part.Position = args.Position
	
	if args.PartArgs then
		for key, val in pairs(args.PartArgs) do
			part[key] = val
		end
	end
	
	part.Parent = workspace.Effects
	
	self:Tween(part, {Size = Vector3.new(2, 2, 2) * args.Radius, Transparency = 1}, args.Duration, args.Style, args.Direction).Completed:Connect(function()
		part:Destroy()
	end)
end

function EffectsClient:EffectGodRay(args)
	local part = self.Storage.Models.Cone:Clone()
	for key, val in pairs(args.PartArgs) do
		part[key] = val
	end
	
	local height = 48
	part.Size = Vector3.new(0, height, 0)
	part.Position = args.Position + Vector3.new(0, height / 2, 0)
	part.Parent = workspace.Effects
	
	local radius = args.Radius
	local goalSize = Vector3.new(radius * 2, height, radius * 2)
	self:Tween(part, {Size = goalSize, Transparency = 1}, args.Duration, Enum.EasingStyle.Linear).Completed:Connect(function()
		part:Destroy()
	end)
end

function EffectsClient:EffectForceWave(args)
	local root = args.Root
	local cframe = args.CFrame
	local startSize = args.StartSize or Vector3.new()
	local endSize = args.EndSize
	local duration = args.Duration
	local fadeDuration = args.FadeDuration or 0.25
	local partArgs = args.PartArgs
	local rotSpeed = args.RotSpeed or math.pi * 4
	
	local part = self.Storage.Models.ForceWave:Clone()
	
	if partArgs then
		self:ApplyArgs(part, partArgs)
	end
	
	local function setCFrame()
		part.CFrame = cframe + (root.Position - cframe.Position)
	end
	setCFrame()
	part.Size = startSize
	part.Parent = workspace.Effects
	
	local function onTicked(e, dt)
		cframe *= CFrame.Angles(0, 0, rotSpeed * dt)
		part.Size = e:Lerp(args.StartSize, args.EndSize, e:GetProgress())
		setCFrame()
	end
	
	local startTransparency = part.Transparency
	
	self:Effect{
		Time = duration - fadeDuration,
		OnTicked = onTicked,
		OnEnded = function()
			self:Effect{
				Time = fadeDuration,
				OnTicked = function(e, dt)
					onTicked(e, dt)
					part.Transparency = e:Lerp(startTransparency, 1, e:GetProgress())
				end,
				OnEnded = function()
					part:Destroy()
				end,
			}
		end,
	}
end

function EffectsClient:EffectShockwave(args)
	self:Effect{
		Time = args.Duration,
		OnStarted = function(e)
			e.Part = self.Storage.Models.Shockwave:Clone()
			if args.PartArgs then
				self:ApplyArgs(e.Part, args.PartArgs)
			end
			e.Part.Parent = workspace.Effects
			e:OnTicked(0)
		end,
		OnTicked = function(e, dt)
			local part = e.Part
			part.Size = e:Lerp(
				args.StartSize or Vector3.new(0, 0, 0),
				args.EndSize,
				e:GetProgress()
			) * Vector3.new(1.5, 1, 1.5)
			part.CFrame = args.CFrame * CFrame.new(0, part.Size.Y / 2, 0)
			part.Transparency = e:Lerp(0, 1, e:GetProgress())
		end,
		OnEnded = function(e)
			e.Part:Destroy()
		end,
	}
end

function EffectsClient:EffectAnchoredSpinningShockwave(args)
	local part = self.Storage.Models.Shockwave:Clone()
	if args.PartArgs then
		self:ApplyArgs(part, args.PartArgs)
	end
	part.Size = args.StartSize
	
	local rotation = 0
	local function setCFrame()
		part.CFrame = args.Anchor.CFrame * args.Offset * CFrame.Angles(0, rotation, 0)
	end
	setCFrame()
	
	part.Parent = workspace.Effects
	
	self:Effect{
		Time = args.GrowDuration,
		OnTicked = function(e, dt)
			rotation += args.RotationSpeed * dt
			part.Size = e:Lerp(args.StartSize, args.EndSize, e:GetProgress())
			setCFrame()
		end,
		OnEnded = function()
			self:Effect{
				Time = args.HoldDuration,
				OnTicked = function(e, dt)
					rotation += args.RotationSpeed * dt
					setCFrame()
				end,
				OnEnded = function()
					self:Effect{
						Time = args.ShrinkDuration,
						OnTicked = function(e, dt)
							rotation += args.RotationSpeed * dt
							part.Size = e:Lerp(args.EndSize, args.StartSize, e:GetProgress())
							setCFrame()
						end,
						OnEnded = function()
							part:Destroy()
						end,
					}
				end,
			}
		end,
	}
end

function EffectsClient:EffectSound(args)
	local soundPart = Instance.new("Part")
	soundPart.Anchored = true
	soundPart.CanCollide = false
	soundPart.Transparency = 1
	soundPart.Size = Vector3.new()
	soundPart.Position = args.Position
	soundPart.Parent = workspace.Effects
	
	local sound = args.Sound:Clone()
	
	if sound:FindFirstChild("Offset") then
		sound.TimePosition = sound.Offset.Value
	end
	
	sound.Parent = soundPart
	sound:Play()
	
	game:GetService("Debris"):AddItem(soundPart, sound.TimeLength / sound.PlaybackSpeed)
end

function EffectsClient:EffectKickDownDoor(args)
	local door = args.Door:Clone()
	if not door.PrimaryPart then return end
	door.Parent = workspace.Effects
	
	--weld, unanchor
	for _, object in pairs(door:GetChildren()) do
		if object:IsA("BasePart") and object ~= door.PrimaryPart then
			local w = Instance.new("Weld")
			w.Part0 = door.PrimaryPart
			w.Part1 = object
			w.C0 = w.Part0.CFrame:toObjectSpace(w.Part1.CFrame)
			w.Parent = w.Part0
			
			object.Anchored = false
		end
	end
	
	--activate special effects
	if door.PrimaryPart:FindFirstChild("KickDownTrail") then
		door.PrimaryPart.KickDownTrail.Enabled = true
	end
	
	if door.PrimaryPart:FindFirstChild("KickDownSound") then
		door.PrimaryPart.KickDownSound:Play()
	end
	
	--unanchor and push primaryPart
	local root = door.PrimaryPart
	local delta = root.CFrame:pointToObjectSpace(args.KickerPosition)
	
	local direction
	if delta.Z > 0 then
		direction = root.CFrame.lookVector
	else
		direction = -root.CFrame.lookVector
	end
	
	root.Anchored = false
	root.CFrame = root.CFrame + (direction * 5)
	root.Velocity = direction * 64
	
	--rotation
	local function r()
		return math.random(30, 60) * self:RandomSign()
	end
	root.RotVelocity = Vector3.new(r(), r(), r())
	
	--debris
	delay(3, function()
		local duration = 1
		for _, desc in pairs(door:GetDescendants()) do
			if desc:IsA("BasePart") then
				self:Tween(desc, {Transparency = 1}, duration, Enum.EasingStyle.Linear)
			
			elseif desc:IsA("Light") then
				self:Tween(desc, {Range = 0}, duration, Enum.EasingStyle.Linear)
			end
		end
		game:GetService("Debris"):AddItem(door, duration)
	end)
end

function EffectsClient:EffectExplodeDungeon(args)
	local model = args.Model
	model.Parent = workspace.Effects
	
	local function isBigPart(part)
		return math.max(part.Size.X, part.Size.Y, part.Size.Z) > 16
	end
	
	local function isLittlePart(part)
		return part.Size.X * part.Size.Y * part.Size.Z < 64
	end
	
	local parts = {}
	local partCounter = 0
	
	for _, desc in pairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			local part = desc
			
			if isBigPart(part) or isLittlePart(part) then
				part:Destroy()
			else
				partCounter = partCounter + 1
				if partCounter % 4 == 1 then
					table.insert(parts, part)
				else
					part:Destroy()
				end
			end
		end
	end
	
	local explosionCounter = 0
	
	self:Shuffle(parts)
	for _, part in pairs(parts) do
		local original = part
		part = part:Clone()
		original:Destroy()
		part.Parent = workspace.Effects
		
		part.Anchored = false
		part.CanCollide = false
		
		local launchCFrame =
			CFrame.Angles(0, math.pi * 2 * math.random(), 0) *
			CFrame.Angles(math.pi * 0.5 * math.random(), 0, 0)
		local launchSpeed = 64 + 64 * math.random()
		
		part.Velocity = launchCFrame.LookVector * launchSpeed
		part.RotVelocity = Vector3.new(
			math.random(-360, 360),
			math.random(-360, 360),
			math.random(-360, 360)
		)
		
		explosionCounter = explosionCounter + 1
		if explosionCounter % 16 == 0 then
			local e = Instance.new("Explosion")
			e.BlastPressure = 0
			e.Position = part.Position
			e.Parent = workspace.Effects
		end
		
		game:GetService("Debris"):AddItem(part, 2)
	end
	
	local sound = self.Storage.Sounds.ExplosionMassive:Clone()
	sound.Parent = workspace
	sound:Play()
	game:GetService("Debris"):AddItem(sound, sound.TimeLength)
end

function EffectsClient:EffectMessage(args)
	local gui = self.Storage.UI.TitleScreen:Clone()
	gui.TitleLabel.Text = ""
	gui.SubtitleLabel:Destroy()
	gui.BackgroundTransparency = 1
	gui.Parent = self.Player.PlayerGui:WaitForChild("Gui")
	
	spawn(function()
		for index = 1, #args.Text do
			gui.TitleLabel.Text = args.Text:sub(1, index)
			wait()
		end
		wait(2.5)
		self:Tween(gui.TitleLabel, {Position = gui.TitleLabel.Position + UDim2.new(0, 0, 1, 0)}, 1).Completed:Connect(function()
			gui:Destroy()
		end)
	end)
end

function EffectsClient:EffectTitleScreen(args)
	local gui = self.Storage.UI.TitleScreen:Clone()
	gui.TitleLabel.Text = args.Title or ""
	gui.SubtitleLabel.Text = args.Subtitle or ""
	
	local function setTransparencyHelper(gui, transparency)
		if gui:IsA("Frame") then
			gui.BackgroundTransparency = transparency
		elseif gui:IsA("TextLabel") then
			gui.TextTransparency = transparency
		end
	end
	local function setTransparency(transparency)
		setTransparencyHelper(gui, transparency)
		for _, object in pairs(gui:GetDescendants()) do
			setTransparencyHelper(object, transparency)
		end
	end
	
	setTransparency(1)
	gui.Parent = self.Player.PlayerGui:WaitForChild("Gui")
	
	local function fadeIn()
		self:Effect{
			Time = args.FadeInDuration or 1,
			OnTicked = function(e, dt)
				setTransparency(e:GetProgress())
			end,
			OnEnded = function()
				gui:Destroy()
			end,
		}
	end
	
	self:Effect{
		Id = args.Id,
		Time = args.FadeOutDuration or 1,
		OnCanceled = function(e)
			args.HoldDuration = 1
			e.Active = true
		end,
		OnTicked = function(e, dt)
			setTransparency(1 - e:GetProgress())
		end,
		OnEnded = function()
			setTransparency(0)
			
			if args.HoldDuration then
				wait(args.HoldDuration)
				fadeIn()
			else
				self:Effect{
					Id = args.Id,
					Infinite = true,
					OnEnded = function()
						fadeIn()
					end
				}
			end
		end,
	}
end

function EffectsClient:EffectPierce(args)
	local part = self:GetEffectPart()
	part.Size = Vector3.new()
	part.Transparency = 1
	
	local l = Instance.new("Attachment")
	l.CFrame = CFrame.new(-args.Width / 2, 0, args.Tilt)
	l.Parent = part
	
	local m = Instance.new("Attachment")
	m.Parent = part
	
	local r = Instance.new("Attachment")
	r.CFrame = CFrame.new(args.Width / 2, 0, args.Tilt)
	r.Parent = part
	
	local t1 = Instance.new("Trail")
	t1.Attachment0 = l
	t1.Attachment1 = m
	t1.Transparency = NumberSequence.new(0.5, 1)
	t1.Lifetime = 0.125
	t1.Color = ColorSequence.new(args.Color or Color3.new(1, 1, 1))
	t1.Parent = part
	
	local t2 = t1:Clone()
	t2.Attachment0 = r
	t2.Attachment1 = m
	t2.Parent = part
	
	local startCFrame = args.CFrame * CFrame.new(0, 0, args.Length / 2)
	local endCFrame = args.CFrame * CFrame.new(0, 0, -args.Length / 2)
	
	part.CFrame = startCFrame
	self:Tween(part, {CFrame = endCFrame}, args.Duration or 0.2, Enum.EasingStyle.Linear).Completed:Connect(function()
		t1.Enabled = false
		t2.Enabled = false
		wait(1)
		part:Destroy()
	end)
	
	part.Parent = workspace.Effects
end

function EffectsClient:EffectCleave(args)
	local part = self:GetEffectPart()
	part.Size = Vector3.new()
	part.Transparency = 1
	
	local a = Instance.new("Attachment")
	a.CFrame = CFrame.new(0, 0, -args.Long)
	a.Parent = part
	
	local b = Instance.new("Attachment")
	b.CFrame = CFrame.new(0, 0, -args.Short)
	b.Parent = part
	
	local trail = Instance.new("Trail")
	trail.Attachment0 = b
	trail.Attachment1 = a
	trail.Transparency = NumberSequence.new(0.5, 1)
	trail.Lifetime = 0.5
	trail.Color = ColorSequence.new(args.Color or Color3.new(1, 1, 1))
	trail.Parent = part
	
	local function setPartCFrame(progress)
		local angle = self:Lerp(args.StartAngle, args.EndAngle, progress)
			
		local here = args.Root.Position
		local there = args.Target.Position
		local delta = (there - here) * Vector3.new(1, 0, 1)
		local cframe = CFrame.new(here, here + delta) * CFrame.Angles(0, angle, 0)
		part.CFrame = cframe
	end
	setPartCFrame(0)
	
	part.Parent = workspace.Effects
	
	self:Effect{
		Time = args.Duration,
		OnTicked = function(e, dt)
			setPartCFrame(e:GetProgress())
		end,
		OnEnded = function()
			game:GetService("Debris"):AddItem(part, trail.Lifetime)
		end
	}
end

function EffectsClient:EffectTween(args)
	self:Tween(args.Object, args.Goals, args.Duration, args.Style, args.Direction)
end

function EffectsClient:EffectChatMessage(args)
	game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
		Text = args.Text,
		Color = args.Color or Color3.new(1, 1, 1),
		Font = args.Font or Enum.Font.GothamSemibold,
		TextSize = args.TextSize,
	})
end

function EffectsClient:EffectDialogue(args)
	if not self.DialogueQueue then
		self.DialogueQueue = {}
	end
	
	table.insert(self.DialogueQueue, args)
	while self.DialogueQueue[1] ~= args do wait() end
	
	local gui = self.Storage:WaitForChild("UI"):WaitForChild("DialogueFrame"):Clone()
	gui.NameText.Text = args.Name
	gui.Icon.Image = args.Image
	gui.DialogueText.Text = ""
	
	if args.Position == "Top" then
		gui.AnchorPoint = Vector2.new(0.5, 0)
		gui.Position = UDim2.new(0.5, 0, 0, 0)
	end
	
	local finish = gui.Position
	local start = gui.Position + UDim2.new(0, 0, 1, 0)
	
	gui.Position = start
	
	gui.UIScale.Scale = args.Scale or 1
	
	local parent = args.Parent or self.Player.PlayerGui:WaitForChild("Gui")
	while parent:FindFirstChild("TitleScreen") do wait() end
	 
	gui.Parent = parent
	
	self:Tween(gui, {Position = finish}, 0.25)
	
	local punctuation = {",", ".", "!", "?"}
	local function isPunctuation(character)
		for _, p in pairs(punctuation) do
			if p == character then
				return true
			end
		end
		return false
	end
	
	local button = gui.SkipButton
	
	local skipped = false
	local finished = false
	local function skip()
		if not skipped then
			skipped = true
			
		else
			finished = true
		end
	end
	
	local active = true
	local dialogue = {
		End = function()
			active = false
			skipped = true
			finished = true
		end,
		Ended = self:CreateNew"Event"(),
	}
	
	local lastInputType = UIS:GetLastInputType()
	if lastInputType == Enum.UserInputType.Touch then
		button.Text = "Tap here to continue"
	elseif lastInputType == Enum.UserInputType.Gamepad1 then
		button.Text = "Press L3 to continue"
	else
		button.Text = "Click here to continue"
	end
	
	button.Activated:Connect(function()
		skip()
	end)
	
	CAS:BindAction("DialogueSkip", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		
		skip()
	end, false, Enum.KeyCode.ButtonL3)
	
	spawn(function()
		local text = args.Text
		for index = 1, #text do
			gui.DialogueText.Text = text:sub(1, index)
			
			local character = text:sub(index, index)
			if not skipped then
				if isPunctuation(character) then
					wait(0.2)
				else
					wait()
				end
			end
			
			if not active then
				break
			end
		end
		
		skipped = true
		
		if args.ManualTiming then
			button:Destroy()
			while active do
				wait()
			end
		else
			while not finished do
				wait()
			end
		end
		
		CAS:UnbindAction("DialogueSkip")
		
		self:Tween(gui, {Position = start}, 0.25)
		wait(0.25)
		
		gui:Destroy()
		table.remove(self.DialogueQueue, 1)
		
		dialogue.Ended:Fire()
	end)
	
	return dialogue
end

function EffectsClient:EffectHalberdZone(args)
	local part = self.Storage.Models.HalberdZone:Clone()
	part.Size = Vector3.new(args.Width, 0, args.Length)
	
	local function setPartCFrame()
		local here = Vector3.new(
			args.Source.Position.X,
			args.Height,
			args.Source.Position.Z
		)
		local there = args.Target.Position
		local delta = (there - here) * Vector3.new(1, 0, 1)
		local cframe = CFrame.new(here, here + delta) * CFrame.new(0, 0, -args.Distance)
		part.CFrame = cframe
	end
	
	local c = 0.3
	local function setTransparency(t)
		part.Gui.StaticSquare.Left.BackgroundTransparency = t
		part.Gui.StaticSquare.Right.BackgroundTransparency = t
	end
	
	setPartCFrame()
	part.Parent = workspace.Effects
	
	self:Effect{
		Time = args.Duration / (1 - c),
		OnStarted = function(e)
			setTransparency(1)
		end,
		OnTicked = function(e, dt)
			setPartCFrame()
			
			local t = e:GetProgress()
			if t < c then
				setTransparency(1 - (t / c))
			elseif t > c and t < (1 - c) then
				setTransparency(0)
			elseif t > (1 - c) then
				setTransparency((t - (1 - c)) / c)
			end
		end,
		OnEnded = function()
			part:Destroy()
		end
	}
end

function EffectsClient:EffectRapierZone(args)
	local part = self.Storage.Models.RapierZone:Clone()
	part.Size = Vector3.new(args.Radius, 0, args.Radius) * 2 * 1.25
	
	local function setPartCFrame()
		part.CFrame = CFrame.new(args.Root.Position + args.Delta)
	end
	
	local c = 0.3
	local function setTransparency(t)
		part.Gui.Image.ImageTransparency = t
	end
	
	setPartCFrame()
	part.Parent = workspace.Effects
	
	self:Effect{
		Time = args.Duration / (1 - c),
		OnStarted = function(e)
			setTransparency(1)
		end,
		OnTicked = function(e, dt)
			setPartCFrame()
			
			local t = e:GetProgress()
			if t < c then
				setTransparency(1 - (t / c))
			elseif t > c and t < (1 - c) then
				setTransparency(0)
			elseif t > (1 - c) then
				setTransparency((t - (1 - c)) / c)
			end
		end,
		OnEnded = function()
			part:Destroy()
		end
	}
end

function EffectsClient:EffectBreakBreakable(args)
	local model = args.Model:Clone()
	args.Model:Destroy()
	model.Parent = workspace.Effects
	
	local cframe = model:GetBoundingBox()
	self:EffectSound{
		Sound = model:FindFirstChild("BreakSound") or self.Storage.Sounds.BreakSound,
		Position = cframe.Position
	}
	
	local function weldModel(model)
		local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		for _, child in pairs(model:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Anchored = false
				if child ~= root then
					local w = Instance.new("WeldConstraint")
					w.Part0 = root
					w.Part1 = child
					w.Parent = child
				end
			end
		end
		return root
	end
	
	local parts = {}
	for _, child in pairs(model:GetChildren()) do
		if child:IsA("BasePart") then
			child.Anchored = false
			table.insert(parts, child)
		elseif child:IsA("Model") then
			table.insert(parts, weldModel(child))
		end
	end
	
	for _, part in pairs(parts) do
		local delta = part.Position - args.Position
		part.Velocity = delta.Unit * math.random(32, 64)
		
		local function rot()
			return math.random(-90, 90)
		end
		part.RotVelocity = Vector3.new(
			rot(),
			rot(),
			rot()
		)
	end
	
	-- fade out
	delay(3, function()
		local duration = 1
		for _, desc in pairs(model:GetDescendants()) do
			if desc:IsA("BasePart") then
				self:Tween(desc, {Transparency = 1}, duration, Enum.EasingStyle.Linear)
			
			elseif desc:IsA("Light") then
				self:Tween(desc, {Range = 0}, duration, Enum.EasingStyle.Linear)
			end
		end
		game:GetService("Debris"):AddItem(model, duration)
	end)
end

function EffectsClient:EffectFadeModel(args)
	for _, desc in pairs(args.Model:GetDescendants()) do
		if desc:IsA("BasePart") then
			self:Tween(desc, {Transparency = 1}, args.Duration, Enum.EasingStyle.Linear)
		
		elseif desc:IsA("Light") then
			self:Tween(desc, {Range = 0}, args.Duration, Enum.EasingStyle.Linear)
			
		elseif desc:IsA("ParticleEmitter") then
			desc.Enabled = false
		end
	end
	game:GetService("Debris"):AddItem(args.Model, args.Duration)
end

function EffectsClient:EffectDropBoulder(args)
	local boulder = self:GetEffectPart()
	boulder.Material = Enum.Material.Slate
	boulder.BrickColor = BrickColor.new("Dirt brown")
	boulder.Size = Vector3.new(1, 1, 1) * (5 + math.random() * 3)
	boulder.CFrame =
		CFrame.new(args.Position + Vector3.new(0, 64, 0)) *
		CFrame.Angles(math.pi * 2 * math.random(), 0, math.pi * 2 * math.random())
	boulder.Parent = workspace.Effects
	
	self:Tween(boulder, {Position = args.Position}, args.Duration, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Connect(function()
		self:Tween(boulder, {Transparency = 1}, 0.5).Completed:Connect(function()
			boulder:Destroy()
		end)
	end)
end

function EffectsClient:EffectShadowAfflictedSpread(args)
	local bolt = self.Storage.Models.ShadowBolt.Root:Clone()
	local emitter = bolt.EmitterAttachment.Emitter
	
	bolt.Parent = workspace.Effects
	
	self:Effect{
		Time = args.Duration,
		OnTicked = function(e, dt)
			local a = args.RootStart.Position
			local c = args.RootFinish.Position
			local b = a + Vector3.new(0, 6, 0)
			
			local w = e:GetProgress()
			local ab = self:Lerp(a, b, w)
			local bc = self:Lerp(b, c, w)
			
			local p = self:Lerp(ab, bc, w)
			
			bolt.Position = p
		end,
		OnEnded = function()
			bolt.Transparency = 1
			emitter.Enabled = false
			game:GetService("Debris"):AddItem(bolt, emitter.Lifetime.Max)
		end
	}
end

function EffectsClient:EffectThrowJavelin(args)
	local javelin = args.Javelin
	local target = args.Target
	local duration = args.Duration
	
	javelin = javelin:Clone()
	javelin.Motor:Destroy()
	javelin.Transparency = 0
	javelin.Parent = workspace.Effects
	
	local startPosition = javelin.Position
	local rotation = javelin.RotationOffset.Value
	rotation = CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
	
	self:Effect{
		Time = duration,
		OnTicked = function(e)
			if not (target and target.Position) then
				e.Active = false
				return
			end
			
			local position = self:Lerp(startPosition, target.Position, e:GetProgress())
			local cframe = CFrame.new(position, target.Position) * rotation
			
			javelin.CFrame = cframe
		end,
		OnEnded = function()
			javelin:Destroy()
		end
	}
end

function EffectsClient:EffectLobProjectile(args)
	local model = args.Model:Clone()
	model.Parent = workspace.Effects
	
	local fadeDuration = args.FadeDuration or 1
	
	local tumble = CFrame.Angles(
		math.pi * 2 * math.random(),
		0,
		math.pi * 2 * math.random()
	)
	
	local tumbleX = math.pi * 2 * math.random()
	local tumbleY = math.pi * 2 * math.random()
	local tumbleZ = math.pi * 2 * math.random()
	
	self:Effect{
		Time = args.Duration,
		OnTicked = function(e, dt)
			local a = args.Start
			if typeof(a) ~= "Vector3" then
				a = a.Position
			end
			
			local c = args.Finish
			if typeof(c) ~= "Vector3" then
				c = c.Position
			end
			
			local b = (a + c) / 2 + Vector3.new(0, args.Height, 0)
			
			local w = e:GetProgress()
			local ab = self:Lerp(a, b, w)
			local bc = self:Lerp(b, c, w)
			
			local p = self:Lerp(ab, bc, w)
			
			if model.PrimaryPart then
				model:SetPrimaryPartCFrame(CFrame.new(p) * tumble)
				tumble = tumble * CFrame.Angles(tumbleX * dt, tumbleY * dt, tumbleZ * dt)
			else
				e:Stop()
			end
		end,
		OnEnded = function()
			if fadeDuration == 0 then
				model:Destroy()
			else
				self:EffectFadeModel{
					Model = model,
					Duration = fadeDuration,
				}
			end
		end
	}
end

function EffectsClient:EffectLeap(args)
	local root = args.Root
	local duration = args.Duration
	local finish = args.Finish
	local height = args.Height
	
	local start = root.CFrame
	
	local middlePosition = (start.Position + finish.Position) / 2 + Vector3.new(0, height, 0)
	local middle = finish - finish.Position + middlePosition

	self:Effect{
		Time = duration,
		OnTicked = function(e, dt)
			local w = math.clamp(e:GetProgress(), 0, 1)
			local ab = start:Lerp(middle, w)
			local bc = middle:Lerp(finish, w)

			local cframe = ab:Lerp(bc, w)
			root.CFrame = cframe
		end,
		OnEnded = function()
			root.CFrame = finish
		end,
	}
end

function EffectsClient:EffectCorruptionMana(args)
	local ball = self:GetEffectPart()
	ball.Material = Enum.Material.Neon
	ball.Size = Vector3.new(1, 1, 1) * 0.75
	ball.Shape = Enum.PartType.Ball
	
	local t = Instance.new("Attachment")
	t.Position = Vector3.new(0, 0.25, 0)
	t.Parent = ball
	
	local b = Instance.new("Attachment")
	b.Position = Vector3.new(0, -0.25, 0)
	b.Parent = ball
	
	local purple = Color3.fromRGB(61, 21, 133)
	local blue = Color3.fromRGB(82, 124, 174)
	
	ball.Color = purple
	ball.CFrame = args.StartCFrame
	
	local light = Instance.new("PointLight")
	light.Range = 0
	light.Color = purple
	light.Parent = ball
	
	local trail = Instance.new("Trail")
	trail.Color = ColorSequence.new(purple)
	trail.Attachment0 = t
	trail.Attachment1 = b
	trail.FaceCamera = true
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Lifetime = 0.5
	trail.Parent = ball
	
	ball.Parent = workspace.Effects
	
	self:Effect{
		Time = args.Duration,
		OnTicked = function(e, dt)
			local a = args.StartCFrame.Position
			local c = args.Root.Position
			local b = (a + c) / 2 + Vector3.new(0, 16, 0)
			
			local w = e:GetProgress()
			local ab = self:Lerp(a, b, w)
			local bc = self:Lerp(b, c, w)
			
			local p = self:Lerp(ab, bc, w)
			
			ball.Color = purple:Lerp(blue, w)
			ball.Position = p
			
			light.Color = ball.Color
			if w < 0.2 then
				light.Range = 16 * w / 0.2
			elseif w >= 0.2 and w <= 0.8 then
				light.Range = 16
			elseif w > 0.8 then
				light.Range = 16 * (1 - (w - 0.8) / 0.2)
			end
			
			trail.Color = ColorSequence.new(ball.Color)
		end,
		OnEnded = function()
			ball.Transparency = 1
			trail.Enabled = false
			game:GetService("Debris"):AddItem(ball, trail.Lifetime)
		end
	}
end

function EffectsClient:EffectKillEffectGhost(args)
	local ghost = self.Storage.Models.Ghost:Clone()
	
	local cframe = CFrame.new(args.Position) * CFrame.Angles(0, math.pi * 2 * math.random(), 0)
	local vz = cframe.LookVector
	local height = 0
	local lastPosition = cframe.Position + Vector3.new(0, -1, 0)
	
	ghost.Parent = workspace.Effects
	ghost.Sound:Play()
	
	local heightSpeed = 12
	local amplitude = 2
	local frequency = 0.5
	
	self:Effect{
		Time = 4,
		OnTicked = function(e, dt)
			height += heightSpeed * dt
			local dx = math.sin(height * frequency) * amplitude
			local position = (cframe * CFrame.new(dx, height, 0)).Position
			
			local vy = (position - lastPosition).Unit
			local vx = vy:Cross(vz)
			ghost.CFrame = CFrame.fromMatrix(position, vx, vy, vz)
			
			lastPosition = position
		end,
		OnEnded = function()
			ghost:Destroy()
		end
	}
end

function EffectsClient:EffectGenericBolt(args)
	local bolt = args.Model:Clone()
	
	local lights = {}
	local emitters = {}
	local trails = {}
	local parts = {}
	local fadeDuration = 0
	for _, desc in pairs(bolt:GetDescendants()) do
		if desc:IsA("Light") then
			table.insert(lights, desc)
			
		elseif desc:IsA("ParticleEmitter") then
			table.insert(emitters, desc)
			fadeDuration = math.max(fadeDuration, desc.Lifetime.Max)
			
		elseif desc:IsA("Trail") then
			table.insert(trails, desc)
			fadeDuration = math.max(fadeDuration, desc.Lifetime)
			
		elseif desc:IsA("BasePart") then
			table.insert(parts, desc)
		end
	end
	
	bolt.Parent = workspace.Effects
	
	self:Effect{
		Time = args.Duration,
		OnStarted = function(e)
			bolt:SetPrimaryPartCFrame(CFrame.new(args.StartPosition, args.TargetRoot.Position))
		end,
		OnTicked = function(e, dt)
			local a = args.StartPosition
			local b = args.TargetRoot.Position
			
			local w = e:GetProgress()
			local p = self:Lerp(a, b, w)
			if args.ControlPosition then
				local ac = self:Lerp(a, args.ControlPosition, w)
				local cb = self:Lerp(args.ControlPosition, b, w)
				p = self:Lerp(ac, cb, w)
			end
			
			bolt:SetPrimaryPartCFrame(CFrame.new(p, b))
		end,
		OnEnded = function()
			local cframe = bolt:GetPrimaryPartCFrame()
			local delta = args.TargetRoot.Position - cframe.Position
			bolt:SetPrimaryPartCFrame(cframe + delta)
			
			for _, part in pairs(parts) do
				part.Transparency = 1
			end
			for _, light in pairs(lights) do
				self:Tween(light, {Range = 0}, fadeDuration, Enum.EasingStyle.Linear)
			end
			for _, trail in pairs(trails) do
				trail.Enabled = false
			end
			for _, emitter in pairs(emitters) do
				emitter.Enabled = false
			end
			game:GetService("Debris"):AddItem(bolt, fadeDuration)
		end
	}
end

function EffectsClient:EffectHandaxeThrow(args)
	local axe = args.Axe:Clone()
	axe.Anchored = true
	axe.Trail.Enabled = true
	axe.Parent = workspace.Effects
	
	local rotSpeed = math.pi * 16
	
	local offset = args.Offset or CFrame.new()
	
	self:Effect{
		Time = args.Duration,
		OnTicked = function(e, dt)
			if not args.Target then return end
			
			local a = args.StartPosition
			local c = args.Target.Position
			local b = (a + c) / 2 + Vector3.new(0, 8, 0)
			local delta = c - a
			
			local w = e:GetProgress()
			local ab = self:Lerp(a, b, w)
			local bc = self:Lerp(b, c, w)
			
			local p = self:Lerp(ab, bc, w)
			
			axe.CFrame = CFrame.new(p, p + delta) * CFrame.Angles(rotSpeed * e.Time, 0, 0) * offset
		end,
		OnEnded = function()
			axe:Destroy()
		end
	}
end

function EffectsClient:EffectHandaxeDrop(args)
	local axe = args.Axe:Clone()
	axe.Anchored = true
	
	local cframe = CFrame.new(args.Position) * CFrame.Angles(0, math.pi * 2 * math.random(), 0)
	axe.CFrame = cframe:ToWorldSpace(axe.Ground.CFrame:Inverse())
	
	axe.Parent = workspace.Effects
	
	local ring = self.Storage.Models.PickupPart:Clone()
	ring.Position = args.Position
	ring.Parent = workspace.Effects
	
	self:Effect{
		Id = args.Id,
		Infinite = true,
		OnEnded = function()
			axe:Destroy()
			ring:Destroy()
		end
	}
end

function EffectsClient:EffectCombatTeleport(args)
	local distance = (args.A - args.B).Magnitude
	local midpoint = (args.A + args.B) / 2
	
	local part = self:GetEffectPart()
	part.Transparency = 1
	part.Size = Vector3.new(4, 4, distance)
	part.CFrame = CFrame.new(midpoint, args.B)
	
	local emitter = self.Storage.Emitters.CombatTeleportEmitter:Clone()
	emitter.Parent = part
	
	part.Parent = workspace.Effects
	
	wait()
	
	emitter:Emit(distance * 2)
	game:GetService("Debris"):AddItem(part, emitter.Lifetime.Max)
end

function EffectsClient:EffectThunderstrike(args)
	local soundEnabled = args.SoundEnabled if soundEnabled == nil then soundEnabled = true end
	
	local duration = 0.15
	
	local part = self:GetEffectPart()
	part.Material = Enum.Material.Neon
	part.Color = Color3.new(1, 1, 1)
	part.CastShadow = false
	
	local function drawSegment(a, b)
		local m = (a + b) / 2
		local d = (b - a).Magnitude
		local segment = part:Clone()
		segment.Size = Vector3.new(0.2, 0.2, d)
		segment.CFrame = CFrame.new(m, b)
		segment.Parent = workspace.Effects
		self:Tween(segment, {Transparency = 1}, duration, Enum.EasingStyle.Linear).Completed:Connect(function()
			segment:Destroy()
		end)
	end
	
	local lastPosition = args.Position
	local y = lastPosition.Y
	local dy = 8
	for segment = 1, 12 do
		local theta = math.pi * 2 * math.random()
		local r = 6 * math.random()
		local dx = math.cos(theta) * r
		local dz = math.sin(theta) * r
		y = y + dy
		
		local position = Vector3.new(
			args.Position.X + dx,
			y,
			args.Position.Z + dz 
		)
		
		drawSegment(lastPosition, position)
		lastPosition = position
	end
	
	if soundEnabled then
		local sound = self.Storage.Sounds.LightningClose:Clone()
		self:EffectSound{
			Position = args.Position,
			Sound = sound,
		}
	end
end

function EffectsClient:EffectExclamationPoint(args)
	local bang = self.Storage.Models.ExclamationPoint:Clone()

	local position = args.Position
	local function setCFrame(rotation)
		local cam = workspace.CurrentCamera
		local cframe = cam.CFrame
		local delta = position - cframe.Position
		cframe += delta
		bang.CFrame = cframe * CFrame.Angles(0, rotation, 0)
	end

	setCFrame(0)
	bang.Parent = workspace.Effects

	self:Effect{
		Id = args.Id,
		Infinite = true,
		OnTicked = function(e, dt, t)
			setCFrame(t)
		end,
		OnEnded = function()
			bang:Destroy()
		end,
	}
end

function EffectsClient:EffectLevelUp(args)
	local root = args.Root
	local player = args.Player
	
	local count = 4
	local parts = {}
	for _ = 1, count do
		local part = self.Storage.Models.LevelUpThing:Clone()
		part.Parent = workspace.Effects
		table.insert(parts, part)
	end
	
	local height = 0
	local speed = 4
	local acceleration = 2
	local radius = 2
	
	local sound = self.Storage.Sounds.LevelUp:Clone()
	sound.Parent = root
	sound:Play()
	game:GetService("Debris"):AddItem(sound, sound.TimeLength)
	
	local light = Instance.new("PointLight")
	light.Color = BrickColor.new("Gold").Color
	light.Range = 32
	light.Parent = root
	self:Tween(light, {Range = 0}, 1).Completed:Connect(function()
		light:Destroy()
	end)
	
	self:EffectAirBlast{
		Position = root.Position,
		Radius = 16,
		Color = light.Color,
		Duration = 0.5,
		PartArgs = {
			Material = "Neon"
		}
	}
	
	self:Effect{
		Time = 1,
		OnTicked = function(e, dt)
			speed += acceleration * dt
			height += speed * dt
			
			local thetaBase = height
			for step = 1, count do
				local part = parts[step]
				local theta = thetaBase + (math.pi * 2 / count) * (step - 1)
				local dx = math.cos(theta) * radius
				local dz = math.sin(theta) * radius
				local dy = -2 + height
				
				part.CFrame = CFrame.new(root.Position + Vector3.new(dx, dy, dz))
			end
		end,
		OnEnded = function(e)
			for _, part in pairs(parts) do
				part.Transparency = 1
				
				local trail = part:FindFirstChild("Trail")
				if trail then
					trail.Enabled = false
					game:GetService("Debris"):AddItem(part, trail.Lifetime)
				else
					part:Destroy()
				end
			end
		end
	}
	
	if player == self.Player then
		local gui = self.Storage.UI.LevelUpFrame:Clone()
		gui.Parent = self.Player.PlayerGui.Gui
		
		local durationA = 2
		local durationB = 4
		
		self:Tween(gui.Bar, {Size = UDim2.new(8, 0, 0, 0), BackgroundTransparency = 1}, durationA, Enum.EasingStyle.Quint)
		
		for _, text in pairs{gui.StaticText, gui.StaticTextBackground} do
			self:Tween(text, {ImageTransparency = 1}, durationB, Enum.EasingStyle.Linear)
		end
		
		game:GetService("Debris"):AddItem(gui, durationB)
	end
end

function EffectsClient:EffectThunderstorm(args)
	local rain = {}
	
	local rainCount = 64
	local cyclesPerSecond = 2
	
	for _ = 1, rainCount do
		local part = self:GetEffectPart()
		part.Transparency = 0.5
		part.Color = Color3.new(0.5, 0.5, 0.5)
		part.Size = Vector3.new(0.2, 8, 0.2)
		part.CastShadow = false
		table.insert(rain, part)
		part.Parent = workspace.Effects
	end
	
	local position = Vector3.new()
	local delta = 64
	local spin = math.pi * 2 * math.random()
	local tilt = math.pi / 8
	local index = 1
	
	local lightningCooldown = self:CreateNew"Cooldown"{}
	local function lightning()
		local lighting = game:GetService("Lighting")
		local db = 4
		self:Effect{
			Time = 0.05,
			OnStarted = function(e)
				local sound = self.Storage.Sounds["Lightning"..math.random(1, 5)]:Clone()
				sound.Parent = workspace
				sound:Play()
				game:GetService("Debris"):AddItem(sound, sound.TimeLength)
				
				lighting.Brightness = lighting.Brightness + db
			end,
			OnEnded = function(e)
				lighting.Brightness = lighting.Brightness - db
			end
		}
	end
	
	local rainSound = self.Storage.Sounds.RainLoop:Clone()
	rainSound.Parent = workspace
	rainSound:Play()
	
	self:Effect{
		Id = args.Id,
		Infinite = true,
		OnTicked = function(e, dt)
			local char = self.Player.Character
			if char and char.PrimaryPart then
				position = char.PrimaryPart.Position
			end
			
			local cycles = cyclesPerSecond * dt
			local indices = math.floor(rainCount * cycles)
			
			for _ = 1, indices do
				local part = rain[index]
				local dx = math.random(-delta, delta)
				local dz = math.random(-delta, delta)
				local cframe =
					CFrame.new(position + Vector3.new(dx, 0, dz)) *
					CFrame.Angles(0, spin, tilt) *
					CFrame.new(0, 128, 0)
				part.CFrame = cframe
				self:Tween(part, {CFrame = cframe * CFrame.new(0, -144, 0)}, 0.5, Enum.EasingStyle.Linear)
				
				index = index + 1
				if index > rainCount then
					index = 1
				end
			end
			
			if lightningCooldown:IsReady() then
				lightningCooldown:Use(self:RandomFloat(0.5, 10))
				lightning()
			end
		end,
		OnEnded = function()
			for _, part in pairs(rain) do
				part:Destroy()
			end
			rainSound:Destroy()
		end
	}
end

function EffectsClient:EffectElectricSpark(args)
	local start = args.Start
	local finish = args.Finish
	local segmentCount = args.SegmentCount
	local radius = args.Radius
	local duration = args.Duration
	local partArgs = args.PartArgs
	
	local cframe = CFrame.new(start, finish)
	
	local template = self:GetEffectPart()
	for key, val in pairs(partArgs) do
		template[key] = val
	end
	
	local distance = (finish - start).Magnitude
	local lastPosition = start
	local distanceStep = distance / segmentCount
	
	for segmentNumber = 1, segmentCount do
		local segment = template:Clone()
		
		local a = lastPosition
		
		local c = cframe * CFrame.new(0, 0, -distanceStep * segmentNumber)
		c *= CFrame.Angles(0, 0, math.pi * 2 * math.random())
		c *= CFrame.new(0, radius * math.random(), 0)
		
		local b = c.Position
		
		segment.CFrame = CFrame.new((a + b) / 2, b)
		segment.Size = Vector3.new(0.2, 0.2, (b - a).Magnitude)
		segment.Parent = workspace.Effects
		
		lastPosition = b
		
		self:Tween(segment, {Transparency = 1}, duration)
	end
end

function EffectsClient:EffectTextFeedback(args)
	local duration = args.Duration
	
	local tweenStyle = args.TweenStyle or Enum.EasingStyle.Elastic
	local tweenDuration = args.TweenDuration or 0.25
	
	local fadeStyle = args.FadeStyle or Enum.EasingStyle.Linear
	local fadeDuration = args.FadeDuration or 0.5
	
	local text = Instance.new("TextLabel")
	text.Name = "TextFeedback"
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.Size = UDim2.new(0, 0, 0, 0)
	text.TextSize = 20
	text.BackgroundTransparency = 1
	text.TextStrokeTransparency = 0
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeColor3 = Color3.new(0, 0, 0)
	text.Font = Enum.Font.GothamBold
	
	for key, val in pairs(args.TextArgs) do
		text[key] = val
	end
	
	text.Position = UDim2.new(0.5, 0, 1, text.TextSize + 8)
	text.Parent = self.Player.PlayerGui:WaitForChild("Gui")
	
	self:Tween(text, {Position = UDim2.new(0.5, 0, 0.66, 0)}, tweenDuration, tweenStyle).Completed:Connect(function()
		wait(duration)
		
		self:Tween(text, {TextTransparency = 1, TextStrokeTransparency = 1}, fadeDuration, fadeStyle).Completed:Connect(function()
			text:Destroy()
		end)
	end)
end

function EffectsClient:EffectOminousDialogue(args)
	local tweenDuration = args.TweenDuration
	local duration = args.Duration
	local fadeStyle = args.FadeStyle or Enum.EasingStyle.Linear
	local fadeDuration = args.FadeDuration or 0.5

	local text = Instance.new("TextLabel")
	text.Name = "TextFeedback"
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.Size = UDim2.new(0, 0, 0, 0)
	text.TextSize = 20
	text.BackgroundTransparency = 1
	text.TextStrokeTransparency = 0
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeColor3 = Color3.new(0, 0, 0)
	text.RichText = true
	text.Font = Enum.Font.GothamBold

	for key, val in pairs(args.TextArgs) do
		text[key] = val
	end
	
	local graphemes = 0
	for _ in utf8.graphemes(text.Text) do
		graphemes += 1
	end

	text.Position = UDim2.new(0.5, 0, 0.66, 0)
	text.MaxVisibleGraphemes = 0
	text.Parent = self.Player.PlayerGui:WaitForChild("Gui")

	self:Tween(text, {MaxVisibleGraphemes = graphemes}, tweenDuration, Enum.EasingStyle.Linear).Completed:Connect(function()
		wait(duration)

		self:Tween(text, {TextTransparency = 1, TextStrokeTransparency = 1}, fadeDuration, fadeStyle).Completed:Connect(function()
			text:Destroy()
		end)
	end)
end

function EffectsClient:EffectAddJavelinEmitter(args)
	local javelin = args.Javelin
	
	local emitter = self.Storage.Emitters.JavelinEmitter:Clone()
	emitter.Parent = javelin
end

function EffectsClient:EffectRicochet(args)
	local position = args.Position
	local target = args.Target
	local duration = args.Duration
	local model = args.ProjectileModel:Clone()
	
	local function setCFrame(progress)
		local current = position + (target.Position - position) * progress
		local cframe = CFrame.new(current, target.Position)
		model:SetPrimaryPartCFrame(cframe)
	end
	
	setCFrame(0)
	model.Parent = workspace.Effects
	
	self:Effect{
		Time = duration,
		OnTicked = function(e)
			setCFrame(e:GetProgress())
		end,
		OnEnded = function()
			self:EffectFadeModel({
				Model = model,
				Duration = 0.5,
			})
		end,
	}
end

function EffectsClient:EffectRainOfProjectiles(args)
	local position = args.Position
	local duration = args.Duration
	local radius = args.Radius
	local projectileModel = args.ProjectileModel
	local startPosition = args.StartPosition
	
	local height = 128
	
	-- rising projectile
	self:Effect{
		Time = 0.5,
		SetCFrame = function(e, progress)
			local position = startPosition + Vector3.new(0, height * progress, 0)
			local cframe = CFrame.new(position) * CFrame.Angles(math.pi / 2, 0, 0)
			e.Model:SetPrimaryPartCFrame(cframe)
		end,
		OnStarted = function(e)
			e.Model = projectileModel:Clone()
			
			e:SetCFrame(0)
			e.Model.Parent = workspace.Effects
		end,
		OnTicked = function(e)
			e:SetCFrame(e:GetProgress())
		end,
		OnEnded = function(e)
			e.Model:Destroy()
		end,
	}
	
	-- raining projectiles
	self:Effect{
		Time = duration,
		Interval = 0.1,
		OnTicked = function()
			local model = projectileModel:Clone()
			
			local start = position + Vector3.new(0, height, 0)
			
			local theta = math.pi * 2 * math.random()
			local r = radius * math.random()
			local dx = math.cos(theta) * r
			local dz = math.sin(theta) * r
			local finish = position + Vector3.new(dx, 0, dz)
			
			local delta = (finish - start)
			
			local function setCFrame(progress)
				local cframe = CFrame.new(start + delta * progress, finish)
				model:SetPrimaryPartCFrame(cframe)
			end
			
			setCFrame(0)
			model.Parent = workspace.Effects
			
			self:Effect{
				Time = 0.5,
				OnTicked = function(e)
					setCFrame(e:GetProgress())
				end,
				OnEnded = function()
					setCFrame(1)
					
					self:EffectFadeModel({
						Model = model,
						Duration = 0.5,
					})
				end,
			}
		end,
	}
	
	-- sound
	local soundPart = Instance.new("Part")
	soundPart.Anchored = true
	soundPart.CanCollide = false
	soundPart.Transparency = 1
	soundPart.Size = Vector3.new()
	soundPart.Position = position
	soundPart.Parent = workspace.Effects

	local sound = self.Storage.Sounds.RainOfProjectiles:Clone()
	sound.Parent = soundPart
	
	delay(0.25, function()
		sound:Play()
		wait(duration)
		soundPart:Destroy()
	end)
end

local Singleton = EffectsClient:Create()
return Singleton