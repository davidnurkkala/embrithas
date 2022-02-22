--[[

Defaultio 2018

	This is a macro container plugin that makes it easy to make yourself tools to help you on your project.
	
	This is a nice substitute for that big fat "commands" script we all tend to make that contains all our
	frequently used command bar scripts. Instead, you can give each of these commmands a macro for quick
	and easy execution.
	
	~ ~ The plugin just created a folder called MACRO_PLUGIN in ServerStorage. This is where you will put 
	the macro modules you make. Folders referenced below can be found in that folder.
	
	
	--------------------------------------
	------------ EXAMPLES ----------------

	In the Macros folder there are some example macros to get you started. These demonstrate all of the
	available API, which are also listed below.


	--------------------------------------
	------------ INSTRUCTIONS ------------

	1.	When you add a new macro module to the Macros folder, add it to the MacroOrder module table. You 
		can disable a macro without destroying the module by removing it from this list.
	
	2.	If you change a macro, check the CheckMeToRefreshMacros bool value to refresh your macros.

	3.	You can add utility modules you want to share between macros in the Util folder. The path to these
		modules from a macro module is:
	
			script.Parent.Parent.Util[moduleName]
			
	4.	The button module automatically sets ChangeHistoryService waypoints before and after button
		activation so you can undo/redo through your macro functions. However, this functionality is not
		implemented for the Boolean/Numver/String Changed function. If you implement macros that modify
		the datamodel in a macro item changed function, it would be wise to set ChangeHistoryService
		waypoints.
			

	--------------------------------------
	------------ API ---------------------

	Each macro is a module in the macros folder. The module creates and returns a macro object, which has
	a list of its contained macro items.
	
	Usage should be pretty self explanatory from the examples. I suggest you look at those first, but
	here's a comprehensive API list if needed.
	
	
	-------------------
	---- MACRO API ----
	
	Macros have the following API:
	
		1. macro.Items - a list of the macro's macro items in order of appearance
		2. macro:SetVisible(visible) - show or hide the entire macro container


	----------------------------
	---- MACRO ITEM CLASSES ----

	Macro items are GUI line items in each macro container in the plugin widget. The default available
	macro item classes are:
	
		1. Button - a button that can be connected to execute a function
		2. Title - a noninteractive text display
		3. Boolean - a boolean setting
		4. Number - a numeric setting
		5. String - a string setting
		6. Vector3 - a vector3 setting
		
	If needed, you can add custom macro item classes to the MacroItemClasses folder, but these five should
	suit most needs.
		
	
	---------------------------------
	---- SETTING UP A MACRO ITEM ----
		
	See the examples for how to set up macro items. Each is a table with keys:
	
		1. Type - string macro item type (from above list)
		2. Text - label for the macro item
		3. SettingId - only for Boolean/Number/String macro items, this is a unique string identifier used
						to save the state of the macro item input
		4. Value - only for Boolean/Number/String macro items, this is the default value for the macro 
						item input
		
	
	------------------------
	---- MACRO ITEM API ----
	
	Macro items have the following API:
	
		applicable for: Button / Title / Boolean / Number / String / Vector3
		
			1. macroItem:UpdateText(newText) - update the text label for the macro item
			2. macroItem:SetVisible(visible) - show or hide the macro item
			
		applicable for: Button
		
			3. macroItem:Activated() - called when button is clicked
			
		applicable for: Boolean / Number / String / Vector3
		
			4. macroItem:Changed(newValue, oldValue) - called when value is changed
			

--]]