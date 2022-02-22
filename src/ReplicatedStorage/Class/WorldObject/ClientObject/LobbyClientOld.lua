local Debris = game:GetService("Debris")
local ItemData = require(game.ReplicatedStorage.ItemData)
local DialogueData = require(game.ReplicatedStorage.DialogueData)
local FactionData = require(game.ReplicatedStorage.FactionData)
local ProductData = require(game.ReplicatedStorage.ProductData)
local ChangeLog = require(game.ReplicatedStorage.ChangeLog)

local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local Super = require(script.Parent)
local LobbyClient = Super:Extend()

LobbyClient.IsTutorial = false

function LobbyClient:OnCreated()
	self.MissionExamined = self:CreateNew"Event"()
	self.MissionSelected = self:CreateNew"Event"()
	
	self.InviteQueue = {}
	self.PlayerLevel = 0
	
	-- who are we
	self.Player = game:GetService("Players").LocalPlayer
	
	local function d(m)
		print("Lobby client "..m)
	end
	
	-- get the game gui
	d"waiting for gui"
	self.GameGui = self.Player.PlayerGui:WaitForChild("Gui")
	
	-- set up the lobby gui
	self.LobbyGui = Instance.new("ScreenGui")
	self.LobbyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.LobbyGui.Name = "LobbyGui"
	
	local p = UDim.new(0, 4)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = p
	padding.PaddingBottom = p
	padding.PaddingRight = p
	padding.PaddingLeft = p
	padding.Parent = self.LobbyGui
	
	self.LobbyGui.Parent =  self.Player.PlayerGui
	
	-- interactables
	self.Interactables = {}
	self.GamepadStates = {}
	
	-- get alignment
	d"getting alignment"
	self.Alignment = self.Storage:WaitForChild("Remotes"):WaitForChild("GetPlayerAlignment"):InvokeServer()
	
	-- start updating
	self:GetWorld():AddObject(self)
	
	-- prepare for lobby requests
	d"connecting remotes"
	self:ConnectRemote("LobbyRequested", self.OnLobbyRequested, false)
	self:ConnectRemote("PartyUpdated", self.OnPartyUpdated, false)
	self:ConnectRemote("OpenPartiesUpdated", self.OnOpenPartiesUpdated, false)
	self:ConnectRemote("AlignmentUpdated", self.OnAlignmentUpdated, false)
	self:ConnectRemote("TutorialUpdated", self.OnTutorialUpdated, false)
	self:ConnectRemote("ExpansionPackPrompted", self.OnExpansionPackPrompted, false)
	self:ConnectRemote("ExpansionPackThanked", self.OnExpansionPackThanked, false)
	self:ConnectRemote("UnlimitedThanked", self.OnUnlimitedThanked, false)
	
	-- make our own request
	self:FireRemote("TutorialTried")
	
	d"finished initializing"
end

function LobbyClient:OnAlignmentUpdated(alignment)
	self.Alignment = alignment
end

function LobbyClient:GetPlayerLevel()
	return self:GetClass("GuiClient").Level
end

function LobbyClient:OnLobbyRequested(lobbyModel, playerData, isTutorial)
	self.Model = lobbyModel
	self.PlayerData = playerData
	
	self:InitMissionsButton()
	self:InitOpenPartiesButton()
	self:InitCraftingButton()
	self:InitLoreButton()
	self:InitUpdatesButton()
	self:InitInteractables()
	
	-- miscellaneous billboards
	do
		local bb = self.Storage:WaitForChild("UI"):WaitForChild("ReforgeBillboard")
		bb.Adornee = self.Model.NPCs.Blacksmith.PrimaryPart
		bb.Parent = self.LobbyGui
	end
	
	do
		local bb = self.Storage:WaitForChild("UI"):WaitForChild("RespecBillboard")
		bb.Adornee = self.Model.NPCs.Instructor.PrimaryPart
		bb.Parent = self.LobbyGui
	end
	
	-- player guide?
	if not isTutorial then
		self:GetClass("PlayerGuideClient")
	end
end

function LobbyClient:InitUpdatesButton()
	local billboard = self.Storage:WaitForChild("UI"):WaitForChild("UpdatesBillboard")
	billboard.Adornee = self.Model.Updates.PrimaryPart
	
	billboard.Button.Activated:Connect(function()
		self:ShowChangeLog()
	end)
	
	billboard.Parent = self.LobbyGui
	self.ChangeLogBillboard = billboard
	
	local latest = ChangeLog[1]
	local latestTime = latest.Time
	
	spawn(function()
		while true do
			wait(5)
			
			local now = DateTime.now().UnixTimestampMillis
			local since = now - latestTime
			local hours = since / 1000 / 60 / 60
			billboard.NewLabel.Visible = (hours < 24)
		end
	end)
	
	local frame = self.GameGui:WaitForChild("ChangeLogFrame"):WaitForChild("ContentFrame")
	local template = frame:WaitForChild("TextTemplate")
	
	local height = 0
	
	for index, entry in pairs(ChangeLog) do
		local date = template:Clone()
		date.Visible = true
		date.Font = Enum.Font.GothamBlack
		
		local dt = DateTime.fromUnixTimestampMillis(entry.Time)
		local t = dt:ToLocalTime()
		local hour = t.Hour
		local half = "AM"
		if hour > 12 then
			hour -= 12
			half = "PM"
		end
		date.Text = string.format("%d/%d/%d %d:%d %s", t.Day, t.Month, t.Year, hour, t.Minute, half)
		date.LayoutOrder = index * 2
		date.Parent = frame
		height += date.Size.Y.Offset
		
		local changes = entry.Changes
		if string.sub(changes, 1, 2) == "- " then
			changes = "• "..string.sub(changes, 3)
		end
		changes = string.gsub(entry.Changes, "\n- ", "• ")
		
		local text = template:Clone()
		text.Visible = true
		text.Text = entry.Changes
		text.LayoutOrder = index * 2 + 1
		text.Parent = frame
		while not text.TextFits do
			text.Size += UDim2.new(0, 0, 0, template.Size.Y.Offset)
		end
		height += text.Size.Y.Offset
	end
	
	frame.CanvasSize = UDim2.new(0, 0, 0, height)
end

function LobbyClient:InitCraftingButton()
	local billboard = self.Storage:WaitForChild("UI"):WaitForChild("CraftingBillboard")
	billboard.Adornee = self.Model.CraftingAnvil.PrimaryPart
	
	billboard.Button.Activated:Connect(function()
		self:ShowCrafting()
	end)
	
	billboard.Parent = self.LobbyGui
	self.CraftingBillboard = billboard
end

function LobbyClient:InitLoreButton()
	local billboard = self.Storage:WaitForChild("UI"):WaitForChild("LoreBillboard")
	billboard.Adornee = self.Model.LoreBook.PrimaryPart
	
	billboard.Button.Activated:Connect(function()
		self:ShowLore()
	end)
	
	billboard.Parent = self.LobbyGui
	self.LoreBillboard = billboard
end

function LobbyClient:InitInteractables()
	self.Interactables.MissionTable = self:CreateNew"Interactable"{
		Model = self.Model.MapTable,
		Radius = 16,
		Callback = function()
			self:ShowMissions()
		end,
	}
	
	self.Interactables.CraftingAnvil = self:CreateNew"Interactable"{
		Model = self.Model.CraftingAnvil,
		Radius = 16,
		Callback = function()
			self:ShowCrafting()
		end
	}
	
	self.Interactables.LoreBook = self:CreateNew"Interactable"{
		Model = self.Model.LoreBook,
		Radius = 8,
		Callback = function()
			self:ShowLore()
		end
	}
	
	self.Interactables.OpenParties = self:CreateNew"Interactable"{
		Model = self.Model.OpenParties,
		Radius = 8,
		Callback = function()
			self:ShowOpenParties()
		end
	}
	
	self.Interactables.ChangeLog = self:CreateNew"Interactable"{
		Model = self.Model.Updates,
		Radius = 8,
		Callback = function()
			self:ShowChangeLog()
		end
	}
	
	self.Interactables.Instructor = self:CreateNew"Interactable"{
		Model = self.Model.NPCs.Instructor,
		Radius = 8,
		Offset = Vector3.new(0, -1, 0),
		Callback = function(i)
			self:InstructorDialogue(i)
		end
	}
	
	self.Interactables.Ranger = self:CreateNew"Interactable"{
		Model = self.Model.NPCs.Ranger,
		Radius = 8,
		Offset = Vector3.new(0, -1, 0),
		Callback = function(i)
			self:RangerDialogue(i)
		end,
	}
	
	self.Interactables.ContestKnight = self:CreateNew"Interactable"{
		Model = self.Model.NPCs.ContestKnight,
		Radius = 8,
		Offset = Vector3.new(0, -1, 0),
		Callback = function(i)
			self:ContestDialogue(i)
		end
	}
	
	self.Interactables.Blacksmith = self:CreateNew"Interactable"{
		Model = self.Model.NPCs.Blacksmith,
		Radius = 8,
		Offset = Vector3.new(0, -1, 0),
		Callback = function(i)
			i.Enabled = false
			
			self.ReforgeGui = self:CreateNew"ReforgeGui"{
				SlotDatas = self:GetService("InventoryClient").Inventory.Weapons,
				Parent = self.GameGui,
			}
			self.ReforgeGui.Closed:Connect(function()
				i.Enabled = true
				self.ReforgeGui = nil
			end)
		end
	}

	local dialogueNpcs = {
		{Name = "DrillmasterLeon"},
		{Name = "Adrasta"},
		{Name = "Jeonsa"},
		{Name = "Avery"},
		{Name = "Elle", GetIsActive = function()
			return self:HasCompletedMission("conflagration")
		end},
		{Name = "Jukumai", GetIsActive = function()
			return self:HasCompletedMission("theYawningAbyss")
		end}
	}

	for _, dialogueNpc in pairs(dialogueNpcs) do
		local name = dialogueNpc.Name
		local model = self.Model.NPCs[name]
		local active = (dialogueNpc.GetIsActive == nil) or (dialogueNpc.GetIsActive())

		if active then
			local topic = self:DialogueTopicLastMission()

			-- potential exclamation point
			local bang
			if self:DoesSpeakerHaveImportantLine(name, topic) then
				bang = self.Storage.UI.ExclamationPointBillboard:Clone()
				bang.Parent = model
				bang.Adornee = model.PrimaryPart
			end

			-- set up the interactable
			self.Interactables[name] = self:CreateNew"Interactable"{
				Model = model,
				Radius = 8,
				Offset = Vector3.new(0, -1, 0),
				Callback = function(i)
					-- cancel exclamation point
					if bang then
						bang:Destroy()
						bang = nil
					end

					-- do the dialogue
					i.Enabled = false
					self:ShowLobbyDialogue(name, topic, model.AnimationController:LoadAnimation(model.Talk))
					i.Enabled = true
				end
			}
		else
			model:Destroy()
		end
	end
