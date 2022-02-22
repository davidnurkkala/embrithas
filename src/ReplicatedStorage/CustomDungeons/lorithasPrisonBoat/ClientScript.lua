local model = script.Parent
local progress = model:WaitForChild("Progress")
local gui = script.CustomProgressFrame:Clone()

local function updateGui()
	gui.Bar.Size = UDim2.new(progress.Value, 0, 1, 0)
end
progress.Changed:Connect(updateGui)
updateGui()

progress.AncestryChanged:Connect(function()
	if not progress:IsDescendantOf(workspace) then
		gui:Destroy()
	end
end)

gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Gui")

return {}