local HttpService = game:GetService("HttpService")

local BASE_RANDOM = Random.new(tick())

local Class = {}

Class.Storage = game.ReplicatedStorage

function Class:Extend(object)
	object = object or {}
	setmetatable(object, self)
	self.__index = self
	return object
end

function Class:Create(object)
	object = self:Extend(object)
	if object.OnCreated then
		object:OnCreated()
	end
	return object
end

function Class:DictFind(dict, value)
	for key, val in pairs(dict) do
		if val == value then
			return key
		end
	end
end

function Class:GetSuper()
	return getmetatable(self).__index
end

function Class:TableHasValue(t, v)
	for _, val in pairs(t) do
		if val == v then
			return true
		end
	end
	return false
end

function Class:GenerateGuid()
	return HttpService:GenerateGUID(false)
end

function Class:DecodeJson(json)
	return HttpService:JSONDecode(json)
end

function Class:EncodeJson(data)
	return HttpService:JSONEncode(data)
end

function Class:Lerp(a, b, w)
	return a + (b - a) * w
end

function Class:Chance(number, random)
	return (random or BASE_RANDOM):NextInteger(1, 100) < number
end

function Class:Choose(t, random)
	return t[(random or BASE_RANDOM):NextInteger(1, #t)]
end

function Class:RandomFloat(a, b, random)
	return a + (random or BASE_RANDOM):NextNumber() * (b - a)
end

function Class:DeepCopy(t)
	local copy = {}
	for key, val in pairs(t) do
		if typeof(val) == "table" then
			copy[key] = self:DeepCopy(val)
		else
			copy[key] = val
		end
	end
	return copy
end

function Class:RandomSign(random)
	return self:Choose({-1, 1}, random)
end

function Class:DebugMessage(str, ...)
	self:FireRemoteAll("DebugMessaged", string.format(str, ...))
end

function Class:DebugTableValues(t)
	local s = ""
	for key, val in pairs(t) do
		s ..= key.."="..val..", "
	end
	return s
end

function Class:MapVector2(vector2, func)
	return Vector2.new(func(vector2.X), func(vector2.Y))
end

function Class:MapVector3(vector3, func)
	return Vector3.new(func(vector3.X), func(vector3.Y), func(vector3.Z))
end

function Class:FormatTime(seconds)
	local minutes = math.floor(seconds / 60)
	seconds = seconds - minutes * 60
	local hours = math.floor(minutes / 60)
	minutes = minutes - hours * 60
	local remainder = seconds - math.floor(seconds)
	local milliseconds = math.floor(remainder * 1000)
	seconds = math.floor(seconds)
	
	local s = ""
	
	if hours ~= 0 then
		s = hours..":"
	end
	
	if minutes == 0 then
		if hours ~= 0 then
			s = s.."00:"
		else
			s = s.."0:"
		end
	elseif minutes < 10 then
		if hours ~= 0 then
			s = s.."0"..minutes..":"
		else
			s = s..minutes..":"
		end
	else
		s = s..minutes..":"
	end
	
	if seconds == 0 then
		s = s.."00"
	elseif seconds < 10 then
		s = s.."0"..seconds
	else
		s = s..seconds
	end
	
	if milliseconds ~= 0 then
		if milliseconds < 10 then
			s = s..".00"
		elseif milliseconds < 100 then
			s = s..".0"
		else
			s = s.."."
		end
		s = s..milliseconds
	end
	
	return s
end

function Class:SafeTouched(touchPart, callback)
	return touchPart.Touched:Connect(function(part)
		local delta = part.Position - touchPart.Position
		local distanceSq = delta.X ^ 2 + delta.Y ^ 2 + delta.Z ^ 2
		local radius = math.max(touchPart.Size.X, touchPart.Size.Y, touchPart.Size.Z)
		radius += 3
		local radiusSq = radius ^ 2
		
		if distanceSq <= radiusSq then
			callback(part)
		end
	end)
end

function Class:Shuffle(t, random)
	for indexA = 1, #t do
		local indexB = (random or BASE_RANDOM):NextInteger(1, #t)
		local temp = t[indexA]
		t[indexA] = t[indexB]
		t[indexB] = temp
	end
end

function Class:GetClass(className)
	if className == "Class" then
		return Class
	end
	return require(script:FindFirstChild(className, true))
end
Class.GetService = Class.GetClass

function Class:CreateNew(className)
	return function(args)
		return self:GetClass(className):Create(args)
	end
end

function Class:Print(str, ...)
	print(string.format(str, ...))
end

function Class:IsA(class)
	if type(class) == "string" then
		class = self:GetClass(class)
	end
	
	if class == self then
		return true
	end
	
	local super = getmetatable(self)
	while super do
		if super == class then
			return true
		end
		super = getmetatable(super)
	end
	return false
end
Class.IsClass = Class.IsA

function Class:IsServer()
	return game:GetService("RunService"):IsServer()
end

function Class:IsClient()
	return game:GetService("RunService"):IsClient()
end

function Class:IsStudio()
	return game:GetService("RunService"):IsStudio()
end

function Class:GetWorld()
	return self:GetClass"World"
end

function Class:GetRun()
	return Class.Run
end

function Class:GetRemote(remoteName)
	local remote = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(remoteName, 5)
	if not remote then
		error("Could not find remote", remote)
	end
	return remote
end

function Class:ConnectRemote(remoteName, method, serverSided)
	local remote = self:GetRemote(remoteName)
	local event
	
	if serverSided ~= nil then
		if serverSided then
			event = remote.OnServerEvent
		else
			event = remote.OnClientEvent
		end
	else
		if self:IsServer() then
			event = remote.OnServerEvent
		else
			event = remote.OnClientEvent
		end
	end
	
	return event:Connect(function(...)
		method(self, ...)
	end)
end

function Class:FireRemote(remoteName, ...)
	if self:IsServer() then
		self:GetRemote(remoteName):FireClient(...)
	else
		self:GetRemote(remoteName):FireServer(...)
	end
end

function Class:FireRemoteAll(remoteName, ...)
	self:GetRemote(remoteName):FireAllClients(...)
end

function Class:AddConnection(connection)
	if not self.Connections then
		self.Connections = {}
	end
	table.insert(self.Connections, connection)
end

function Class:ForEachWorldObject(worldObjects, callback)
	for index = #worldObjects, 1, -1 do
		local worldObject = worldObjects[index]
		if worldObject.Active then
			callback(worldObject)
		end
		
		-- don't use an else here, we might deactivate
		-- the object in the callback phase and we
		-- can save time for the next call of this
		if not worldObject.Active then
			table.remove(worldObjects, index)
		end
	end
end

function Class:CleanConnections()
	if not self.Connections then return end
	
	for _, connection in pairs(self.Connections) do
		connection:Disconnect()
	end
end

function Class:Raycast(ray, ignoreList, shouldIgnoreFunc)
	local part, point, normal, material
	repeat
		local finished = true
		part, point, normal, material = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
		if shouldIgnoreFunc then
			if (part ~= nil) and shouldIgnoreFunc(part) then
				table.insert(ignoreList, part)
				finished = false
			end
		end
	until finished
	return part, point, normal, material
end

function Class:Attempt(tries, func)
	local attemptCount = 1
	while tries > 0 do
		if func() then
			return true, attemptCount
		else
			tries -= 1
			attemptCount += 1
		end
	end
	return false, attemptCount
end

function Class:Tween(object, goals, duration, style, direction, repeats, doesReverse, delayTime)
	local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out, repeats or 0, doesReverse or false, delayTime or 0)
	local tween = game:GetService("TweenService"):Create(object, info, goals)
	tween:Play()
	return tween
end

function Class:TweenNetwork(args)
	self:GetService("EffectsService"):RequestEffectAll("Tween", args)
	return self:Tween(args.Object, args.Goals, args.Duration, args.Style, args.Direction)
end

function Class:GetWeightedResult(weightTable, random)
	if random == nil then random = BASE_RANDOM end
	
	local total = 0
	local choices = {}
	for result, weight in pairs(weightTable) do
		local choice = {
			Result = result,
			Min = total,
			Max = total + weight
		}
		total = choice.Max
		table.insert(choices, choice)
	end
	
	local cursor = random:NextNumber() * total
	for _, choice in pairs(choices) do
		if cursor >= choice.Min and cursor <= choice.Max then
			return choice.Result
		end
	end
	
	-- this shouldn't be possible
	return nil
end

return Class
