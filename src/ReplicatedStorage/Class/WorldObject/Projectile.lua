local Super = require(script.Parent)
local Projectile = Super:Extend()

Projectile.CFrame = CFrame.new()
Projectile.Velocity = Vector3.new()
Projectile.Acceleration = Vector3.new()
Projectile.DistanceTraversed = 0
Projectile.Range = 256

function Projectile.CreateGenericProjectile(args)
	local targeting = Projectile:GetService("TargetingService")

	local cframe = args.CFrame
	local speed = args.Speed
	local model = args.Model:Clone()
	local deactivationType = args.DeactivationType or "Any"
	local onTicked = args.OnTicked
	local onEnded = args.OnEnded
	local onHitTarget = args.OnHitTarget
	local onHitAlly = args.OnHitAlly
	local onHitPart = args.OnHitPart
	local getOffset = args.GetOffset
	local width = args.Width
	local range = args.Range

	local velocity = cframe.LookVector * speed

	local victims = {}

	local projectileArgs = {
		Model = model,
		CFrame = cframe,
		Velocity = velocity,
		FaceTowardsVelocity = true,
		GetOffset = getOffset,
		Range = range,
		OnTicked = function(projectile, dt)
			-- custom on ticked function?
			if onTicked then
				onTicked(projectile, dt)
			end

			-- hit targets as we go
			local targets = targeting:TargetWideProjectile(targeting:GetEnemies(), {
				Projectile = projectile,
				Width = width,
			})

			for _, target in pairs(targets) do
				if target and (not table.find(victims, target)) and (not target:IsDead()) then
					table.insert(victims, target)

					if onHitTarget then
						onHitTarget(target, projectile)
					end

					if deactivationType == "Any" or deactivationType == "Enemy" then
						projectile.LastPartHit = target.Root
						projectile:Deactivate()
						return
					end
				end
			end

			-- allies?
			if onHitAlly then
				local allies = targeting:TargetWideProjectile(targeting:GetMortals(), {
					Projectile = projectile,
					Width = width,
				})

				for _, ally in pairs(allies) do
					if ally and (not table.find(victims, ally)) and (not ally:IsDead()) then
						table.insert(victims, ally)

						onHitAlly(ally, projectile)

						if deactivationType == "Any" or deactivationType == "Ally" then
							projectile.LastPartHit = ally.Root
							projectile:Deactivate()
							return
						end
					end
				end
			end
		end,
		ShouldIgnoreFunc = function(part)
			if game:GetService("CollectionService"):HasTag(part, "InvisibleWall") then return true end
			
			local hitsWalls = (deactivationType == "Any" or deactivationType == "Wall")
			if not hitsWalls then return true end
		end,
		OnHitPart = function(projectile, part)
			if not part:IsDescendantOf(Projectile:GetRun().Dungeon.Model) then return end

			if onHitPart then
				onHitPart(part, projectile)
			end

			if deactivationType == "Any" or deactivationType == "Wall" then
				projectile:Deactivate()
			end

			return true
		end,
		OnEnded = onEnded,
	}

	if args.Args then
		for key, val in pairs(args.Args) do
			projectileArgs[key] = val
		end
	end

	local projectile = Projectile:CreateNew"Projectile"(projectileArgs)
	Projectile:GetWorld():AddObject(projectile)

	return projectile
end

