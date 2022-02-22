local model = script.Parent
local progress = model:WaitForChild("Progress")
local gui = script.CustomProgressFrame:Clone()

local function updateGui()
	gui.Bar.Size = UDim2.new(progress.Value, 0, 1, 0)
	
	if progress.Value <= 0 then
		gui:Destroy()
	end
end
progress.Changed:Connect(updateGui)
updateGui()

gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Gui")

return {}