local Super = require(script.Parent)
local OptionsService = Super:Extend()

OptionsService.DefaultOptions = {
	AutoMap = false,
	AutoSalvage = true,
	MusicMuted = false,
	ShowRange = true,
	DisablePlayerGuide = false,
	TrueTopDown = false,
	PlayerListSorting = "Name",
	InviteFilter = "None",
	UIScaling = 1,
	QuestLogHidden = false,
	Keybinds = {
		Inventory = {"Keyboard", "E"},
		Map = {"Keyboard", "V"},
		Character = {"Keyboard", "K"},
		Celebrate = {"Keyboard", "C"},
		QuickSwitch = {"Keyboard", "Q"},
		AttackLight = {"MouseButton1"},
		AttackHeavy = {"Keyboard", "LeftControl"},
		PanCamera = {"MouseButton2"},
		SheathWeapons = {"Keyboard", "G"},
		Hotbar1 = {"Keyboard", "Space"},
		Hotbar2 = {"Keyboard", "LeftShift"},
		Hotbar3 = {"Keyboard", "R"},
		Hotbar4 = {"Keyboard", "F"},
		Hotbar5 = {"Keyboard", "Z"},
		Hotbar6 = {"Keyboard", "X"},
		Hotbar7 = {"Keyboard", "One"},
		Hotbar8 = {"Keyboard", "Two"},
		Hotbar9 = {"Keyboard", "Three"},
		Hotbar10 = {"Keyboard", "Four"},
	},
}

function OptionsService:OnCreated()
	self:ConnectRemote("OptionsUpdated", self.OnOptionsUpdated, true)
end

function OptionsService:OnOptionsUpdated(player, func, ...)
	if func == "RequestUpdate" then
		self:FireRemote("OptionsUpdated", player, self:GetPlayerOptions(player))
	elseif func == "ChangeOption" then
		self:ChangePlayerOption(player, ...)
	end
end

function OptionsService:GetIsValid(option, value)
	if option == "PlayerListSorting" then
		local options = {"Name", "Level", "Health", "Deaths"}
		return (table.find(options, value) ~= nil)
		
	elseif option == "InviteFilter" then
		local options = {"None", "Friends"}
		return (table.find(options, value) ~= nil)
		
	elseif option == "UIScaling" then
		return (value >= 0.1) and (value <= 4)
		
	elseif option == "Keybinds" then
		for key, val in pairs(value) do
			if typeof(key) ~= "string" then return false end
			if typeof(val) ~= "table" then return false end
			if not (#val == 1 or #val == 2) then return false end
			if typeof(val[1]) ~= "string" then return false end
			if val[2] and (typeof(val[2]) ~= "string") then return false end
		end
		return true
		
	else
		return (value == true) or (value == false)
	end
end

function OptionsService:ChangePlayerOption(player, option, value)
	if not self:GetIsValid(option, value) then return end
	
	local options = self:GetPlayerOptions(player) 
	options[option] = value
	self:FireRemote("OptionsUpdated", player, options)
end

function OptionsService:ResetPlayerOptions(player)
	for name, value in pairs(self.DefaultOptions) do
		self:ChangePlayerOption(player, name, value)
	end
end

function OptionsService:GetPlayerOptions(player)
	local playerData = self:GetService("DataService"):GetPlayerData(player)
	
	if not playerData.Options then
		playerData.Options = {}
	end
	
	local options = playerData.Options
	
	for key, val in pairs(self.DefaultOptions) do
		if options[key] == nil then
			options[key] = val
		end
		
		if key == "Keybinds" then
			for key, val in pairs(self.DefaultOptions.Keybinds) do
				if options.Keybinds[key] == nil then
					options.Keybinds[key] = val
				end
			end
		end
	end
	
	return options
end

local Singleton = OptionsService:Create()
return Singleton