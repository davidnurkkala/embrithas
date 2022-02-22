local Super = require(script.Parent)
local TargetingService = Super:Extend()

function TargetingService:GetEnemies()
	local enemies = {}
	for _, enemy in pairs(self:GetClass("Enemy").Instances) do
		if (enemy.Untargetable == 0) then
			table.insert(enemies, enemy)
		end
	end
	return enemies
end

function TargetingService:GetMortals()
	local mortals = {}
	for _, legend in pairs(self:GetClass("Legend").Instances) do
		if (legend.Untargetable == 0) then
			table.insert(mortals, legend)
		end
	end
	
	for _, ally in pairs(self:GetClass("Ally").Instances) do
		if (ally.Untargetable == 0) then
			table.insert(mortals, ally)
		end
	end
	return mortals
end

function TargetingService:GetCharacters()
	local characters = {}
	
	for _, legend in pairs(self:GetClass("Legend").Instances) do
		if (legend.Untargetable == 0) then
			table.insert(characters, legend)
		end
	end

	for _, ally in pairs(self:GetClass("Ally").Instances) do
		if (ally.Untargetable == 0) then
			table.insert(characters, ally)
		end
	end
	
	for _, enemy in pairs(self:GetClass("Enemy").Instances) do
		if (enemy.Untargetable == 0) then
			table.insert(characters, enemy)
		end
	end
	
	return characters
end

function TargetingService:GetMortalFromPart(part)
	for _, mortal in pairs(self:GetMortals()) do
		if part:IsDescendantOf(mortal.Model) then
			return mortal
		end
	end
	return nil
end

function TargetingService:GetClampedAimPosition(legend, rangeMax, rangeMin, visionRequired)
	visionRequired = visionRequired or true
	rangeMin = rangeMin or 0
	
	local here = legend:GetPosition()
	local there = legend.AimPosition
	
	if visionRequired then
		local delta = (there - here) * Vector3.new(1, 0, 1)
		local ray = Ray.new(here, delta)
		local _, point = legend:Raycast(ray)
		there = Vector3.new(point.X, there.Y, point.Z)
	end
	
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local distance = delta.Magnitude
	local direction = delta / distance
	
	distance = math.clamp(distance, rangeMin, rangeMax)
	local clampedPosition = here + direction * distance
	
	return Vector3.new(
		clampedPosition.X,
		there.Y,
		clampedPosition.Z
	)
end

function TargetingService:IsVisible(target, position, visionDisabled)
	if visionDisabled then return true end
	
	local here = target:GetPosition()
	local there = position
	local delta = (there - here) * Vector3.new(1, 0, 1)
	there = here + delta
	
	return target:CanSeePoint(there)
end

function TargetingService:TargetCone(targets, args)
	local cframe = args.CFrame
	local angleLimit = args.Angle
	local rangeSq = args.Range ^ 2
	local callback = args.Callback
	
	for _, target in pairs(targets) do
		local delta = target:GetPosition() - cframe.Position
		local angle = math.deg(math.acos(cframe.LookVector:Dot(delta.Unit)))
		if angle < angleLimit then
			local distanceSq = delta.X ^ 2 + delta.Z ^ 2
			if distanceSq <= rangeSq then
				if self:IsVisible(target, cframe.Position, args.VisionDisabled) then
					local data = {
						DistanceSq = distanceSq,
						Angle = angle,
					}
					callback(target, data)
				end
			end
		end
	end
end

function TargetingService:TargetCircle(targets, args)
	local position = args.Position
	local rangeSq = args.Range ^ 2
	local callback = args.Callback

	for _, target in pairs(targets) do
		local delta = target:GetPosition() - position
		local distanceSq = delta.X ^ 2 + delta.Z ^ 2
		if distanceSq <= rangeSq then
			if self:IsVisible(target, position, args.VisionDisabled) then
				local data = {
					DistanceSq = distanceSq,
					DistanceRatio = distanceSq / rangeSq,
				}
				callback(target, data)
			end
		end
	end
end

