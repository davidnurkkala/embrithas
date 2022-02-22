local Super = require(script.Parent)
local ControlClient = Super:Extend()

local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")

function ControlClient:OnCreated()
	self.AbilitiesActive = {}
	
	self.AbilityInfo = nil
	
	local optionsClient = self:GetService("OptionsClient")
	self.Keybinds = (optionsClient.Options or optionsClient.Updated:Wait()).Keybinds
	optionsClient.Updated:Connect(function(options)
		self.Keybinds = options.Keybinds
	end)
	
	-- this cooldown is here to bridge the gap between client and server
	self.ClientCooldown = self:CreateNew"Cooldown"{Time = 0.25}
	
	self.Storage:WaitForChild("Remotes"):WaitForChild("AbilityInfoUpdated").OnClientEvent:Connect(function(...)
		self:OnAbilityInfoUpdated(...)
	end)
	
	UIS.InputBegan:Connect(function(...)
		self:OnInputBegan(...)
	end)
	
	UIS.InputEnded:Connect(function(...)
		self:OnInputEnded(...)
	end)
	
	spawn(function()
		while true do
			local dt = wait(1/20)
			self:OnUpdated(dt)
		end
	end)
end

function ControlClient:OnAbilityInfoUpdated(abilityInfos)
	self.AbilityInfos = abilityInfos
end

function ControlClient:StartAction(actionName)
	if actionName == "AttackLight" then
		self:FireRemote("WeaponStateChanged", "Light", true)
	elseif actionName == "AttackHeavy" then
		self:FireRemote("WeaponStateChanged", "Heavy", true)
	elseif actionName == "QuickSwitch" then
		self:QuickSwitch()
	elseif actionName == "Celebrate" then
		self:Celebrate()
	elseif actionName == "SheathWeapons" then
		self:SheathWeapons()
	elseif actionName == "Hotbar1" then
		self:StartAbility("1")
	elseif actionName == "Hotbar2" then
		self:StartAbility("2")
	elseif actionName == "Hotbar3" then
		self:StartAbility("3")
	elseif actionName == "Hotbar4" then
		self:StartAbility("4")
	elseif actionName == "Hotbar5" then
		self:StartAbility("5")
	elseif actionName == "Hotbar6" then
		self:StartAbility("6")
	elseif actionName == "Hotbar7" then
		self:StartAbility("7")
	elseif actionName == "Hotbar8" then
		self:StartAbility("8")
	elseif actionName == "Hotbar9" then
		self:StartAbility("9")
	elseif actionName == "Hotbar10" then
		self:StartAbility("10")
	end
end

function ControlClient:StopAction(actionName)
	if actionName == "AttackLight" then
		self:FireRemote("WeaponStateChanged", "Light", false)
	elseif actionName == "AttackHeavy" then
		self:FireRemote("WeaponStateChanged", "Heavy", false)
	elseif actionName == "Hotbar1" then
		self:StopAbility("1")
	elseif actionName == "Hotbar2" then
		self:StopAbility("2")
	elseif actionName == "Hotbar3" then
		self:StopAbility("3")
	elseif actionName == "Hotbar4" then
		self:StopAbility("4")
	elseif actionName == "Hotbar5" then
		self:StopAbility("5")
	elseif actionName == "Hotbar6" then
		self:StopAbility("6")
	elseif actionName == "Hotbar7" then
		self:StopAbility("7")
	elseif actionName == "Hotbar8" then
		self:StopAbility("8")
	elseif actionName == "Hotbar9" then
		self:StopAbility("9")
	elseif actionName == "Hotbar10" then
		self:StopAbility("10")
	end
end

function ControlClient:OnInputBegan(input, sunk)
	if sunk then return end
	
	for actionName, keybind in pairs(self.Keybinds) do
		if input.UserInputType.Name == keybind[1] then
			if (input.KeyCode.Name == keybind[2]) or (not keybind[2]) then
				self:StartAction(actionName)
			end
		end
	end
end

function ControlClient:OnInputEnded(input, sunk)
	if sunk then return end
	
	for actionName, keybind in pairs(self.Keybinds) do
		if input.UserInputType.Name == keybind[1] then
			if (input.KeyCode.Name == keybind[2]) or (not keybind[2]) then
				self:StopAction(actionName)
			end
		end
	end
end

function ControlClient:QuickSwitch()
	self:FireRemote("WeaponSwitched")
end

function ControlClient:Celebrate()
	self:FireRemote("Celebrated")
end

function ControlClient:SheathWeapons()
	self:FireRemote("WeaponsSheathed")
end

function ControlClient:UseAbility(slotNumber)
	if not self.ClientCooldown:IsReady() then return end
	if not self.AbilityInfos then return end
	local abilityInfo = self.AbilityInfos[slotNumber]
	if not abilityInfo then return end
	if abilityInfo.CooldownActive then return end
	
	local clientCooldownTime = 0.25
	
	if abilityInfo.Class ~= "Custom" then
		local ability = self:GetClass(abilityInfo.Class)
		clientCooldownTime = math.min(clientCooldownTime, ability.ClientCooldown)
		
		if ability.OnActivatedClient then
			if not ability:OnActivatedClient(game:GetService("Players").LocalPlayer, abilityInfo) then
				return
			end
		end
	end
	
	self:FireRemote("AbilityActivated", slotNumber)
	self.ClientCooldown:Use(clientCooldownTime)
end

function ControlClient:StartAbility(slotNumber)
	self.AbilitiesActive[slotNumber] = true
end

function ControlClient:StopAbility(slotNumber)
	self.AbilitiesActive[slotNumber] = nil
end

function ControlClient:OnUpdated(dt)
	for slotNumber, _ in pairs(self.AbilitiesActive) do
		self:UseAbility(slotNumber)
	end
end

local Singleton = ControlClient:Create()
return Singleton