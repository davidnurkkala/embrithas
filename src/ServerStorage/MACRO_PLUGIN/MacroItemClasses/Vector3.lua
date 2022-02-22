-- number macro item

local item = {}

local utilFolder = script.Parent.Parent.Util
local parametricEval = require(utilFolder.ParametricEval)


function item:New(itemContainer, macroItem, pluginSettings, updatePluginSettings)
	itemContainer.TextLabel.Text = macroItem.Text
	local fieldX, fieldY, fieldZ = itemContainer.Field.X, itemContainer.Field.Y, itemContainer.Field.Z
	
	local function updateDisplay()
		fieldX.Text = macroItem.Value.X
		fieldY.Text = macroItem.Value.Y
		fieldZ.Text = macroItem.Value.Z
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
			local x, y, z = parametricEval(fieldX.Text), parametricEval(fieldY.Text), parametricEval(fieldZ.Text)
			if x and y and z then
				valueSet(Vector3.new(x, y, z))
			else
				updateDisplay()
			end
		else
			updateDisplay()
		end
	end
	
	fieldX.FocusLost:Connect(focusLost)
	fieldY.FocusLost:Connect(focusLost)
	fieldZ.FocusLost:Connect(focusLost)
	updateDisplay()	
	
	
	--function macroItem:LoadSetting(storedSetting)
	--	macroItem.Value = Vector3.new(storedSetting[1], storedSetting[2], storedSetting[3])
	--end
	
	function macroItem:UpdateTheme(theme)
		itemContainer.TextLabel.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.SubText)
		fieldX.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		fieldX.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
		fieldY.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		fieldY.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
		fieldZ.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		fieldZ.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
	end
end

return item
