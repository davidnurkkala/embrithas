local GuiService = game:GetService("GuiService")
local function e()
	script.Parent:Destroy()
	GuiService.SelectedObject = nil
end
script.Parent.CloseButton.Activated:Connect(e)
GuiService.SelectedObject = script.Parent.CloseButton