end

function LobbyClient:HasCompletedMission(missionId)
	for _, entry in pairs(self.PlayerData.MissionLog) do
		if entry.MissionId == missionId and entry.VictoryCount and (entry.VictoryCount > 0) then
			return true
		end
	end
	return false
end

function LobbyClient:DialogueTopicLastMission()
	local lastMission = self.PlayerData.MissionLog[1]
	if lastMission then
		if lastMission.LastResult == "Victory" then
			return lastMission.MissionId
		else
			return "other"
		end
	else
		return "none"
	end
end

function LobbyClient:DoesSpeakerHaveImportantLine(speaker, topic)
	if topic == "other" then return false end
	
	local speaker = DialogueData[speaker]
	local linesByTopic = speaker.LinesByTopic
	local lines = linesByTopic[topic]
	return lines ~= nil
end

function LobbyClient:ShowLobbyDialogue(speaker, topic, animationTrack)
	speaker = DialogueData[speaker]
	
	print(topic)
	
	local linesByTopic = speaker.LinesByTopic
	local lines = linesByTopic[topic]
	if not lines then
		lines = linesByTopic["other"]
	end
	if not lines then
		return
	end
	
	for _, line in pairs(lines) do
		animationTrack:Play()
		self:GetService("EffectsClient"):EffectDialogue{
			Name = speaker.Name,
			Image = speaker.Image,
			Text = line,
		}.Ended:Wait()
	end
end

function LobbyClient:ContestDialogue(i)
	i.Enabled = false
	
	local function dialogue(text)
		self:GetService("EffectsClient"):EffectDialogue{
			Name = "Contest of Slayers Advocate",
			Image = "rbxassetid://5651417472",
			Text = text,
		}.Ended:Wait()
	end
	
	dialogue("Greetings, slayer. Have you heard of the Contest of Slayers?")
	local result = self:GetService("GuiClient"):ShowPrompt("Would you like to learn more about the contest of slayers?", "Yes", "No")
	if result then
		dialogue("The Contest of Slayers is a way for slayers to compete with one another. It takes place on the Great Arch, a curious rock out at sea.")
		dialogue("Two teams of four fight waves of monsters to earn Blood Shards, which can be spent to make the other team's waves more difficult.")
		dialogue("You're not just participating for glory, either. All participants receive some Bloodsteel Ingots -- though the winners earn more.")
		dialogue("I myself have competed many times. It's quite a rush! I'd recommend it to any slayer seeking to test their mettle against other slayers.")
		dialogue("To participate, simply step up to one of the flags behind me. You'll join that team. When we have four slayers on each team, we'll start the match.")
	else
		dialogue("Well, you know the drill. Step up to a flag to join a team! Four on each team and we'll start the match.")
	end
	
	i.Enabled = true
end

function LobbyClient:InstructorDialogue(i)
	i.Enabled = false
	
	local function dialogue(text)
		self:GetService("EffectsClient"):EffectDialogue{
			Name = "Ability Instructor",
			Image = "rbxassetid://5651417472",
			Text = text,
		}.Ended:Wait()
	end
	
	dialogue("Slayer, would you like me to re-train you and refund your stat points?")
	local result = self:GetService("GuiClient"):ShowPrompt("Refund your stat points for 1,000 gold coins?", "Yes", "No")
	
	if not result then
		dialogue("Anytime you'd like re-training, I'll be here.")
	else
		local result, reason = self.Storage.Remotes.TryResetStats:InvokeServer()
		
		if not result then
			if reason == "noData" then
				dialogue("There was a problem retrieving your data. Tell the developer.")
			elseif reason == "gold" then
				dialogue("Unfortunately you don't have the funds. Try going on a few more Lorithas Expeditions to get more gold coins.")
			elseif reason == "zero" then
				dialogue("You're as fresh as the day you joined up. You don't need re-training!")
			end
		else
			dialogue("All right, Slayer. You're as fresh as the day you joined up! Now's your opportunity to try something new.")
		end
	end
	
	i.Enabled = true
end

function LobbyClient:RangerDialogue(i)
	i.Enabled = false

	local function dialogue(text)
		self:GetService("EffectsClient"):EffectDialogue{
			Name = "Norov, Master Ranger",
			Image = "rbxassetid://7034504700",
			Text = text,
		}.Ended:Wait()
	end
	
	local status = self.Storage.Remotes.LobbyRanger:InvokeServer("query")
	if status == "fresh" then
		dialogue("Slayer, I can see it in your eyes. Hawk's eyes. Pinpoint precision. You're a budding ranger, eh? You like slaying from afar, am I right?")
		local result = self:GetService("GuiClient"):ShowPrompt("Would you like to develop your skills as a ranger?", "Yes", "No")
		if result then
			dialogue("That's what I thought, slayer! You and I are alike in this. I will teach you. First, slay some monsters using a ranger's weapon -- a bow or a crossbow. Learn the basics.")
			self.Storage.Remotes.LobbyRanger:InvokeServer("startQuest")
		end
		
	elseif status == "ricochet" then
		dialogue("Ricochet is one of the most important ranger skills. Bouncing your projectiles off multiple targets greatly increases your crowd control capabilities.")
	elseif status == "fan" then
		dialogue("Fan of Projectiles is great for dishing out a lot of damage to all the enemies in front of you, or for a brutal single-target hit at close range. Very versatile!")
	elseif status == "rain" then
		dialogue("Rain of Projectiles can deny the monsters an area and devastate them at choke points. Use it strategically!")
	elseif status == "explosive" then
		dialogue("Explosive Projectile is very interesting. It has a similar area effect to Fan of Projectiles, but you can use it at a much greater distance.")
	elseif status == "barrage" then
		dialogue("Now that you've learned Projectile Barrage, you're nearly a master ranger like me! Well done, slayer!")
	elseif status == "quest" then
		dialogue("You know how to begin, slayer. This is your first step to becoming a master ranger.")
	end

	i.Enabled = true
end

function LobbyClient:InitMissionsButton()
	local billboard = self.Storage:WaitForChild("UI"):WaitForChild("MissionsBillboard")
	billboard.Adornee = self.Model.MapTable.PrimaryPart
	
	billboard.Button.Activated:Connect(function()
		self:ShowMissions()
	end)
	
	billboard.Parent = self.LobbyGui
	self.MissionsBillboard = billboard
end

function LobbyClient:InitOpenPartiesButton()
	local billboard = self.Storage:WaitForChild("UI"):WaitForChild("OpenPartiesBillboard")
	billboard.Adornee = self.Model.OpenParties.PrimaryPart
	
	billboard.Button.Activated:Connect(function()
		self:ShowOpenParties()
	end)
	
	billboard.Parent = self.LobbyGui
	self.OpenPartiesBillboard = billboard
end

function LobbyClient:GetItemData(category, id)
	return require(self.Storage:WaitForChild("ItemData"))[category][id]
end

function LobbyClient:ShowItemDetails(category, itemData)
	local prompt = self.Storage:WaitForChild("UI"):WaitForChild("ItemDetailsPrompt"):Clone()
	
	prompt.NameLabel.Text = itemData.Name
	prompt.CategoryLabel.Text = category
	prompt.Icon.Image = itemData.Image
	
	local description = itemData.Description.."\n"
	if category == "Weapon" then
		local weaponClass = self:GetClass(itemData.Class):Extend()
		weaponClass.Data = itemData
		if itemData.Args then
			for key, val in pairs(itemData.Args) do
				weaponClass[key] = val
			end
		end
		description = weaponClass:GetDescription(self:GetPlayerLevel(), itemData)
		
		if itemData.Perks then
			for _, perk in pairs(itemData.Perks) do
				local s
				if typeof(perk) == "function" then
					s = perk(weaponClass)
				else
					s = perk
				end
				description = description.."\n🔶 "..s
			end
		end
	end
	prompt.DescriptionLabel.Text = description
	
	GuiService:AddSelectionParent("ItemDetailsPrompt", prompt)
	local gamepadPreviousSelectedObject
	
	local function close()
		prompt:Destroy()
		CAS:UnbindAction("GamepadCloseItemDetails")
		GuiService:RemoveSelectionGroup("ItemDetailsPrompt")
		
		if gamepadPreviousSelectedObject then
			GuiService.SelectedObject = gamepadPreviousSelectedObject
		end
	end
	
	prompt.ClickOutButton.Activated:Connect(close)
	prompt.CloseButton.Activated:Connect(close)
	
	CAS:BindAction("GamepadCloseItemDetails", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		
		close()
	end, false, Enum.KeyCode.ButtonB)
	
	prompt.Parent = self.GameGui
	
	if self:IsGamepad() then
		gamepadPreviousSelectedObject = GuiService.SelectedObject
		GuiService.SelectedObject = prompt.CloseButton
	end
end

function LobbyClient:ShowLore()
	self.Interactables.LoreBook.Enabled = false
	self.LoreBillboard.Enabled = false
	
	local frame = self.Storage:WaitForChild("UI"):WaitForChild("LoreFrame"):Clone()
	local contentFrame = frame.ContentFrame
	local contentLabel = contentFrame.ContentLabel
	local booksFrame = frame.BooksFrame
	local titleLabel = frame.TitleLabel
	
	titleLabel.Text = "Select a text..."
	contentLabel.Text = "Lore can be discovered while playing various missions. Explore carefully to find them all!"
	
	local function showLore(loreEntry)
		titleLabel.Text = loreEntry.Title
		contentLabel.Text = loreEntry.Content
		
		local size = game:GetService("TextService"):GetTextSize(
			contentLabel.Text,
			contentLabel.TextSize,
			contentLabel.Font,
			contentLabel.AbsoluteSize
		)
		contentFrame.CanvasPosition = Vector2.new()
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, size.Y * 1.75)
	end
	
	-- acquire and filter lore entries
	local loreEntries = self.Storage.Remotes.GetPlayerLore:InvokeServer()
	
	-- show the list of lore
	for index, loreEntry in pairs(loreEntries) do
		local button = booksFrame.TemplateButton:Clone()
		button.Name = "Button"
		button.Visible = true
		button.Text = loreEntry.Title
		button.Activated:Connect(function()
			showLore(loreEntry)
		end)
		button.Parent = booksFrame
	end
	local padding = booksFrame.UIListLayout.Padding.Offset
	local height = #loreEntries * (booksFrame.TemplateButton.Size.Y.Offset + padding) - padding
	booksFrame.CanvasSize = UDim2.new(0, 0, 0, height)
	
	frame.ClickOutButton.Activated:Connect(function()
		self:HideLore()
	end)
	
	CAS:BindAction("GamepadCloseLore", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		
		self:HideLore()
	end, false, Enum.KeyCode.ButtonB, Enum.KeyCode.E)
	
	self.LoreFrame = frame
	frame.Parent = self.GameGui
