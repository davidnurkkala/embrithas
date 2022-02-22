local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")

local Super = require(script.Parent)
local AmountPromptGui = Super:Extend()

function AmountPromptGui:OnCreated()
	self.Gui = self.Storage:WaitForChild("UI"):WaitForChild("AmountPromptFrame"):Clone()
	
	self.Gui.Text.Text = self.PromptText or self.Gui.Text.Text
	self.Gui.ConfirmButton.Text = self.ConfirmText or self.Gui.ConfirmButton.Text
	self.Gui.CancelButton.Text = self.CancelText or self.Gui.CancelButton.Text
	
	local amountGui = self:CreateNew"AmountGui"{
		Gui = self.Gui:WaitForChild("AmountFrame"),
		DefaultValue = self.DefaultValue,
		MinValue = self.MinValue,
		MaxValue = self.MaxValue,
		SmallStep = self.SmallStep,
		LargeStep = self.LargeStep,
	}
	
	local gamepadPreviousSelectedObject
	
	self.Completed = self:CreateNew"Event"()
	self.Completed:Connect(function()
		self.Gui:Destroy()
		
		if gamepadPreviousSelectedObject then
			GuiService.SelectedObject = gamepadPreviousSelectedObject
		end
		
		GuiService:RemoveSelectionGroup("AmountPromptGui")
		CAS:UnbindAction("CloseAmountPromptGui")
	end)
	
	CAS:BindAction("CloseAmountPromptGui", function(name, state, input)
		self.Completed:Fire(false)
	end, false, Enum.KeyCode.ButtonB)
	
	self.Gui.ConfirmButton.Activated:Connect(function()
		self.Completed:Fire(true, amountGui:GetValue())
	end)
	
	local function onCanceled()
		self.Completed:Fire(false)
	end
	self.Gui.CancelButton.Activated:Connect(onCanceled)
	self.Gui.ClickOutButton.Activated:Connect(onCanceled)
	
	self.Gui.Parent = self.Parent
	
	GuiService:AddSelectionParent("AmountPromptGui", self.Gui)
	if self:IsGamepad() then
		gamepadPreviousSelectedObject = GuiService.SelectedObject
		GuiService.SelectedObject = self.Gui.CancelButton
	end
end

return AmountPromptGui