local Players = game:GetService("Players")

local Super = require(script.Parent)
local InteractableService = Super:Extend()

function InteractableService:OnCreated()
	self.InteractableId = 0
	self.Interactables = {}
	
	self:ConnectRemote("InteractableActivated", self.OnInteractableActivated, true)
end

function InteractableService:CleanInteractables()
	for index = #self.Interactables, 1, -1 do
		local interactable = self.Interactables[index]
		if not interactable.Model:IsDescendantOf(workspace) then
			self:DestroyInteractable(interactable.Id, true)
		end
	end
end

function InteractableService:GetInteractableById(id)
	for index, interactable in pairs(self.Interactables) do
		if interactable.Id == id then
			return interactable, index
		end
	end
	return nil, 0
end

function InteractableService:OnInteractableActivated(player, id)
	local interactable = self:GetInteractableById(id)
	if not interactable then return end
	
	local character = player.Character
	if not character then return end
	local root = character.PrimaryPart
	if not root then return end
	
	local model = interactable.Model
	if not model then return end
	local part = model.PrimaryPart
	if not part then return end
	
	local distance = (part.Position - root.Position).Magnitude
	if distance > interactable.Radius then return end
	
	interactable.Callback(player)
end

function InteractableService:CreateInteractable(args)
	self:CleanInteractables()
	
	local id = self.InteractableId
	self.InteractableId += 1
	
	local interactable = {Id = id}
	for key, val in pairs(args) do
		interactable[key] = val
	end
	
	local function onPlayerAdded(player)
		self:FireRemote("InteractableCreated", player, interactable)
	end
	interactable.PlayerAdded = Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	
	table.insert(self.Interactables, interactable)
	
	return id
end

function InteractableService:DestroyInteractable(id, isFullSweep)
	if isFullSweep == nil then isFullSweep = false end
	
	if not isFullSweep then
		self:CleanInteractables()
	end
	
	local interactable, index = self:GetInteractableById(id)
	if not interactable then return end
	
	table.remove(self.Interactables, index)
	interactable.PlayerAdded:Disconnect()
	
	self:FireRemoteAll("InteractableDestroyed", id)
end

local Singleton = InteractableService:Create()
return Singleton