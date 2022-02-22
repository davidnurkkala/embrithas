local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local MarketplaceService = game:GetService("MarketplaceService")

local Super = require(script.Parent)
local ChatService = Super:Extend()

function ChatService:OnCreated()
	spawn(function() self:InitChat() end)
end

function ChatService:InitChat()
	local chatService = require(SSS:WaitForChild("ChatServiceRunner"):WaitForChild("ChatService"))
	
	chatService.SpeakerAdded:Connect(function(playerName)
		local player = Players:FindFirstChild(playerName)
		if not player then return end
		
		local speaker = chatService:GetSpeaker(playerName)
		
		local tags = {}
		
		local success, isUnlimited = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, 11776128)
		end)
		
		if success and isUnlimited then
			table.insert(tags, {TagText = "υ", TagColor = Color3.fromRGB(164, 76, 190)})
		end
		if BadgeService:UserHasBadgeAsync(player.UserId, 2124529476) then
			table.insert(tags, {TagText = "ρα", TagColor = Color3.new(1, 0, 0)})
		elseif BadgeService:UserHasBadgeAsync(player.UserId, 2124539184) then
			table.insert(tags, {TagText = "α", TagColor = Color3.fromRGB(255, 122, 55)})
		elseif BadgeService:UserHasBadgeAsync(player.UserId, 2124570682) then
			table.insert(tags, {TagText = "β", TagColor = Color3.fromRGB(255, 255, 155)})
		end
		speaker:SetExtraData("Tags", tags)
	end)
end

local Singleton = ChatService:Create()
return Singleton