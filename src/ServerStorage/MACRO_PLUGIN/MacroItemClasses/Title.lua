-- title macro item

local item = {}

function item:New(itemContainer, macroItem, pluginSettings, updatePluginSettings)
	itemContainer.TextLabel.Text = macroItem.Text
	
	function macroItem:UpdateText(text)
		itemContainer.TextLabel.Text = text
	end
	

	function macroItem:UpdateTheme(theme)
		itemContainer.TextLabel.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end
end

return item