function Projectile.CreateHostileProjectile(args)
	local targeting = Projectile:GetService("TargetingService")

	local cframe = args.CFrame
	local speed = args.Speed
	local model = args.Model:Clone()
	local deactivationType = args.DeactivationType or "Any"
	local onTicked = args.OnTicked
	local onEnded = args.OnEnded
	local onHitTarget = args.OnHitTarget
	local onHitPart = args.OnHitPart
	local getOffset = args.GetOffset
	local width = args.Width
	local range = args.Range

	local velocity = cframe.LookVector * speed

	local victims = {}

	local projectileArgs = {
		Model = model,
		CFrame = cframe,
		Velocity = velocity,
		FaceTowardsVelocity = true,
		GetOffset = getOffset,
		Range = range,
		OnTicked = function(projectile, dt)
			-- custom on ticked function?
			if onTicked then
				onTicked(projectile, dt)
			end

			-- hit targets as we go
			local targets = targeting:TargetWideProjectile(targeting:GetMortals(), {
				Projectile = projectile,
				Width = width,
			})

			for _, target in pairs(targets) do
				if target and (not table.find(victims, target)) and (not target:IsDead()) then
					table.insert(victims, target)

					if onHitTarget then
						onHitTarget(target, projectile)
					end

					if deactivationType == "Any" or deactivationType == "Enemy" then
						projectile.LastPartHit = target.Root
						projectile:Deactivate()
						return
					end
				end
			end
		end,
		ShouldIgnoreFunc = function(part)
			if game:GetService("CollectionService"):HasTag(part, "InvisibleWall") then return true end

			local hitsWalls = (deactivationType == "Any" or deactivationType == "Wall")
			if not hitsWalls then return true end
		end,
		OnHitPart = function(projectile, part)
			if not part:IsDescendantOf(Projectile:GetRun().Dungeon.Model) then return end

			if onHitPart then
				onHitPart(part, projectile)
			end

			if deactivationType == "Any" or deactivationType == "Wall" then
				projectile:Deactivate()
			end

			return true
		end,
		OnEnded = onEnded,
	}

	if args.Args then
		for key, val in pairs(args.Args) do
			projectileArgs[key] = val
		end
	end

	local projectile = Projectile:CreateNew"Projectile"(projectileArgs)
	Projectile:GetWorld():AddObject(projectile)
	Projectile:GetService("EffectsService"):RequestEffectAll("ShowProjectile", {Projectile = projectile.Model, Width = width})

	return projectile
end



function Projectile:OnCreated()
	Super.OnCreated(self)
	
	self:SetCFrame(self.CFrame.Position)
	self.LastCFrame = self.CFrame
	self.Model.Parent = workspace.Projectiles
	
	self.Time = 0
end

function Projectile:SetCFrame(position)
	if self.FaceTowardsVelocity then
		self.CFrame = CFrame.new(position, position + self.Velocity)
	else
		self.CFrame = self.CFrame - self.CFrame.Position + position
	end
	
	if self.GetOffset then
		self.Model:SetPrimaryPartCFrame(self.CFrame * self:GetOffset())
	else
		self.Model:SetPrimaryPartCFrame(self.CFrame)
	end
end

function Projectile:OnUpdated(dt)
	self.Time += dt
	
	local movement = self.Velocity * dt
	local ray = Ray.new(self.CFrame.Position, movement)
	local part, point, normal = self:Raycast(ray, {workspace.Effects, workspace.Projectiles}, self.ShouldIgnoreFunc)
	
	local nextPosition = self.CFrame.Position + movement
	
	if part then
		self.LastPartHit = part
		
		if self.OnHitPart then
			if self:OnHitPart(part) then
				nextPosition = point
				movement = nextPosition - self.CFrame.p
			end
		end
	end
	
	self.DistanceTraversed = self.DistanceTraversed + movement.Magnitude
	if self.Range and self.DistanceTraversed >= self.Range then
		self:Deactivate()
	end
	
	if self.OnTicked then
		self:OnTicked(dt)
	end
	
	self.LastCFrame = self.CFrame
	self:SetCFrame(nextPosition)
end

function Projectile:IsHittingCharacter(character)
	local delta = character:GetPosition() - self.CFrame.Position
	local distanceSq = delta.X ^ 2 + delta.Z ^ 2
	return distanceSq <= 4
end

function Projectile:TiltTowards(position, rotSpeed, dt)
	local here = self.CFrame.Position
	
	local cframe = CFrame.new(here, here + self.Velocity)
	local direction = cframe.LookVector
	local delta = (position - here) * Vector3.new(1, 0, 1)
	local angle = math.acos(direction:Dot(delta.Unit))
	
	local sign = 1
	if cframe:PointToObjectSpace(position).X > 0 then
		sign = -1
	end
	
	local rotation = math.min(rotSpeed * dt, angle) * sign
	cframe *= CFrame.Angles(0, rotation, 0)
	
	self.Velocity = cframe.LookVector * self.Velocity.Magnitude
end

function Projectile:OnDestroyed()
	if self.OnEnded then
		self:OnEnded()
	end
	
	local cleanupScript = self.Model:FindFirstChild("CleanupScript")
	if cleanupScript then
		require(cleanupScript)(self)
	else
		self.Model:Destroy()
	end
end

return Projectile
