local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Super = require(script.Parent)
local DifficultyPromptGui = Super:Extend()

local Difficulties = {
	"Recruit",
	"Rookie",
	"Slayer",
	"Veteran",
	"Hero",
	"Legendary Hero",
}

function DifficultyPromptGui:ShowDifficulty(difficulty)
	local data = self:GetClass("Run").DifficultyData[difficulty]
	local text = ""

	if data.LootChance then
		text ..= string.format("• Loot chance is %d%%\n", data.LootChance * 100)
	end

	if data.LevelDelta then
		if data.LevelDelta > 0 then
			text ..= string.format("• Enemies are %d levels higher\n", data.LevelDelta)
		else
			text ..= string.format("• Enemies are %d levels lower\n", data.LevelDelta)
		end
	end

	if data.HealthMultiplier then
		text ..= string.format("• Enemies have %d%% health\n", data.HealthMultiplier * 100)
	end

	if data.DamageMultiplier then
		text ..= string.format("• Enemies deal %d%% damage\n", data.DamageMultiplier * 100)
	end
	
	if data.Armor then
		if data.Armor > 0 then
			text ..= string.format("• Enemies resist %d%% of damage\n", data.Armor * 100)
		else
			text ..= string.format("• Enemies take %d%% more damage\n", -data.Armor * 100)
		end
	end

	if data.ExtraSpawns then
		text ..= string.format("• %d - %d more enemies will spawn per room\n", data.ExtraSpawns[1], data.ExtraSpawns[2])
	end

	if data.ModifierChance then
		text ..= string.format("• %d%% of enemies have modifiers\n", data.ModifierChance * 100)
	end
	
	if data.ModifierDoubleChance then
		text ..= string.format("• %d%% chance for enemies with modifiers to have two\n", data.ModifierDoubleChance * 100)
	end
	
	if data.ModifierTripleChance then
		text ..= string.format("• %d%% chance for enemies with modifiers to have three\n", data.ModifierTripleChance * 100)
	end

	if data.EliteChance then
		text ..= string.format("• %d%% of enemies are elite\n", data.EliteChance * 100)
	end

	self.Gui.DescriptionText.Text = text
end

function DifficultyPromptGui:IsGamepad()
	return UIS:GetLastInputType() == Enum.UserInputType.Gamepad1
end

function DifficultyPromptGui:OnCreated()
	self.Completed = self:CreateNew"Event"()
	
	self.Gui = self.Storage:WaitForChild("UI"):WaitForChild("DifficultyPrompt"):Clone()

	local selectedDifficulty = "Rookie"
	local selectedButton
	self:ShowDifficulty(selectedDifficulty)
	
	local buttons = {}
	for index, difficulty in pairs(Difficulties) do
		local button = self.Gui.ChoicesFrame.TemplateButton:Clone()
		button.Text = difficulty
		button.Activated:Connect(function()
			if selectedButton then
				selectedButton.BorderSizePixel = 1
			end
			selectedButton = button
			button.BorderSizePixel = 3
			
			selectedDifficulty = difficulty
			self:ShowDifficulty(difficulty)
		end)
		button.LayoutOrder = index
		button.Visible = true
		button.Parent = self.Gui.ChoicesFrame
		
		table.insert(buttons, button)
	end
	
	local buttonsFrame = self.Gui.ButtonsFrame	
	local function confirm()
		self:Close()
		self.Completed:Fire(selectedDifficulty)
	end
	buttonsFrame.ConfirmButton.Activated:Connect(confirm)
	self.Gui.ClickOutButton.Activated:Connect(confirm)
	
	CAS:BindAction("DifficultyPromptClose", function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		
		self:Close()
	end, false, Enum.KeyCode.ButtonB)
	
	self.Gui.Parent = self.Parent
	
	buttons[#buttons].NextSelectionDown = buttonsFrame.ConfirmButton
	buttonsFrame.ConfirmButton.NextSelectionUp = buttons[#buttons]
	
	self.PreviousSelectedObject = GuiService.SelectedObject
	if self:IsGamepad() then
		GuiService.SelectedObject = buttonsFrame.ConfirmButton
	end
	GuiService:AddSelectionParent("DifficultyPrompt", self.Gui)
end

function DifficultyPromptGui:Close()
	CAS:UnbindAction("DifficultyPromptClose")
	GuiService:RemoveSelectionGroup("DifficultyPrompt")
	GuiService.SelectedObject = self.PreviousSelectedObject
	self.Gui:Destroy()
end

return DifficultyPromptGui