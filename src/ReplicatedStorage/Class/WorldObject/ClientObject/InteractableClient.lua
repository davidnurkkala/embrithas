local Super = require(script.Parent)
local InteractableClient = Super:Extend()

function InteractableClient:OnCreated()
	self.Interactables = {}
	
	self:ConnectRemote("InteractableCreated", self.OnInteractableCreated, false)
	self:ConnectRemote("InteractableDestroyed", self.OnInteractableDestroyed, false)
	
	self:GetWorld():AddObject(self)
end

function InteractableClient:OnInteractableCreated(args)
	local properties = {}
	for key, val in pairs(args) do
		properties[key] = val
	end
	properties.Callback = function()
		self:FireRemote("InteractableActivated", args.Id)
	end
	
	local interactable = self:CreateNew"Interactable"(properties)
	table.insert(self.Interactables, interactable)
end

function InteractableClient:OnInteractableDestroyed(id)
	for index, interactable in pairs(self.Interactables) do
		if interactable.Id == id then
			interactable:Destroy()
			table.remove(self.Interactables, index)
			break
		end
	end
end

function InteractableClient:OnUpdated()
	for index = #self.Interactables, 1, -1 do
		local interactable = self.Interactables[index]
		
		if interactable.Model:IsDescendantOf(workspace) then
			interactable:OnUpdated()
		else
			interactable:Destroy()
			table.remove(self.Interactables, index)
		end
	end
end

local Singleton = InteractableClient:Create()
return Singleton