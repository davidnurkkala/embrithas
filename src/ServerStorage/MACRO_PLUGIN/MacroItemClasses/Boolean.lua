-- boolean macro item
local item = {}


function item:New(itemContainer, macroItem, pluginSettings, updatePluginSettings)
	itemContainer.TextLabel.Text = macroItem.Text
	local box = itemContainer.Box
	
	local function updateDisplay()
		box.Text = macroItem.Value and "✓" or ""
	end
	
	local function valueSet(newValue)
		local oldValue = macroItem.Value
		macroItem.Value = newValue
		pluginSettings[macroItem.SettingId] = newValue
		updatePluginSettings()
		updateDisplay()
		if type(macroItem.Changed) == "function" then
			macroItem:Changed(newValue, oldValue)
		end
	end

	function macroItem:Set(value)
		valueSet(value)
	end
	
	function macroItem:UpdateText(text)
		itemContainer.TextLabel.Text = text
	end
	
	local function buttonClick()
		valueSet(not macroItem.Value)
	end
	
	box.MouseButton1Click:Connect(buttonClick)
	updateDisplay()	
	
	function macroItem:UpdateTheme(theme)
		itemContainer.TextLabel.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.SubText)
		box.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		box.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
	end
end

return item
