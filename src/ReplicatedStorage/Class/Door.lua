local Super = require(script.Parent)
local Door = Super:Extend()

function Door:OnCreated()
	assert(self.Rooms)
	assert(self.CFrame)
	assert(self.Model)
	
	self:InitModel()
end

function Door:Locked()
	for _, room in pairs(self.Rooms) do
		if room.State == "Completed" then
			return false
		end
	end
	return true
end

function Door:InitModel()
	self.Root = self.Model.PrimaryPart
	
	local door = self.Model
	door:SetPrimaryPartCFrame(self.CFrame)
	
	-- tell maps to have an icon for the door
	--local mapIconNameValue = Instance.new("StringValue")
	--mapIconNameValue.Name = "MapIconName"
	--mapIconNameValue.Value = "Door"
	--mapIconNameValue.Parent = self.Root
	
	local touchedConn
	touchedConn = self:SafeTouched(door.PrimaryPart, function(part)
		--are we unlocked?
		if self:Locked() then return end
		
		--did a legend kick us down?
		local legend = self:GetClass"Legend".GetLegendFromPart(part)
		if not legend then return end
		legend:KickDownDoor(self)
		
		--switch to the debris collision group
		local physicsService = game:GetService("PhysicsService")
		for _, object in pairs(door:GetDescendants()) do
			if object:IsA("BasePart") then
				physicsService:SetPartCollisionGroup(object, "Debris")
			end
		end
		
		--disconnect
		touchedConn:Disconnect()
		
		local function kickDown(door)
			door.Parent = self.Storage.Temp
			game:GetService("Debris"):AddItem(door, 5)
			self:GetService("EffectsService"):RequestEffectAll("KickDownDoor", {
				Door = door,
				KickerPosition = part.Position
			})
		end
		
		if self.Model:FindFirstChild("SubDoors") then
			for _, subDoor in pairs(self.Model.SubDoors:GetChildren()) do
				kickDown(subDoor)
			end
		else
			kickDown(door)
		end
		
		--activate my rooms
		for _, room in pairs(self.Rooms) do
			room:Activate()
		end
		
		-- push away enemies
		self:GetClass("AbilityWarCry"):PushEnemies(self.Model.PrimaryPart.Position, 24)
		
		-- start my dungeon
		self.Dungeon:Start()
		
		-- notify my dungeon that I've been kicked down
		self.Dungeon:OnDoorKickedDown(self)
	end)
		
	door.Parent = self.Dungeon.Model
end

return Door