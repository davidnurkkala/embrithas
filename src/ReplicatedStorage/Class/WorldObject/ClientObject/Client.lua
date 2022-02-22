local Super = require(script.Parent)
local Client = Super:Extend()

function Client:OnCreated()
	-- disable resetting
	spawn(function()
		repeat
			local success, reason = pcall(function()
				game:GetService("StarterGui"):SetCore("ResetButtonCallback", false)
			end)
			if not success then
				wait(0.1)
			end
		until success
	end)
	
	local function i(className)
		print("Initializing "..className)
		self:GetClass(className)
	end
	
	i"InteractableClient"
	i"FacerClient"
	i"EffectsClient"
	i"ControlClient"
	i"TutorialClient"
	i"AnimationClient"
	i"InventoryClient"
	i"QuestClient"
	i"CharacterScreenClient"
	i"ShopClient"
	i"MapClient"
	i"OptionsClient"
	i"NoClimbingClient"
	i"LobbyClient"
	i"DamageIndicatorClient"
	i"CameraClient"
	i"GuiClient"
	
	print("Client fully initialized.")
	
	self:ConnectRemote("ClientScriptRequested", self.OnClientScriptRequested, false)
	self:ConnectRemote("ClientFloorScriptRequested", self.OnClientFloorScriptRequested, false)
end

function Client:OnClientFloorScriptRequested(floorScript, model)
	require(floorScript).Client(self, model)
end

function Client:OnClientScriptRequested(clientScript)
	require(clientScript)
end

local Singleton = Client:Create()
return Singleton