function TargetingService:TargetRing(targets, args)
	local position = args.Position
	local rangeInnerSq = args.RangeInner ^ 2
	local rangeOuterSq = args.RangeOuter ^ 2
	local callback = args.Callback

	for _, target in pairs(targets) do
		local delta = target:GetPosition() - position
		local distanceSq = delta.X ^ 2 + delta.Z ^ 2
		if (distanceSq >= rangeInnerSq) and (distanceSq <= rangeOuterSq) then
			if self:IsVisible(target, position, args.VisionDisabled) then
				callback(target)
			end
		end
	end
end

function TargetingService:TargetCircleNearest(targets, args)
	local position = args.Position
	local rangeSq = args.Range ^ 2
	local callback = args.Callback
	
	local best = nil
	local bestRange = rangeSq

	for _, target in pairs(targets) do
		local delta = target:GetPosition() - position
		local distanceSq = delta.X ^ 2 + delta.Z ^ 2
		if distanceSq <= bestRange then
			if self:IsVisible(target, position, args.VisionDisabled) then
				bestRange = distanceSq
				best = target
			end
		end
	end
	
	if best then
		callback(best)
	end
end

function TargetingService:TargetMeleeNearest(targets, args)
	local width = args.Width
	local length = args.Length
	local cframe = args.CFrame
	local callback = args.Callback
	
	local squareCFrame = cframe * CFrame.new(0, 0, -length / 2)
	
	local bestTarget
	local bestDistance = length
	
	for _, target in pairs(targets) do
		local delta = cframe:PointToObjectSpace(target:GetPosition())
		
		local inX = math.abs(delta.X) < (width / 2)
		local inZ = (-delta.Z >= 0) and (-delta.Z <= length)
		
		if inX and inZ then
			local distance = -delta.Z
			if distance < bestDistance then
				if self:IsVisible(target, cframe.Position, args.VisionDisabled) then
					bestDistance = distance
					bestTarget = target
				end
			end
		end
	end
	
	if bestTarget then
		callback(bestTarget)
	end
end

function TargetingService:TargetMelee(targets, args)
	local width = args.Width
	local length = args.Length
	local cframe = args.CFrame * CFrame.new(0, 0, -length / 2)
	local callback = args.Callback
	
	return self:TargetSquare(targets, {
		CFrame = cframe,
		Width = width,
		Length = length,
		Callback = callback,
	})
end

function TargetingService:TargetSquare(targets, args)
	local cframe = args.CFrame
	local width = args.Width
	local length = args.Length
	local callback = args.Callback
	
	local visionPosition
	if args.VisionCentered then
		visionPosition = cframe.Position
	else
		visionPosition = (cframe * CFrame.new(0, 0, length / 2)).Position
	end
	
	for _, target in pairs(targets) do
		local delta = cframe:PointToObjectSpace(target:GetPosition())
		if math.abs(delta.X) < width / 2 and math.abs(delta.Z) < length / 2 then
			
			if self:IsVisible(target, visionPosition, args.VisionDisabled) then
				local data = {
					LengthWeight = -delta.Z / length + 0.5,
					WidthWeight = delta.X / width + 0.5,
				}
				callback(target, data)
			end
		end
	end
end

function TargetingService:TargetWideProjectile(targetsRaw, args)
	local projectile = args.Projectile
	
	local targetDistancePairs = {}
	
	local here = projectile.LastCFrame.Position
	local there = projectile.CFrame.Position
	local delta = (there - here)
	local length = delta.Magnitude
	local midpoint = (here + there) / 2
	local cframe = CFrame.new(midpoint, there)
	
	local lengthFuzz = 2
	
	args.CFrame = cframe
	args.Length = length + lengthFuzz
	args.Callback = function(target, data)
		table.insert(targetDistancePairs, {
			Target = target,
			Distance = data.LengthWeight,
		})
	end
	self:TargetSquare(targetsRaw, args)
	
	table.sort(targetDistancePairs, function(a, b)
		return a.Distance < b.Distance
	end)
	
	local targets = {}
	for _, pair in ipairs(targetDistancePairs) do
		table.insert(targets, pair.Target)
	end
	
	return targets
end

local Singleton = TargetingService:Create()
return Singleton