end
function LobbyClient:HideLore()
	self.Interactables.LoreBook.Enabled = true
	self.LoreBillboard.Enabled = true
	
	self.LoreFrame:Destroy()
	
	CAS:UnbindAction("GamepadCloseLore")
end

function LobbyClient:ShowCrafting()
	-- disable entrance points
	self.Interactables.CraftingAnvil.Enabled = false
	self.CraftingBillboard.Enabled = false
	
	-- set up the initial frame
	local frame = self.Storage:WaitForChild("UI"):WaitForChild("CraftingFrame"):Clone()
	
	local selectedRecipe = nil
	local requiredItems = nil
	local canCraftRecipe = false
	
	-- amount gui
	local amountGui = self:CreateNew"AmountGui"{
		Gui = frame:WaitForChild("DetailsFrame"):WaitForChild("AmountFrame"),
		MinValue = 1,
	}
	
	-- recipes stuff
	local function clearRecipe()
		selectedRecipe = nil
		
		local detailsFrame = frame.DetailsFrame
		for _, scrollingFrame in pairs{detailsFrame.IngredientsFrame, detailsFrame.ResultsFrame} do
			for _, child in pairs(scrollingFrame:GetChildren()) do
				if child.Name == "Ingredient" then
					child:Destroy()
				end
			end
		end
	end
	
	local function showRecipe(recipe)
		clearRecipe()
		selectedRecipe = recipe
		requiredItems = {}
		canCraftRecipe = true
		
		local repeats = amountGui:GetValue()
		
		local detailsFrame = frame.DetailsFrame
		local ingredientsFrame = detailsFrame.IngredientsFrame
		local resultsFrame = detailsFrame.ResultsFrame
		local template = ingredientsFrame.TemplateFrame
		
		local inventory = self:GetClass("InventoryClient").Inventory
		
		local function showIngredient(ingredient, index, isInput)
			if ingredient.Category == "Gold" then
				local required = ingredient.Amount * repeats
				
				local gui = template:Clone()
				gui.Name = "Ingredient"
				gui.Visible = true
				gui.Icon.Image = "rbxassetid://5272914329"
				gui.NameLabel.Text = "Gold "..inventory.Gold.."/"..required
				
				if inventory.Gold < required then
					gui.NameLabel.TextColor3 = Color3.new(1, 0, 0)
					canCraftRecipe = false
				end
				
				gui.DetailsButton.Activated:Connect(function()
					self:ShowItemDetails("Currency", {
						Name = "Gold",
						Image = gui.Icon.Image,
						Description = "Gold coins. Can be earned by embarking on a Lorithas Expedition at the missions table.",
					})
				end)
				
				gui.Parent = isInput and ingredientsFrame or resultsFrame
				return gui
				
			elseif ingredient.Category == "Alignment" then
				local gui = template:Clone()
				gui.Name = "Ingredient"
				gui.Visible = true
				
				local faction = ingredient.Faction
				local factionData = FactionData[faction]
				local image = factionData.Image
				local name = factionData.Name
				local description = factionData.Description
				gui.Icon.Image = image
				
				if isInput then
					gui.NameLabel.Text = faction.." Alignment "..self.Alignment[faction].."/"..ingredient.Amount
					if self.Alignment[faction] < ingredient.Amount then
						gui.NameLabel.TextColor3 = Color3.new(1, 0, 0)
						canCraftRecipe = false
					end
				else
					local amount = ingredient.Amount * repeats
					
					gui.NameLabel.Text = faction.." Alignment "..amount
					if amount < 0 then
						gui.NameLabel.TextColor3 = Color3.new(1, 0, 0)
					end
				end
				
				gui.DetailsButton.Activated:Connect(function()
					self:ShowItemDetails("Faction Alignment", {Name = name, Image = image, Description = description})
				end)
				
				gui.Parent = isInput and ingredientsFrame or resultsFrame
				return gui
				
			else
				local itemData = self:GetItemData(ingredient.Category, ingredient.Id)
				
				local held = 0
				if isInput then
					for index, slotData in pairs(inventory[ingredient.Category]) do
						local isEquippedWeapon = (ingredient.Category == "Weapons") and ((index == inventory.EquippedWeaponIndex) or (index == inventory.OffhandWeaponIndex))
						
						if (slotData.Id == ingredient.Id) and (not isEquippedWeapon) then
							held = held + (slotData.Amount or 1)
						end
					end
				end
				
				local gui = template:Clone()
				gui.Name = "Ingredient"
				gui.Visible = true
				gui.Icon.Image = itemData.Image
				
				local name = itemData.Name
				if isInput then
					local required = ingredient.Count * repeats
					
					name = name.." "..held.."/"..required
					if held < required then
						gui.NameLabel.TextColor3 = Color3.new(1, 0, 0)
						canCraftRecipe = false
					end
					
					-- the player will have to choose which copies of these items they want to use
					if (ingredient.Category == "Weapons") or (ingredient.Category == "Abilities") then
						table.insert(requiredItems, {
							Category = ingredient.Category,
							Id = ingredient.Id,
							Count = required,
						})
					end
				else
					local amount = ingredient.Count * repeats
					
					if amount > 1 then
						name = name.." x"..amount
					end
				end
				gui.NameLabel.Text = name
				
				gui.DetailsButton.Activated:Connect(function()
					local category
					if ingredient.Category == "Weapons" then
						category = "Weapon"
					elseif ingredient.Category == "Abilities" then
						category = "Ability"
					elseif ingredient.Category == "Materials" then
						category = "Material"
					end
					
					self:ShowItemDetails(category, itemData)
				end)
				
				gui.Parent = isInput and ingredientsFrame or resultsFrame
				return gui
			end
		end
		
		local inputGuis = {}
		for index, input in pairs(recipe.Inputs) do
			table.insert(inputGuis, showIngredient(input, index, true).DetailsButton)
		end
		do
			local padding = ingredientsFrame.UIListLayout.Padding.Offset
			local height = #recipe.Inputs * (template.Size.Y.Offset + padding) - padding
			ingredientsFrame.CanvasSize = UDim2.new(0, 0, 0, height)
		end
		
		local outputGuis = {}
		for index, output in pairs(recipe.Outputs) do
			table.insert(outputGuis, showIngredient(output, index, false).DetailsButton)
		end
		do
			local padding = resultsFrame.UIListLayout.Padding.Offset
			local height = #recipe.Outputs * (template.Size.Y.Offset + padding) - padding
			resultsFrame.CanvasSize = UDim2.new(0, 0, 0, height)
		end
		
		for _, list in pairs{inputGuis, outputGuis} do
			if #list > 1 then
				if #list > 2 then
					for index = 2, #list - 1 do
						list[index].NextSelectionUp = list[index - 1]
						list[index].NextSelectionDown = list[index + 1]
					end
				end
				list[1].NextSelectionDown = list[2]
				list[#list].NextSelectionUp = list[#list - 1]
			end
			
			for _, gui in pairs(list) do
				local debounce = false
				gui.SelectionGained:Connect(function()
					if debounce then return end
					GuiService.SelectedObject = gui.Parent
					debounce = true
					GuiService.SelectedObject = gui
					debounce = false
				end)
			end
		end
		
		if self.IsTutorial then
			spawn(function() self:OnTutorialUpdated("explainRecipe") end)
		end
	end
	
	local gamepadPreviousSelection
	local function hideRecipes()
		local recipesFrame = frame:FindFirstChild("RecipesFrame")
		if recipesFrame then
			recipesFrame.Visible = false
		end
		
		local categoriesFrame = frame:FindFirstChild("CategoriesFrame")
		if categoriesFrame then
			categoriesFrame.Visible = true
		end
		
		CAS:UnbindAction("GamepadCraftingBackToCategories")
		GuiService.SelectedObject = gamepadPreviousSelection
	end
	frame.RecipesFrame.BackButton.Activated:Connect(hideRecipes)
	
	local function showRecipes(recipes)
		frame.RecipesFrame.Visible = true
		frame.CategoriesFrame.Visible = false
		
		local frame = frame.RecipesFrame.ScrollingFrame
		
		for _, child in pairs(frame:GetChildren()) do
			if child.Name == "Recipe" then
				child:Destroy()
			end
		end
		
		local firstButton
		
		for index, recipe in pairs(recipes) do
			local button = frame.TemplateButton:Clone()
			button.Name = "Recipe"
			button.Visible = true
			button.Text = recipe.Name
			button.LayoutOrder = index
			button.Activated:Connect(function()
				showRecipe(recipe)
			end)
			button.Parent = frame
			
			if not firstButton then
				firstButton = button
			end
		end
		
		do
			local padding = frame.UIListLayout.Padding.Offset
			local height = #recipes * (frame.TemplateButton.Size.Y.Offset + padding) - padding
			frame.CanvasSize = UDim2.new(0, 0, 0, height)
		end
		
		gamepadPreviousSelection = GuiService.SelectedObject
		if self:IsGamepad() then
			GuiService.SelectedObject = firstButton
		end
		
		CAS:BindAction("GamepadCraftingBackToCategories", function(name, state, input)
			if state ~= Enum.UserInputState.Begin then return end
			
			hideRecipes()
		end, false, Enum.KeyCode.ButtonB)
		
		if self.IsTutorial then
			spawn(function() self:OnTutorialUpdated("explainRecipes") end)
		end
	end
	
	-- show category list
	local categories = require(self.Storage:WaitForChild("CraftingData")).Categories
	for index, category in pairs(categories) do
		local button = frame.CategoriesFrame.TemplateButton:Clone()
		button.Name = "Recipe"
		button.Visible = true
		button.Text = category.Name
		button.LayoutOrder = index
		button.Activated:Connect(function()
			showRecipes(category.Recipes)
		end)
		button.Parent = frame.CategoriesFrame
	end
	do
		local padding = frame.CategoriesFrame.UIListLayout.Padding.Offset
		local height = #categories * (frame.CategoriesFrame.TemplateButton.Size.Y.Offset + padding) - padding
		frame.CategoriesFrame.CanvasSize = UDim2.new(0, 0, 0, height)
	end
	
	-- refresh the recipe when the amount changes
	amountGui.Updated:Connect(function()
		if selectedRecipe then
			showRecipe(selectedRecipe)
		end
	end)
	
	-- actual crafting button
	local craftButton = frame.DetailsFrame.CraftButton 
	craftButton.Activated:Connect(function()
		if not selectedRecipe then return end
		
		craftButton.Active = false
		
		local succeeded = false
		
		if canCraftRecipe then
			local confirmedAll = true
			local indicesById = {}
			
			for _, requiredItem in pairs(requiredItems) do
				local inventory = self:GetClass("InventoryClient").Inventory
				local itemData = self:GetItemData(requiredItem.Category, requiredItem.Id)
				
				local choices = {}
				for index, slotData in pairs(inventory[requiredItem.Category]) do
					local isEquippedWeapon = (requiredItem.Category == "Weapons") and ((index == inventory.EquippedWeaponIndex) or (index == inventory.OffhandWeaponIndex))
					
					if (slotData.Id == requiredItem.Id) and (not isEquippedWeapon) then
						table.insert(choices, {
							Name = self:GetService("ItemService"):GetItemName(requiredItem.Category, slotData),
							Image = itemData.Image,
							Index = index,
						})
					end
				end
				
				local prompt = self:CreateNew"ItemChoicePromptGui"{
					Choices = choices,
					Parent = self.GameGui,
					ChoiceCountRequired = requiredItem.Count,
				}
				
				local confirmed, indices = prompt.Completed:Wait()
				if confirmed then
					indicesById[requiredItem.Id] = indices
				else
					confirmedAll = false
					break
				end
			end
						
			if confirmedAll and self.Storage.Remotes.CraftRecipe:InvokeServer(selectedRecipe.CategoryIndex, selectedRecipe.Id, amountGui:GetValue(), indicesById) then
				succeeded = true
				showRecipe(selectedRecipe)
			end
		end
		
		if succeeded then
			if self.IsTutorial then
				self:OnTutorialUpdated("congratulateCrafting")
			end
		end
			
		if not succeeded then
			craftButton.BorderColor3 = Color3.new(1, 0, 0)
		end
		
		wait(0.5)
		craftButton.Active = true
		craftButton.BorderColor3 = Color3.new(1, 1, 1)
	end)
	
	-- allow click-out
	frame.ClickOutButton.Activated:Connect(function()
		if not self:TutorialCanCloseCrafting() then return end
		
		self:HideCrafting()
	end)
	
	-- bind for gamepad
	CAS:BindAction("GamepadCloseCrafting", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		
		if not self:TutorialCanCloseCrafting() then return end
		
		self:HideCrafting()
	end, false, Enum.KeyCode.ButtonB, Enum.KeyCode.E)
	
	-- parent it!
	self.CraftingFrame = frame
	frame.Parent = self.GameGui
	
	GuiService:AddSelectionParent("Crafting", frame)
	if self:IsGamepad() then
		for _, child in pairs(frame.CategoriesFrame:GetChildren()) do
			if child:IsA("TextButton") and child.Visible then
				GuiService.SelectedObject = child
				break
			end
		end
	end
	
	if self.IsTutorial then
		spawn(function() self:OnTutorialUpdated("explainAnvil") end)
	end
end
function LobbyClient:HideCrafting()
	self.Interactables.CraftingAnvil.Enabled = true
	self.CraftingBillboard.Enabled = true
	
	self.CraftingFrame:Destroy()
	
	CAS:UnbindAction("GamepadCloseCrafting")
	GuiService:RemoveSelectionGroup("Crafting")
end

function LobbyClient:GetMapCameraCFrame(position)
	local angle = Vector3.new(1, 2, 0)
	
	if not position then
		local there = self.Model.MapTable.PrimaryPart.Position
		local here = there + (angle * 4)
		return CFrame.new(here, there)
	else
		local here = position + (angle * 1.5)
		return CFrame.new(here, position)
	end
end
function LobbyClient:FocusOnMapPosition(position)
	self.CameraTween = self:Tween(
		workspace.CurrentCamera,
		{CFrame = self:GetMapCameraCFrame(position)},
		1
	)
	
	if position then
		local dagger = self.Model.MapTable.Dagger
		
		local goalCFrame =
			CFrame.new(position) *
			CFrame.Angles(math.pi, math.pi * 0.75, 0) *
			CFrame.Angles(0.25, 0, 0) *
			CFrame.new(0, -0.5, 0)
		local liftCFrame = dagger.CFrame * CFrame.new(0, -8, 0)
		local dropCFrame = goalCFrame * CFrame.new(0, -8, 0)
		
		self:Tween(dagger, {CFrame = liftCFrame}, 0.5).Completed:Connect(function()
			dagger.CFrame = dropCFrame
			self:Tween(dagger, {CFrame = goalCFrame}, 0.5, nil, Enum.EasingDirection.In)
		end)
	end
end

function LobbyClient:SetContextActionGuiEnabled(enabled)
	local gui = self.Player.PlayerGui:FindFirstChild("ContextActionGui")
	if gui then
		gui.Enabled = enabled
	end
end

function LobbyClient:GetGuiOffscreen(gui, direction)
	local delta
	local extra = 32
	if direction == "Top" then
		-- extra here because topbar *fortnite default dance*
		delta = UDim2.new(0, 0, 0, -gui.AbsolutePosition.Y - gui.AbsoluteSize.Y - extra - 32)
	elseif direction == "Bottom" then
		delta = UDim2.new(0, 0, 0, gui.AbsoluteSize.Y + extra)
	end
	return gui.Position + delta
end
function LobbyClient:TweenInGui(gui, direction, ...)
	local position = gui.Position
	gui.Position = self:GetGuiOffscreen(gui, direction)
	return self:Tween(gui, {Position = position}, ...)
end
function LobbyClient:TweenOutGui(gui, direction, ...)
	return self:Tween(gui, {Position = self:GetGuiOffscreen(gui, direction)}, ...)
end

function LobbyClient:ShowMissions()
	if self.MissionFrame then return end
	
	self.Interactables.MissionTable.Enabled = false
	
	-- if we're in a party it's closed now
	self:LeaveParty()
	
	self.PlayerLevel = self.Storage.Remotes.GetPlayerLevel:InvokeServer()
	
	-- my gui
	self.MissionsBillboard.Active = false
	
	-- camera
	self:GetClass("CameraClient").Enabled = false
	self:FocusOnMapPosition()
	
	-- other guis
	self.GameGui.Enabled = false
	self:SetContextActionGuiEnabled(false)
	
	-- frame
	local missionFrame = self.Storage.UI.MissionFrame:Clone()
	self.MissionFrame = missionFrame
	
	missionFrame.RewardFrame.Visible = false
	
	missionFrame.ClickOutButton.Activated:Connect(function()
		if self.IsTutorial then return end
		
		self:HideMissions()
	end)
	
	missionFrame.Parent = self.LobbyGui
	
	self:TweenInGui(missionFrame.ListFrame, "Top", 1)
	self:TweenInGui(missionFrame.DetailsFrame, "Bottom", 1)
	
	-- show missions in the list
	self:ClearMissionDetails()
	self:ShowMissionList()
	
	if self.IsTutorial then
		delay(2, function() self:OnTutorialUpdated("explainMissions") end)
	end
end

function LobbyClient:GamepadLoadState(state)
	self.GamepadState = state
	
	GuiService:AddSelectionParent(state.Name, state.Parent)
	GuiService.SelectedObject = state.Object
end

function LobbyClient:GamepadChangeState(state)
	if self.GamepadState then
		self.GamepadState.Object = GuiService.SelectedObject
	end
	self:GamepadLoadState(state)
	table.insert(self.GamepadStates, self.GamepadState)
end

function LobbyClient:GamepadPopState()
	table.remove(self.GamepadStates, #self.GamepadStates)
	GuiService:RemoveSelectionGroup(self.GamepadState.Name)
	
	if #self.GamepadStates > 0 then
		self:GamepadLoadState(self.GamepadStates[#self.GamepadStates])
		return true
	else
		return false
	end
end

function LobbyClient:GetMissionLogEntry(missionId, difficulty)
	for _, entry in pairs(self.PlayerData.MissionLog) do
		local isMission = entry.MissionId == missionId
		local isDifficulty = (difficulty == nil) or (entry.Difficulty == difficulty)
		if isMission and isDifficulty then
			return entry
		end
	end
	return nil
end

function LobbyClient:IsExpansionOwned(packId)
	local product = require(self.Storage:WaitForChild("ProductData")).Expansion[packId]
	local cosmetics = self:GetService("ShopClient").Cosmetics
	local owned = (cosmetics.IsUnlimited) or (table.find(cosmetics.Purchased, product.ProductId) ~= nil)
	return owned
end

function LobbyClient:ShowMissionList()
	local listFrame = self.MissionFrame.ListFrame
	local missionButton = listFrame.TemplateButton
	
	local missionInfos = self.Storage.Remotes.GetMissionInfos:InvokeServer()
	
	local missionInfoById = {}
	for _, missionInfo in pairs(missionInfos) do
		missionInfoById[missionInfo.Module.Name] = missionInfo
	end
	
	local function setCanvasSize()
		local count = 0
		for _, child in pairs(listFrame:GetChildren()) do
			if child:IsA("TextButton") and child.Visible then
				count = count + 1
			end
		end
		local listPadding = listFrame.UIListLayout.Padding.Offset
		local padding = listFrame.UIPadding.PaddingTop.Offset + listFrame.UIPadding.PaddingBottom.Offset
		local height = count * (missionButton.Size.Y.Offset + listPadding) - listPadding + padding
		listFrame.CanvasSize = UDim2.new(0, 0, 0, height)
	end
	
	local layoutOrder = 0
	local firstButton
	local function showMissionDataObject(object, isSubButton)
		local button = missionButton:Clone()
		button.Name = "Button"
		button.Visible = not isSubButton
		button.LayoutOrder = layoutOrder
		
		if isSubButton then
			button.Size = button.Size + UDim2.new(0, -20, 0, 0)
		end
		
		layoutOrder = layoutOrder + 1
		
		if typeof(object) == "string" then
			local missionInfo = missionInfoById[object]
			local mission = require(missionInfo.Module)
			if mission.Hidden then return end
			
			button.Text = mission.Name
			
			if #missionInfo.UnmetRequirements > 0 then
				button.LabelsFrame.LockedLabel.Visible = true
			end
			
			if mission.RequiredExpansion and (not self:IsExpansionOwned(mission.RequiredExpansion)) then
				button.LabelsFrame.PurchaseLabel.Visible = true
			end
			
			if self:HasCompletedMission(missionInfo.Module.Name) then
				button:WaitForChild("CompletedLabel").Visible = true
			end
			
			button.Activated:Connect(function()
				self:ShowMissionDetails(missionInfo)
				
				if self:IsGamepad() then
					self:GamepadChangeState({
						Name = "MissionDetails",
						Object = self.MissionFrame.DetailsFrame.SelectButton,
						Parent = self.MissionFrame.DetailsFrame,
					})
				end
			end)
			
		elseif typeof(object) == "table" then
			button.Text = object.Name
			button.BorderSizePixel = 3
			
			local children = {}
			for _, missionName in pairs(object.Missions) do
				table.insert(children, showMissionDataObject(missionName, true))
			end
			
			button.Activated:Connect(function()
				for _, child in pairs(children) do
					child.Visible = not child.Visible
				end
				setCanvasSize()
			end)
		end
		
		if not firstButton then
			firstButton = button
		end
		
		button.Parent = listFrame
		return button
	end
	
	local missionData = require(self.Storage:WaitForChild("MissionData"))
	for _, object in pairs(missionData) do
		showMissionDataObject(object, false)
	end
	
	setCanvasSize()
	
	if self:IsGamepad() then
		self:GamepadChangeState({
			Name = "MissionList",
			Object = firstButton,
			Parent = listFrame
		})
	end
	
	CAS:BindAction("GamepadCloseMissions", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		
		if not self:GamepadPopState() then
			self:HideMissions()
		end
	end, false, Enum.KeyCode.ButtonB)
	
	CAS:BindAction("KeyboardHideMissions", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		
		self:HideMissions()
	end, false, Enum.KeyCode.E)
end

function LobbyClient:IsGamepad()
	return UIS:GetLastInputType() == Enum.UserInputType.Gamepad1
end

function LobbyClient:ShowReward(reward)
	self:HideReward()
	
	local frame = self.MissionFrame.RewardFrame:Clone()
	
	if reward.Type == "Alignment" then
		local faction = reward.Faction
		local name = FactionData[faction].Name
		
		frame.TitleLabel.Text = name
		frame.TypeLabel.Text = "Faction Alignment"
		
		local description = "Your alignment with this faction will change by "..reward.Amount
		if reward.Reason then
			 description = description.." because "..reward.Reason
		else
			description = description.."."
		end
		frame.DescriptionLabel.Text = description
	else
		local item, itemType
		if reward.Type == "Weapon" then
			item = ItemData.Weapons[reward.Id]
			itemType = self:GetClass(item.Class).DisplayName
		elseif reward.Type == "Ability" then
			item = ItemData.Abilities[reward.Id]
			itemType = "Ability"
		elseif reward.Type == "Trinket" then
			item = ItemData.Trinkets[reward.Id]
			itemType = "Trinket"
		elseif reward.Type == "Material" then
			item = ItemData.Materials[reward.Id]
			itemType = "Material"
		elseif reward.Type == "Product" then
			item = ProductData[reward.Category][reward.Id]
			itemType = "Cosmetic "..self:GetClass("ShopClient"):GetDisplayNameFromCategory(reward.Category)
		end
		
		frame.TitleLabel.Text = item.Name
		frame.TypeLabel.Text = itemType
		frame.DescriptionLabel.Text = item.Description.."\n\n 🎲 Chance = %"..string.format("%4.1f", reward.Chance * 100)
	end
	
	spawn(function()
		frame.Visible = true
		self:TweenInGui(frame, "Top", 1)
	end)
	
	frame.CloseButton.Activated:Connect(function()
		self:HideReward()
	end)
	
	frame.Parent = self.MissionFrame
	self.RewardFrame = frame
end

function LobbyClient:HideReward()
	local frame = self.RewardFrame
	if not frame then return end
	
	self.RewardFrame = nil
	
	self:TweenOutGui(frame, "Top", 1).Completed:Connect(function()
		frame:Destroy()
	end)
end

function LobbyClient:ClearMissionDetails()
	if not self.MissionFrame then return end
	local frame = self.MissionFrame:WaitForChild("DetailsFrame")
	
	-- remove all floors labels
	for _, child in pairs(frame.FloorsFrame:GetChildren()) do
		if child.Name == "Text" then
			child:Destroy()
		end
	end
	
	if self.MissionDetailsConnections then
		for _, connection in pairs(self.MissionDetailsConnections) do
			connection:Disconnect()
		end
		self.MissionDetailsConnections = nil
	end
	
	-- reset text labels
	frame.TitleLabel.Text = "Select a mission"
	frame.DescriptionLabel.Text = ""
	frame.LevelLabel.Text = ""
	frame.SelectButton.Visible = false
	frame.StatsButton.Visible = false
end

function LobbyClient:GetMissionNameFromId(id)
	local module = self.Storage.Missions:FindFirstChild(id)
	if not module then
		return "[INVALID MISSION ID]"
	end
	return require(module).Name
end

function LobbyClient:GetFactionName(factionId)
	local factionData = require(self.Storage:WaitForChild("FactionData"))
	local faction = factionData[factionId]
	return faction.Name
end

local Difficulties = {
	"Recruit",
	"Rookie",
	"Slayer",
	"Veteran",
	"Hero",
	"Legendary Hero",
}

function LobbyClient:ShowMissionStats(missionId, entry, difficulty)
	if entry == nil then entry = {} end
	
	local mission = require(self.Storage.Missions[missionId])
	local gui = self.Storage:WaitForChild("UI"):WaitForChild("MissionStatsFrame"):Clone()
	
	gui.TitleLabel.Text = mission.Name
	gui.DescriptionLabel.Text = mission.Description
	
	local stats = gui.StatsFrame
	
	if mission.RankingType == "MostFloors" then
		stats.CompletionCount.Label.Text = "Floors Cleared"
		stats.CompletionCount.Value.Text = entry.BestFloors or "N/A"
		
		stats.CompletionTime.Visible = false
	else
		stats.CompletionCount.Value.Text = entry.VictoryCount or 0
		stats.CompletionTime.Value.Text = (entry.BestTime ~= nil) and self:FormatTime(entry.BestTime) or "N/A"
	end

	local showLeaderboard
	local difficultiesFrame = gui.DifficultiesFrame
	local difficultyButtons = {}

	local requestId = 0
	showLeaderboard = function()
		requestId += 1
		local thisRequest = requestId
		
		for diff, button in pairs(difficultyButtons) do
			button.BorderSizePixel = (diff == difficulty) and 3 or 1
		end
		
		local leaderboardData = self.Storage.Remotes.GetMissionLeaderboard:InvokeServer(missionId, difficulty)
		if requestId ~= thisRequest then return end
		
		local leaderboard = gui:WaitForChild("LeaderboardFrame")
		local listLayout = leaderboard:WaitForChild("UIListLayout")

		for _, child in pairs(leaderboard:GetChildren()) do
			if child.Name == "Frame" then
				child:Destroy()
			end
		end
		
		local count = 0
		for rank, data in pairs(leaderboardData) do
			if not leaderboard:FindFirstChild("TemplateFrame") then return end
			
			local frame = leaderboard.TemplateFrame:Clone()
			frame.Name = "Frame"
			frame.Visible = true
			frame.RankLabel.Text = rank
			frame.NameLabel.Text = Players:GetNameFromUserIdAsync(data.key)
			
			local success, image = pcall(function()
				return Players:GetUserThumbnailAsync(data.key, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
			end)
			frame.Icon.Image = success and image or ""
			
			if requestId ~= thisRequest then return end
			
			if mission.RankingType == "MostFloors" then
				frame.ValueLabel.Text = data.value
			else
				frame.ValueLabel.Text = self:FormatTime(data.value / 1000)
			end
			
			frame.LayoutOrder = rank
			frame.Parent = leaderboard
			
			count = count + 1
			local padding = listLayout.Padding.Offset
			local height = count * (frame.Size.Y.Offset + padding) - padding
			leaderboard.CanvasSize = UDim2.new(0, 0, 0, height)
		end
	end
	spawn(function() showLeaderboard() end)
	
	local function onClosed()
		gui:Destroy()
		
		if self:IsGamepad() then
			self:GamepadPopState()
		end
	end
	gui.ClickOutButton.Activated:Connect(onClosed)
	gui.CloseButton.Activated:Connect(onClosed)

	for index, diff in pairs(Difficulties) do
		local button = difficultiesFrame.TemplateButton:Clone()
		button.Visible = true
		button.Name = diff
		button.Text = diff
		button.LayoutOrder = index
		button.Activated:Connect(function()
			onClosed()
			self:ShowMissionStats(missionId, self:GetMissionLogEntry(missionId, diff), diff)
		end)
		button.Parent = difficultiesFrame
		difficultyButtons[diff] = button
	end
	
	gui.Parent = self.LobbyGui
	
	if self:IsGamepad() then
		self:GamepadChangeState({
			Name = "MissionStats",
			Object = gui.CloseButton,
			Parent = gui,
		})
	end
end

function LobbyClient:ShowMissionDetails(missionInfo)
	self:ClearMissionDetails()
	self:HideReward()
	
	local frame = self.MissionFrame.DetailsFrame
	local mission = require(missionInfo.Module)
	
	local entry = self:GetMissionLogEntry(missionInfo.Module.Name, "Rookie")
	
	-- camera
	self:FocusOnMapPosition(mission.MapPosition)
	
	-- text labels
	frame.TitleLabel.Text = mission.Name
	frame.DescriptionLabel.Text = mission.Description
	frame.SelectButton.Visible = true
	frame.StatsButton.Visible = true
	
	frame.LevelLabel.Text = string.format("Level %d", mission.Level)
	frame.LevelLabel.TextColor3 = Color3.new(1, 1, 1)
	
	local playerLevel = self:GetService("GuiClient").Level or 0
	if playerLevel < mission.Level then
		frame.LevelLabel.Text ..= string.format("\n(You are level %d)", playerLevel)
		frame.LevelLabel.TextColor3 = Color3.new(0.85, 0.4, 0)
	end
	
	self.MissionDetailsConnections = {}
	
	table.insert(self.MissionDetailsConnections, frame.StatsButton.Activated:Connect(function()
		self:ShowMissionStats(missionInfo.Module.Name, entry, "Rookie")
	end))
	
	-- floors labels
	local floorsFrame = frame.FloorsFrame
	local floorText = floorsFrame.TemplateText
	
	for index, floor in pairs(mission.Floors) do
		local text = floorText:Clone()
		text.Name = "Text"
		text.Visible = true
		text.LayoutOrder = index
		
		local name
		if floor.Type == "Granular" then
			local size = floor.Args.SizeInChunks
			if size then
				local area = size.X * size.Y
				
				local sizeType = "Small"
				if area > 4 then
					sizeType = "Medium"
				elseif area > 9 then
					sizeType = "Large"
				elseif area > 16 then
					sizeType = "Huge"
				elseif area > 25 then
					sizeType = "Gargantuan"
				end
			
				name = floor.Name.." ("..sizeType.." "..floor.Args.Theme..")"
			else
				name = floor.Name.." ("..floor.Args.Theme..")"
			end
		else
			name = floor.Name
		end
		
		text.Text = name
		text.Parent = floorsFrame
	end
	local padding = floorsFrame.UIPadding.PaddingTop.Offset + floorsFrame.UIPadding.PaddingBottom.Offset
	local listPadding = floorsFrame.UIListLayout.Padding.Offset
	local height = #mission.Floors * (floorText.Size.Y.Offset + listPadding) - listPadding + padding
	floorsFrame.CanvasSize = UDim2.new(0, 0, 0, height)
	
	-- select button
	table.insert(self.MissionDetailsConnections, frame.SelectButton.Activated:Connect(function()
		if mission.RequiredExpansion and (not self:IsExpansionOwned(mission.RequiredExpansion)) then
			self:HideMissions()
			self:OnExpansionPackPrompted(mission.RequiredExpansion)
		else
			self:FireRemote("PartyUpdated", "Requested", missionInfo.Module.Name)
			self:HideMissions()
			self.MissionSelected:Fire()
		end
	end))
	
	if #missionInfo.UnmetRequirements > 0 then
		frame.SelectButton.Visible = false
		
		local s = "Locked. In order to undertake this mission, you must"
		local reqCount = #missionInfo.UnmetRequirements
		
		if reqCount > 2 then
			s = s..": "
		else
			s = s.." "
		end
		
		for index, requirement in pairs(missionInfo.UnmetRequirements) do
			if reqCount > 1 and index == reqCount then
				s = s.."and "
			end
			
			local extraDoubleQuote = false
			
			if requirement.Type == "Level" then
				s = s..string.format("be level %d or higher", requirement.Level)
				
			elseif requirement.Type == "Mission" then
				s = s..string.format("have completed the mission \"%s", self:GetMissionNameFromId(requirement.Id))
				extraDoubleQuote = true
				
			elseif requirement.Type == "Alignment" then
				s = s..string.format("have an alignment of at least %d with the %s", requirement.Amount, self:GetFactionName(requirement.Faction))
			end
			
			if index == reqCount then
				s = s.."."
			elseif reqCount > 2 and index ~= reqCount then
				s = s..","
			end
			
			if extraDoubleQuote then
				s = s.."\""
			end
			
			if index ~= reqCount then
				s = s.." "
			end
		end
		
		frame.DescriptionLabel.Text = s
	else
		frame.SelectButton.Visible = true
	end
	
	-- rewards
	for _, child in pairs(frame.RewardsFrame:GetChildren()) do
		if child.Name == "Button" then
			child:Destroy()
		end
	end
	
	if mission.Rewards then
		for index, reward in pairs(mission.Rewards) do
			local button = frame.RewardsFrame.TemplateButton:Clone()
			button.Name = "Button"
			button.Visible = true
			
			local item
			if reward.Type == "Weapon" then
				item = ItemData.Weapons[reward.Id]
			elseif reward.Type == "Ability" then
				item = ItemData.Abilities[reward.Id]
			elseif reward.Type == "Trinket" then
				item = ItemData.Trinkets[reward.Id]
			elseif reward.Type == "Material" then
				item = ItemData.Materials[reward.Id]
			elseif reward.Type == "Alignment" then
				local faction = reward.Faction
				local image = FactionData[faction].Image
				item = {Image = image}
			elseif reward.Type == "Product" then
				local product = ProductData[reward.Category][reward.Id]
				item = {Image = product.Image}
			end
			
			button.Image = item.Image
			button.LayoutOrder = index
			
			if reward.Amount then
				button.AmountLabel.Visible = true
				button.AmountLabel.Text = reward.Amount
				if reward.Amount < 0 then
					button.AmountLabel.TextColor3 = Color3.new(1, 0, 0)
				end
			end
			
			button.Activated:Connect(function()
				self:ShowReward(reward)
			end)
			
			button.Parent = frame.RewardsFrame
		end
	end
	
	-- cost
	if mission.Cost then
		frame.CostFrame.Visible = true
		frame.CostFrame.AmountLabel.Text = mission.Cost.Gold
	else
		frame.CostFrame.Visible = false
	end
	
	self.MissionExamined:Fire()
end

function LobbyClient:HideMissions()
	if not self.MissionFrame then return end
	
	self.Interactables.MissionTable.Enabled = true
	
	-- my gui
	self.MissionsBillboard.Active = true
	
	-- camera
	if self.CameraTween then
		self.CameraTween:Cancel()
	end
	local duration = 1
	self:GetClass("CameraClient"):ReturnCamera(duration)
	
	-- other guis
	self.GameGui.Enabled = true
	self:SetContextActionGuiEnabled(true)
	
	-- frame
	local missionFrame = self.MissionFrame
	
	self:HideReward()
	self:TweenOutGui(missionFrame.ListFrame, "Top", duration)
	self:TweenOutGui(missionFrame.DetailsFrame, "Bottom", duration)
	Debris:AddItem(missionFrame, duration)
	
	CAS:UnbindAction("GamepadCloseMissions")
	CAS:UnbindAction("KeyboardHideMissions")
	while #self.GamepadStates > 0 do
		self:GamepadPopState()
	end
	
	self.MissionFrame = nil
end

function LobbyClient:OnPartyChanged(info)
	if not self.PartyFrame then
		self:ShowParty()
	end
	self:UpdateParty(info)
end

function LobbyClient:OnPartyKicked()
	self:HideParty()
end

function LobbyClient:OnPartyInviteExpired(leader)
	for index, invite in pairs(self.InviteQueue) do
		if invite.Leader == leader then
			table.remove(self.InviteQueue, index)
			
			if invite.Prompt then
				invite.Prompt.Text.Text = "This invite has expired."
				invite.Prompt.ConfirmButton:Destroy()
				invite.Prompt.CancelButton:Destroy()
				delay(1, function()
					invite.RemovePrompt()
				end)
			end
			
			break
		end
	end
end

function LobbyClient:OnPartyInvited(invite)
	table.insert(self.InviteQueue, invite)
	if self.InviteQueue[1] == invite then
		self:ShowInvite(invite)
	end
end

function LobbyClient:ShowInvite(invite)
	local mission = require(invite.MissionModule)
	
	local prompt = self.Storage.UI.PromptFrame:Clone()
	prompt.ClickOutButton:Destroy()
	prompt.AnchorPoint = Vector2.new(0.5, 0)
	prompt.Position = UDim2.new(0.5, 0, 0, 0)
	prompt.Text.Text = string.format("%s has invited you to the mission \"%s.\"", invite.Leader.Name, mission.Name)
	prompt.ConfirmButton.Text = "Join"
	prompt.ConfirmButton.XboxButtonLabel.Image = "http://www.roblox.com/asset/?id=270302874"
	prompt.CancelButton.Text = "Decline"
	prompt.CancelButton.XboxButtonLabel.Image = "http://www.roblox.com/asset/?id=270302928"
	
	local onAccept, onDecline
	
	CAS:BindAction("InvitePrompt", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		local keyCode = input.KeyCode
		
		if keyCode == Enum.KeyCode.DPadRight then
			onDecline()
		else
			onAccept()
		end
	end, false, Enum.KeyCode.DPadRight, Enum.KeyCode.DPadLeft)
	
	local function removePrompt()
		CAS:UnbindAction("InvitePrompt")
		
		self:TweenOutGui(prompt, "Top", 1).Completed:Connect(function()
			prompt:Destroy()
		end)
	end
	
	local function showNext()
		table.remove(self.InviteQueue, 1)
		if #self.InviteQueue > 0 then
			self:ShowInvite(self.InviteQueue[1])
		end
	end
	
	onAccept = function()
		removePrompt()
		showNext()
		self:FireRemote("PartyUpdated", "InviteAccepted", invite.Leader)
	end
	prompt.ConfirmButton.Activated:Connect(onAccept)
	
	onDecline = function()
		removePrompt()
		showNext()
		self:FireRemote("PartyUpdated", "InviteRejected", invite.Leader)
	end
	prompt.CancelButton.Activated:Connect(onDecline)
	
	invite.Prompt = prompt
	invite.RemovePrompt = removePrompt
	
	self:TweenInGui(prompt, "Top", 1)
	prompt.Parent = self.LobbyGui
end

function LobbyClient:OnPartyEmbarked()
	self:HideParty()
end

function LobbyClient:OnPartyUpdated(func, ...)
	self["OnParty"..func](self, ...)
end

function LobbyClient:LeaveParty()
	if self.PartyFrame then
		self:FireRemote("PartyUpdated", "Left")
		self:HideParty()
	end
end

function LobbyClient:OnOpenPartiesUpdated(openParties)
	if not self.OpenParties then
		self.OpenParties = {}
	end
	
	local function find(parties, partyIn)
		for index, party in pairs(parties) do
			if party.Leader == partyIn.Leader then
				return index
			end
		end
		return nil
	end
	
	local function update(oldParty, newParty)
		for key, val in pairs(newParty) do
			oldParty[key] = val
		end
		if not oldParty.Leader then return end
		
		local gui = oldParty.Gui
		local mission = require(oldParty.MissionModule)
		
		gui.LeftFrame.MissionText.Text = mission.Name
		gui.LeftFrame.NameText.Text = oldParty.Leader.Name
		gui.LeftFrame.DifficultyText.Text = oldParty.Difficulty
		gui.LeftFrame.AmountText.Text = string.format("%d / %d", oldParty.MemberCount, mission.PartySize)
		
		if not oldParty.Qualified then
			gui.JoinButton.Visible = false
			gui.BonusText.Visible = true
			gui.BonusText.Text = "Unqualified"
		end
	end
	
	local frame = self.OpenPartiesFrame
	if not frame then return end
	
	for index = #self.OpenParties, 1, -1 do
		local party = self.OpenParties[index]
		if not find(openParties, party) then
			if GuiService.SelectedObject == party.Gui.JoinButton then
				local backup = self.OpenParties[index - 1]
				if backup then
					GuiService.SelectedObject = backup.Gui.JoinButton
				else
					backup = self.OpenParties[index + 1]
					if backup then
						GuiService.SelectedObject = backup.Gui.JoinButton
					else
						GuiService.SelectedObject = frame.CloseButton
					end
				end
			end
			
			table.remove(self.OpenParties, index)
			party.Gui:Destroy()
		end
	end
	
	for index, party in pairs(openParties) do
		local oldPartyIndex = find(self.OpenParties, party) 
		if oldPartyIndex then
			local oldParty = self.OpenParties[oldPartyIndex]
			update(oldParty, party)
		else
			local newParty = {}
			
			local gui = frame.PartiesFrame.TemplateFrame:Clone()
			gui.Visible = true
			gui.JoinButton.Activated:Connect(function()
				self:FireRemote("PartyUpdated", "Joined", newParty.Leader)
				self:HideOpenParties()
			end)
			gui.Parent = frame.PartiesFrame
			newParty.Gui = gui
			
			table.insert(self.OpenParties, newParty)
			
			update(newParty, party)
		end
	end
	
	frame.NoPartiesText.Visible = (#self.OpenParties == 0)
	
	local scrollingFrame = frame.PartiesFrame
	local count = 0
	for _, child in pairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") and child.Visible then
			count += 1
		end
	end
	count = math.floor(count / 2)
	local padding = scrollingFrame.UIGridLayout.CellPadding.Y.Offset
	local height = count * (scrollingFrame.UIGridLayout.CellSize.Y.Offset + padding) - padding
	height += scrollingFrame.UIPadding.PaddingTop.Offset + scrollingFrame.UIPadding.PaddingBottom.Offset
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, height)
end

function LobbyClient:HideChangeLog()
	self.ChangeLogBillboard.Enabled = true
	self.Interactables.ChangeLog.Enabled = true
	
	self.GameGui.ChangeLogFrame.Visible = false
end

function LobbyClient:ShowChangeLog()
	self:HideChangeLog()
	
	self.ChangeLogBillboard.Enabled = false
	self.Interactables.ChangeLog.Enabled = false
	
	local frame = self.GameGui.ChangeLogFrame
	frame.Visible = true
	
	local function close()
		self:HideChangeLog()
		CAS:UnbindAction("ChangeLogClose")
		
		if GuiService.SelectedObject then
			GuiService.SelectedObject = nil
		end
	end
	
	frame.ClickOutButton.Activated:Connect(close)
	CAS:BindAction("ChangeLogClose", close, false, Enum.KeyCode.ButtonB)
	
	if self:IsGamepad() then
		GuiService.SelectedObject = frame.ContentFrame
	end
end

function LobbyClient:ShowOpenParties()
	self:HideOpenParties()
	
	self.OpenPartiesBillboard.Enabled = false
	self.Interactables.OpenParties.Enabled = false
	
	local frame = self.Storage.UI.OpenPartiesFrame:Clone()
	
	frame.CloseButton.Activated:Connect(function()
		self:HideOpenParties()
	end)
	
	frame.Parent = self.GameGui
	self.OpenPartiesFrame = frame
	
	if self:IsGamepad() then
		GuiService.SelectedObject = frame.CloseButton
	end
	
	self:FireRemote("OpenPartiesUpdated")
end

function LobbyClient:HideOpenParties()
	if not self.OpenPartiesFrame then return end
	
	self.OpenPartiesFrame:Destroy()
	self.OpenPartiesFrame = nil
	
	self.OpenParties = {}
	
	self.OpenPartiesBillboard.Enabled = true
	self.Interactables.OpenParties.Enabled = true
end

function LobbyClient:ShowParty()
	if self.PartyFrame then
		self:HideParty()
	end
	
	local frame = self.Storage.UI.PartyFrame:Clone()
	
	frame.CancelButton.Activated:Connect(function()
		self:LeaveParty()
	end)
	
	frame.EmbarkButton.Activated:Connect(function()
		self:FireRemote("PartyUpdated", "Embarked")
	end)
	
	frame.PublicButton.Activated:Connect(function()
		if GuiService.SelectedObject == frame.PublicButton then
			GuiService.SelectedObject = frame.EmbarkButton
		end
		
		self:FireRemote("PartyUpdated", "MadePublic")
	end)

	frame.DifficultyButton.Activated:Connect(function()
		local difficulty = self:CreateNew"DifficultyPromptGui"{
			Parent = self.GameGui
		}.Completed:Wait()
		self:FireRemote("PartyUpdated", "DifficultyChanged", difficulty)
	end)
	
	self:TweenInGui(frame, "Top", 1)
	
	frame.Parent = self.GameGui
	self.PartyFrame = frame
	
	if self:IsGamepad() then
		GuiService.SelectedObject = frame.CancelButton
	end
	
	GuiService:AddSelectionParent("PartyFrame", frame)
end

function LobbyClient:UpdateParty(info)
	if not self.PartyFrame then return end
	local frame = self.PartyFrame
	
	-- collect gamepad information
	local gamepadPreviousSelection
	local object = GuiService.SelectedObject
	if object and object.Parent then
		if object == frame.EmbarkButton then
			gamepadPreviousSelection = {Type = "Button", Name = "EmbarkButton"}
		elseif object == frame.CancelButton then
			gamepadPreviousSelection = {Type = "Button", Name = "CancelButton"}
		elseif object.Parent.Parent == frame.PartyFrame then
			gamepadPreviousSelection = {Type = "List", Name = "PartyFrame", LayoutOrder = object.Parent.LayoutOrder}
		elseif object.Parent.Parent == frame.PlayersFrame then
			gamepadPreviousSelection = {Type = "List", Name = "PlayersFrame", LayoutOrder = object.Parent.LayoutOrder}
		end
	end
	
	-- clear old lists
	for _, listFrame in pairs{frame.PartyFrame, frame.PlayersFrame} do
		for _, child in pairs(listFrame:GetChildren()) do
			if child.Name == "Frame" then
				child:Destroy()
			end
		end
	end
	
	local mission = require(info.MissionModule)
	local partySize = #info.Members + #info.Invited
	local partyFull = partySize == mission.PartySize
	
	frame.TitleFrame.CapacityFrame.AmountLabel.Text = string.format("%d / %d", partySize, mission.PartySize)
	
	-- create new lists
	local isLeader = self.Player == info.Members[1]
	
	local count = 0
	for index, member in pairs(info.Members) do
		local f = frame.PartyFrame.TemplateFrame:Clone()
		f.Name = "Frame"
		f.Visible = true
		f.LayoutOrder = count
		f.LeftFrame.NameText.Text = (index == 1 and "⭐" or "")..member.Name
		f.KickButton.Visible = (member ~= self.Player) and isLeader
		f.KickButton.Activated:Connect(function()
			self:FireRemote("PartyUpdated", "Kicked", member)
		end)
		
		if info.ContributionsByMember then
			local contribution = info.ContributionsByMember[tostring(member.UserId)]
			if contribution then
				local cf = f.LeftFrame.ContributionFrame
				cf.Visible = true
				cf.AmountLabel.Text = contribution.Gold
			end
		end
		
		f.Parent = frame.PartyFrame
		count = count + 1
	end
	for _, invited in pairs(info.Invited) do
		local f = frame.PartyFrame.TemplateFrame:Clone()
		f.Name = "Frame"
		f.Visible = true
		f.LayoutOrder = count
		f.LeftFrame.NameText.Text = invited.Name.." (Invited)"
		f.KickButton:Destroy()
		f.Parent = frame.PartyFrame
		count = count + 1
	end
	do
		local list = frame.PartyFrame
		local padding = list.UIPadding.PaddingTop.Offset + list.UIPadding.PaddingBottom.Offset
		local listPadding = list.UIListLayout.Padding.Offset
		local height = count * (list.TemplateFrame.Size.Y.Offset + listPadding) - listPadding + padding
		list.CanvasSize = UDim2.new(0, 0, 0, height)
	end
	
	for _, player in pairs(info.Players) do
		local f = frame.PlayersFrame.TemplateFrame:Clone()
		f.Name = "Frame"
		f.Visible = true
		
		local bonusText = ""
		if not player.CanInvite then
			bonusText = " (Can't Invite)"
		elseif not player.Qualified then
			bonusText = " (Unqualified)"
		end
		f.LeftFrame.NameText.Text = player.Player.Name..bonusText
		
		f.InviteButton.Visible = isLeader and (not partyFull) and player.Qualified and player.CanInvite
		f.InviteButton.Activated:Connect(function()
			self:FireRemote("PartyUpdated", "Invited", player.Player)
		end)
		f.Parent = frame.PlayersFrame
	end
	do
		local list = frame.PlayersFrame
		local padding = list.UIPadding.PaddingTop.Offset + list.UIPadding.PaddingBottom.Offset
		local listPadding = list.UIListLayout.Padding.Offset
		local height = #info.Players * (list.TemplateFrame.Size.Y.Offset + listPadding) - listPadding + padding
		list.CanvasSize = UDim2.new(0, 0, 0, height)
	end

	-- show difficulty
	frame.TitleFrame.DifficultyFrame.TextLabel.Text = info.Difficulty
	
	-- show cost information
	if info.Cost then
		for costName, amount in pairs(info.Cost) do
			if costName == "Gold" then
				local contributed = 0
				for member, contribution in pairs(info.ContributionsByMember) do
					contributed = contributed + contribution.Gold or 0
				end
				
				local costFrame = frame.TitleFrame.CostFrame
				costFrame.Visible = true
				costFrame.AmountLabel.Text = contributed.." / "..amount
				if contributed < amount then
					costFrame.AmountLabel.TextColor3 = Color3.new(1, 0, 0)
				else
					costFrame.AmountLabel.TextColor3 = Color3.new(1, 1, 1)
				end
			end
		end
		
		-- i do not like doing this but i have no better solution in mind
		if self.PartyFrameContributeButtonActivated then
			self.PartyFrameContributeButtonActivated:Disconnect()
			self.PartyFrameContributeButtonActivated = nil
		end
		
		frame.ContributeButton.Visible = true
		self.PartyFrameContributeButtonActivated = frame.ContributeButton.Activated:Connect(function()
			local inventory = self:GetClass("InventoryClient").Inventory
			
			local prompt = self:CreateNew"AmountPromptGui"{
				DefaultValue = 0,
				MinValue = 0,
				MaxValue = inventory.Gold,
				SmallStep = 100,
				LargeStep = 1000,
				PromptText = "How much Gold would you like to contribute?",
				ConfirmText = "Confirm",
				CancelText = "Cancel",
				Parent = self.GameGui,
			}
			
			local result, amount = prompt.Completed:Wait()
			if not result then return end
			
			self:FireRemote("PartyUpdated", "Contributed", {Gold = amount})
		end)
	end
	
	-- embark button? nah
	frame.EmbarkButton.Visible = isLeader
	frame.PublicButton.Visible = isLeader and (not info.IsPublic)
	
	-- convoluted gamepad selection persistence logic
	local gps = gamepadPreviousSelection 
	if gps then
		if gps.Type == "Button" then
			GuiService.SelectedObject = frame[gps.Name]
			
		elseif gps.Type == "List" then
			local list = frame[gps.Name]
			local bestFrame, bestDistance
			for _, frame in pairs(list:GetChildren()) do
				if frame:IsA("Frame") then
					local distance = math.abs(frame.LayoutOrder - gps.LayoutOrder)
					if (bestFrame == nil) or (distance < bestDistance) then
						bestFrame = frame
						bestDistance = distance
					end
				end
			end
			if bestFrame then
				if gps.Name == "PartyFrame" then
					GuiService.SelectedObject = bestFrame.KickButton
				elseif gps.Name == "PlayersFrame" then
					GuiService.SelectedObject = bestFrame.InviteButton
				end
			else
				GuiService.SelectedObject = frame.CancelButton
			end
		end
	end
end

function LobbyClient:HideParty()
	if not self.PartyFrame then return end
	
	local frame = self.PartyFrame
	local duration = 1
	self:TweenOutGui(frame, "Top", duration)
	Debris:AddItem(frame, duration)
	self.PartyFrame = nil
	
	GuiService:RemoveSelectionGroup("PartyFrame")
	GuiService.SelectedObject = nil
end

function LobbyClient:OnUpdated(dt)
	for _, interactable in pairs(self.Interactables) do
		interactable:OnUpdated()
	end
end

function LobbyClient:OnExpansionPackPrompted(packId)
	self:HideMissions()
	
	local productData = require(self.Storage:WaitForChild("ProductData"))
	local product = productData.Expansion[packId]
	
	self:CreateNew"ExpansionPromptGui"{
		Parent = self.GameGui,
		Product = product,
	}
end

function LobbyClient:OnExpansionPackThanked()
	local gui = self.Storage:WaitForChild("UI"):WaitForChild("ExpansionThankFrame")
	local function close()
		gui:Destroy()
	end
	gui.ButtonsFrame.CloseButton.Activated:Connect(close)
	gui.ClickOutButton.Activated:Connect(close)
	gui.Parent = self.GameGui
end

function LobbyClient:OnUnlimitedThanked()
	local gui = self.Storage:WaitForChild("UI"):WaitForChild("UnlimitedThankFrame")
	local function close()
		gui:Destroy()
	end
	gui.ButtonsFrame.CloseButton.Activated:Connect(close)
	gui.ClickOutButton.Activated:Connect(close)
	gui.Parent = self.GameGui
end



-- tutorial stuff
function LobbyClient:Dialogue(text, args)
	args = args or {}
	local data = {
		Name = "???",
		Image = "rbxassetid://5617843718",
		Text = text,
	}
	for key, val in pairs(args) do
		data[key] = val
	end
	
	local EffectsClient = self:GetService("EffectsClient")
	return EffectsClient:EffectDialogue(data)
end

function LobbyClient:HideArrow()
	if self.ArrowGui then
		self.ArrowGui:Destroy()
		self.ArrowGui = nil
	end
end

function LobbyClient:ShowArrow(position, rotation)
	self:HideArrow()
	
	local arrow = self.Storage.UI.ArrowFrame:Clone()
	local sg = Instance.new("ScreenGui")
	arrow.Position = UDim2.new(0, position.X, 0, position.Y)
	arrow.Rotation = rotation
	arrow.Parent = sg
	sg.Parent = self.Player.PlayerGui
	
	spawn(function()
		while sg.Parent do
			local a = Vector3.new(0.5, 0.5, 0.5)
			local b = Vector3.new(1, 1, 1)
			local t = (math.sin(tick() * 8) + 1) / 2
			local c = self:Lerp(a, b, t)
			arrow.Image.ImageColor3 = Color3.new(c.X, c.Y, c.Z)
			wait()
		end
	end)
	
	self.ArrowGui = sg
end

function LobbyClient:TutorialCanCloseCrafting()
	if not self.IsTutorial then
		return true
	end
	if self.TutorialCompletedSteps.congratulateCrafting then
		return true
	end
	
	return false
end

function LobbyClient:OnTutorialUpdated(step)
	if not self.TutorialCompletedSteps then
		self.TutorialCompletedSteps = {}
	end
	if self.TutorialCompletedSteps[step] then return end
	self.TutorialCompletedSteps[step] = true
	
	self.IsTutorial = true
	
	local function blacksmith(args)
		args = args or {}
		args.Name = "Kenny Smivitt, Blacksmith"
		args.Image = "rbxassetid://5637278275"
		return args
	end
	
	local function leon(args)
		args = args or {}
		args.Name = "Drillmaster Leon"
		args.Image = "rbxassetid://5617833593"
		return args
	end
	
	if step == "walkToAnvil" then
		self.D = self:Dialogue("Ho, there, rookie. It would be best if y' learn how to craft and upgrade weapons. Come on over here to the smithy and step up to the anvil.", blacksmith{ManualTiming = true})
		
		local trail = self.Storage:WaitForChild("Models"):WaitForChild("TutorialTrail"):Clone()
		trail.Attachment0 = (self.Player.Character or self.Player.CharacterAdded:Wait()):WaitForChild("UpperTorso"):WaitForChild("ChestAttachment")
		trail.Attachment1 = self.Model:WaitForChild("CraftingAnvil"):WaitForChild("Anvil"):WaitForChild("Attachment")
		trail.Parent = workspace.Effects
		self.TutorialTrail = trail
		
	elseif step == "explainAnvil" then
		self.D:End()
		self.TutorialTrail:Destroy()
		
		for _, button in pairs(self.CraftingFrame.CategoriesFrame:GetChildren()) do
			if button:IsA("TextButton") and button.Visible and button.Text ~= "Basic Weapons" then
				button.Active = false
				button.TextTransparency = 0.5
			end
		end
		
		self.D = self:Dialogue("Start by selecting \"Basic Weapons.\"", blacksmith{ManualTiming = true})
		self:ShowArrow(self.CraftingFrame.CategoriesFrame.TemplateButton.AbsolutePosition)
	
	elseif step == "explainRecipes" then
		self.D:End()
		self:HideArrow()
		
		self.D = self:Dialogue("Here you can see a list of the basic weapons that you can craft. Go ahead and select one.", blacksmith{ManualTiming = true})
		
	elseif step == "explainRecipe" then
		self.D:End()
		
		self.CraftingFrame.RecipesFrame.Visible = false
		self.CraftingFrame.DetailsFrame.CraftButton.Visible = false
		self:ShowArrow(self.CraftingFrame.DetailsFrame.IngredientsFrame.AbsolutePosition)
		self:Dialogue("This is a list of the things you need in order to craft the item you selected.", blacksmith()).Ended:Wait()
		self:ShowArrow(self.CraftingFrame.DetailsFrame.ResultsFrame.AbsolutePosition)
		self:Dialogue("This is a list of the things you'll get from crafting. Usually it's just one thing, but some recipes create more than one item.", blacksmith()).Ended:Wait()
		self:ShowArrow(self.CraftingFrame.DetailsFrame.ResultsFrame:FindFirstChildOfClass("Frame").DetailsButton.AbsolutePosition)
		self:Dialogue("This button will show you extra details about an item. You can read about the item you want to craft and make an informed decision.", blacksmith()).Ended:Wait()
		self:ShowArrow(self.CraftingFrame.DetailsFrame.CraftButton.AbsolutePosition)
		self.CraftingFrame.DetailsFrame.CraftButton.Visible = true
		self.CraftingFrame.RecipesFrame.Visible = true
		self.D = self:Dialogue("Okay. Go ahead and look through the basic weapons and use the \"Details\" button to decide which one you want to craft. When you're ready, hit the \"Craft\" button.", blacksmith{ManualTiming = true})
		
	elseif step == "congratulateCrafting" then
		local inventoryClient = self:GetService("InventoryClient")
		
		self:HideCrafting()
		self:HideArrow()
		self.D:End()
		
		self.D = self:Dialogue("Congratulations, you're the proud owner of a freshly crafted weapon! Now let's learn how to upgrade it. Go ahead and open your inventory.", blacksmith{ManualTiming = true})
		self:ShowArrow(self.GameGui.InventoryButton.AbsolutePosition)
		inventoryClient.Toggled:Wait()
		self.D:End()
		
		if inventoryClient.SelectedTab ~= "Weapons" then
			self.D = self:Dialogue("Select the \"Weapons\" tab.", blacksmith{ManualTiming = true})
			self:ShowArrow(self.GameGui.InventoryFrame.TabsFrame.WeaponsButton.AbsolutePosition)
			inventoryClient.TabSelected:WaitFor("Weapons")
			self.D:End()
		end
		
		self.D = self:Dialogue("Select your new weapon.", blacksmith{ManualTiming = true})
		local children = self.GameGui.InventoryFrame.ContentFrame:GetChildren() 
		self:ShowArrow(children[#children].AbsolutePosition)
		inventoryClient.ItemSelected:Wait()
		self.D:End()
		
		self.D = self:Dialogue("This is the \"Upgrade\" button. Notice that when you hover this button, it shows you how many materials you need to upgrade it. Go ahead and upgrade your weapon now.", blacksmith{ManualTiming = true, Position = "Top"})
		self:ShowArrow(self.GameGui.InventoryFrame.DetailsFrame.ButtonsFrame.UpgradeButton.AbsolutePosition)
		inventoryClient.ItemUpgraded:Wait()
		self.D:End()
		self:HideArrow()
		self:Dialogue("Congratulations! Your weapon is now a higher level, meaning it deals better damage. Feel free to upgrade it as much as you can.", blacksmith()).Ended:Wait()
		
		local trail = self.Storage:WaitForChild("Models"):WaitForChild("TutorialTrail"):Clone()
		trail.Attachment0 = (self.Player.Character or self.Player.CharacterAdded:Wait()):WaitForChild("UpperTorso"):WaitForChild("ChestAttachment")
		trail.Attachment1 = self.Model:WaitForChild("MapTable"):WaitForChild("Map"):WaitForChild("Attachment")
		trail.Parent = workspace.Effects
		self.TutorialTrail = trail
		self.D = self:Dialogue("All right, slayer. Now that you've got a better weapon, it's time to get you on a real mission. Head on over to the war room and take a look at the Missions table.", leon{ManualTiming = true})
		
	elseif step == "explainMissions" then
		local scale = self.GameGui.UIScale.Scale
		
		self.D:End()
		self.TutorialTrail:Destroy()
		
		local button
		for _, child in pairs(self.MissionFrame.ListFrame:GetChildren()) do
			if child:IsA("TextButton") and child.Text == "Rookie's Grave" then
				button = child
				break
			end
		end
		self:ShowArrow(button.AbsolutePosition)
		
		self.D = self:Dialogue("Here's where you'll see the missions you can embark on. Some are locked because you aren't experienced or haven't completed the required missions. For now, let's take a look at \"Rookie's Grave.\" Oh, and don't let the name bother you.", leon{ManualTiming = true, Parent = self.LobbyGui, Scale = scale, Position = "Top"})
		self.MissionExamined:Wait()
		self.D:End()
		
		self:ShowArrow(self.MissionFrame.DetailsFrame.SelectButton.AbsolutePosition)
		self.D = self:Dialogue("Now click the \"Select\" button.", leon{ManualTiming = true, Parent = self.LobbyGui, Scale = scale, Position = "Top"})
		self.MissionSelected:Wait()
		self.D:End()
		
		wait(2)
		self:ShowArrow(self.PartyFrame.EmbarkButton.AbsolutePosition)
		self.D = self:Dialogue("Under normal circumstances, you could form a party now. However, I think it's best if you take on Rookie's Grave by yourself to start. Go ahead and click \"Start.\"", leon{ManualTiming = true})
	end
end

local Singleton = LobbyClient:Create()
return Singleton