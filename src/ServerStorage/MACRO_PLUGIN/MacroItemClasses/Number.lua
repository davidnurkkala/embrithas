-- number macro item

local item = {}

local utilFolder = script.Parent.Parent.Util
local parametricEval = require(utilFolder.ParametricEval)

function item:New(itemContainer, macroItem, pluginSettings, updatePluginSettings)
	itemContainer.TextLabel.Text = macroItem.Text
	local field = itemContainer.Field
	
	local function updateDisplay()
		field.Text = macroItem.Value
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
	
	local function focusLost(enterPressed)
		if enterPressed then
			local number = parametricEval(field.Text)
			if number then
				valueSet(number)
			else
				updateDisplay()
			end
		else
			updateDisplay()
		end
	end
	
	field.FocusLost:Connect(focusLost)
	updateDisplay()	
	
	function macroItem:UpdateTheme(theme)
		itemContainer.TextLabel.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.SubText)
		field.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		field.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
	end
end

return item
