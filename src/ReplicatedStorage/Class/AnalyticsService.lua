local GameAnalytics = require(game:GetService("ServerStorage").GameAnalytics)

local Super = require(script.Parent)
local AnalyticsService = Super:Extend()

function AnalyticsService:OnCreated()
	GameAnalytics:initialize({
		build = "1.1.0",
		
		gameKey = "a61298e6003483b9504c5094338d2510",
		secretKey = "a25fb38ab72cde36dba20bf3eb0442229dec8a38",
		
		enableInfoLog = false,
		enableVerboseLog = false,
		
		--debug is by default enabled in studio only
		enableDebugLog = false,
		
		automaticSendBusinessEvents = true,
		reportErrors = true,
		
		availableCustomDimensions01 = {},
		availableCustomDimensions02 = {},
		availableCustomDimensions03 = {},
		availableResourceCurrencies = {},
		availableResourceItemTypes = {},
		availableGamepasses = {}
	})
end

function AnalyticsService:AddProgressionEvent(player, missionId, difficulty, status)
	GameAnalytics:addProgressionEvent(player.UserId, {
		progressionStatus = GameAnalytics.EGAProgressionStatus[status],
		progression01 = missionId,
		progression02 = difficulty,
	})
end

function AnalyticsService:ProcessReceiptInfo(info)
	GameAnalytics:ProcessReceiptCallback(info)
end

function AnalyticsService:AddTeleportData(players, teleportData)
	local playerIds = {}
	for _, player in pairs(players) do
		table.insert(playerIds, player.UserId)
	end
	
	return GameAnalytics:addGameAnalyticsTeleportData(playerIds, teleportData)
end

local Singleton = AnalyticsService:Create()
return Singleton