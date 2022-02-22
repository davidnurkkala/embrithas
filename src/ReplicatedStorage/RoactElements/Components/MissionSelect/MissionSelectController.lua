--[[
	Main controller for the Mission Select screen.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local LocalPlayer = game.Players.LocalPlayer

local main = game.ReplicatedStorage.RoactElements
local GuiObjectContext = require(main.Contexts.GuiObjectContext)
local SelectMissionContext = require(main.Contexts.SelectMissionContext)
local ScaledContents = require(main.Components.Base.ScaledContents)
local MissionSelectMain = require(main.Components.MissionSelect.MissionSelectMain)
local BlackFrameTransition = require(main.Components.Base.BlackFrameTransition)
local ContextAction = require(main.Components.Base.ContextAction)

local MissionSelectController = Roact.PureComponent:extend("MissionSelectController")

function MissionSelectController:init()
	self.state = {
		showOpenTransition = true,
		showCloseTransition = false,
		showContents = false,
	}

	local LobbyClient = GuiObjectContext:GetLobbyClient(self)
	self.missionInfos = LobbyClient.Storage.Remotes.GetMissionInfos:InvokeServer()
	self.missionData = require(LobbyClient.Storage:WaitForChild("MissionData"))

	self.closeMissions = function()
		self:setState({
			showCloseTransition = true,
		})
	end

	self.onOpen = function()
		self:setState({
			showContents = true,
		})
	end

	self.onClose = function()
		LobbyClient:StartHidingMissions()
		self:setState({
			showContents = false,
		})
	end

	self.hideOpen = function()
		self:setState({
			showOpenTransition = false,
		})
	end

	self.hideClose = function()
		LobbyClient:HideMissions()
		self:setState({
			showCloseTransition = false,
		})
	end

	self.selectMission = function(missionId, expansionPack)
		if expansionPack then
			LobbyClient:OnExpansionPackPrompted(expansionPack)
		else
			LobbyClient:FireRemote("PartyUpdated", "Requested", missionId)
			LobbyClient.MissionSelected:Fire()
		end
		self.closeMissions()
	end

	self.onInput = function()
		return Enum.ContextActionResult.Sink
	end
end

function MissionSelectController:render()
	local state = self.state
	local showOpen = state.showOpenTransition
	local showClose = state.showCloseTransition
	local showContents = state.showContents

	return Roact.createElement(Roact.Portal, {
		target = LocalPlayer.PlayerGui,
	}, {
		MissionSelect = Roact.createElement("ScreenGui", {
			DisplayOrder = -1,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, {
			OpenTransition = showOpen and Roact.createElement(BlackFrameTransition, {
				FadeTime = 0.5,
				OnTransition = self.onOpen,
				OnCompleted = self.hideOpen,
			}),

			CloseTransition = showClose and Roact.createElement(BlackFrameTransition, {
				FadeTime = 0.5,
				OnTransition = self.onClose,
				OnCompleted = self.hideClose,
			}),

			-- Sink mouse input
			Modal = showContents and Roact.createElement(ContextAction, {
				InputTypes = {
					Enum.UserInputType.MouseButton1,
					Enum.UserInputType.MouseButton2,
				},
				OnInput = self.onInput,
			}),

			Contents = showContents and Roact.createFragment({
				SelectMission = Roact.createElement(SelectMissionContext.Provider, {
					value = self.selectMission,
				}, {
					Main = Roact.createElement(ScaledContents, {}, {
						MissionSelectMain = Roact.createElement(MissionSelectMain, {
							MissionInfos = self.missionInfos,
							MissionData = self.missionData,
							OnClose = self.closeMissions,
						}),
					}),
				}),
			}),
		}),
	})
end

return MissionSelectController
