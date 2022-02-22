-- button macro item
local changeHistoryService = game:GetService("ChangeHistoryService")

local item = {}

function item:New(itemContainer, macroItem, pluginSettings, updatePluginSettings)
	itemContainer.Button.Text = macroItem.Text
	
	local debounce = false
	
	local function buttonClicked()
		if debounce then
			return
		end
		debounce = true
		changeHistoryService:SetWaypoint("Macro button preactivate")
		macroItem:Activate()
		changeHistoryService:SetWaypoint("Macro button postactivate")
		debounce = false
	end
	
	function macroItem:UpdateText(text)
		itemContainer.Button.Text = text
	end
	
	itemContainer.Button.MouseButton1Click:Connect(buttonClicked)
	
	function macroItem:UpdateTheme(theme)
		itemContainer.Button.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		itemContainer.Button.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button)
	end
end

return item
