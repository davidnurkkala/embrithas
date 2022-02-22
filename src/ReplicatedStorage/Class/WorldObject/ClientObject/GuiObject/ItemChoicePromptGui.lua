local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")

local Super = require(script.Parent)
local ItemChoicePromptGui = Super:Extend()

ItemChoicePromptGui.ChoiceCountRequired = 1

function ItemChoicePromptGui:OnCreated()
	self.Gui = self.Storage:WaitForChild("UI"):WaitForChild("ItemChoicePromptFrame"):Clone()
	self.Gui.Parent = self.Parent
	
	self.Chosen = {}
	
	local choicesFrame = self.Gui.ChoicesFrame
	local chosenFrame = self.Gui.ChosenFrame
	
	local function updateCanvasSizes()
		for _, frame in pairs{choicesFrame, chosenFrame} do
			local count = 0
			for _, child in pairs(frame:GetChildren()) do
				if child.Name == "Button" then
					count = count + 1
				end
			end
			
			local padding = frame.UIListLayout.Padding.Offset
			local size = choicesFrame.TemplateButton.Size.Y.Offset
			local height = (size + padding) * count - padding
			frame.CanvasSize = UDim2.new(0, 0, 0, height)
		end
		
		local choiceCount = #self.Chosen
		local needed = self.ChoiceCountRequired - choiceCount
		local label = self.Gui.Text
		
		self.Gui.ConfirmButton.Visible = (needed == 0)
		
		if needed > 0 then
			label.Text = string.format("Choose %d more item%s to use.", needed, (needed > 1) and "s" or "")
		elseif needed < 0 then
			label.Text = string.format("Deselect %d item%s to continue.", -needed, (needed < -1) and "s" or "")
		elseif needed == 0 then
			label.Text = "Are you sure you want to use these items?"
		end
	end
	
	for _, itemData in pairs(self.Choices) do
		local button = choicesFrame.TemplateButton:Clone()
		button.Name = "Button"
		button.Visible = true
		button.Icon.Image = itemData.Image
		button.LevelLabel.Text = ""
		
		button.NameLabel.Text = itemData.Name
		
		button.Activated:Connect(function()
			local choicesIndex = table.find(self.Choices, itemData)
			local chosenIndex = table.find(self.Chosen, itemData)
			
			if choicesIndex then
				table.remove(self.Choices, choicesIndex)
				table.insert(self.Chosen, itemData)
				button.Parent = chosenFrame
			else
				table.remove(self.Chosen, chosenIndex)
				table.insert(self.Choices, itemData)
				button.Parent = choicesFrame
			end
			
			updateCanvasSizes()
		end)
		
		button.Parent = self.Gui.ChoicesFrame
	end
	
	updateCanvasSizes()
	
	local gamepadPreviousSelectedObject
	GuiService:AddSelectionParent("ItemChoicePromptGui", self.Gui)
	
	if self:IsGamepad() then
		gamepadPreviousSelectedObject = GuiService.SelectedObject
		GuiService.SelectedObject = self.Gui.CancelButton
	end
	
	CAS:BindAction("CloseItemChoicePromptGui", function(name, state, input)
		self.Completed:Fire(false)
	end, false, Enum.KeyCode.ButtonB)
	
	self.Completed = self:CreateNew"Event"()
	self.Completed:Connect(function()
		self.Gui:Destroy()
		
		if gamepadPreviousSelectedObject then
			GuiService.SelectedObject = gamepadPreviousSelectedObject
		end
		
		GuiService:RemoveSelectionGroup("ItemChoicePromptGui")
		CAS:UnbindAction("CloseItemChoicePromptGui")
	end)
	
	self.Gui.ConfirmButton.Activated:Connect(function()
		local indices = {}
		for _, chosen in pairs(self.Chosen) do
			table.insert(indices, chosen.Index)
		end
		self.Completed:Fire(true, indices)
	end)
	
	local function onCanceled()
		self.Completed:Fire(false)
	end
	self.Gui.CancelButton.Activated:Connect(onCanceled)
	self.Gui.ClickOutButton.Activated:Connect(onCanceled)
end

return ItemChoicePromptGui