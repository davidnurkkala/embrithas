local UIS = game:GetService("UserInputService")

local Super = require(script.Parent)
local GuiObject = Super:Extend()

function GuiObject:IsGamepad()
	return UIS:GetLastInputType() == Enum.UserInputType.Gamepad1
end

return GuiObject