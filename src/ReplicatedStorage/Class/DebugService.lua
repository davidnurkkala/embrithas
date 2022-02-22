local Super = require(script.Parent)
local DebugService = Super:Extend()

local Players = game:GetService("Players")

function DebugService:OnCreated()
	local function onPlayerAdded(...)
		self:OnPlayerAdded(...)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	
	game:GetService("LogService").MessageOut:Connect(function(...)
		self:OnLogMessageOut(...)
	end)
end

function DebugService:OnLogMessageOut(message, messageType)
	if messageType == Enum.MessageType.MessageOutput then return end
	if game:GetService("RunService"):IsStudio() then return end
	
	self:FireRemoteAll("DebugMessaged", message)
end

function DebugService:OnPlayerAdded(player)
	local function onPlayerChatted(...)
		self:OnPlayerChatted(player, ...)
	end
	player.Chatted:Connect(onPlayerChatted)
end

function DebugService:OnPlayerChatted(player, message)
	if message == "/seed" then
		self:FireRemote("DebugMessaged", player, "The current dungeon generated with the following seed:\n\n"..workspace.DungeonSeed.Value)
	elseif message == "/enemyCount" then
		self:FireRemote("DebugMessaged", player, "The game currently recognizes that "..#self:GetClass("Enemy").Instances.." enemies are alive.")
	elseif message == "/roomCompletion" then
		local dungeon = self:GetService("GameService").CurrentRun.Dungeon
		local roomCount = 0
		local completedCount = 0
		local activeCount = 0
		for _, room in pairs(dungeon.Rooms) do
			roomCount = roomCount + 1
			if room.State == "Completed" then
				completedCount = completedCount + 1
			elseif room.State == "Active" then
				activeCount = activeCount + 1
			end
		end
		self:FireRemote("DebugMessaged", player, string.format("This dungeon has %d rooms, %d of which are active and %d of which have been completed.", roomCount, activeCount, completedCount))
	end
end

local Singleton = DebugService:Create()
return Singleton