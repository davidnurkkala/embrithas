local Super = require(script.Parent)
local TransferGui = Super:Extend()

function TransferGui:OnCreated()
	self.Confirmed = self:CreateNew"Event"()
	
	local gui = self.Storage.UI.TransferFrame:Clone()
	
	local info = self.Info
	
	local categories = gui.CategoriesFrame
	self:InitReward(categories.ItemsFrame, "Battleaxe", "Golden Battleaxe", "Have at least 7 unique rare items.")
	self:InitReward(categories.ItemsFrame, "Sword", "Diamond Longsword", "Have at least 7 unique mythic items.")
	self:InitReward(categories.GoldFrame, "GoldTier1", "Cheer Image: Coins", "Have at least 10,000 gold.")
	self:InitReward(categories.GoldFrame, "GoldTier2", "Cheer Image: Coin Stack", "Have at least 100,000 gold.")
	self:InitReward(categories.GoldFrame, "GoldTier3", "Cheer Image: Coin Bag", "Have at least 1,000,000 gold.")
	self:InitReward(categories.LevelFrame, "Level", "On-hit Effect: 100 Emoji", "Be level 100.")
	self:InitReward(categories.MissionFrame, "Map", "On-hit Effect: Map Emoji", "Have completed at least 1 raid.")
	self:InitReward(categories.MissionFrame, "Telescope", "Giant Spyglass Maul", "Have completed all 3 raids.")
	
	self.CategoriesDeleting = {
		Items = false,
		Gold = false,
		Level = false,
		Mission = false,
	}
	self:InitCheckbox(categories.ItemsFrame, "Items")
	self:InitCheckbox(categories.GoldFrame, "Gold")
	self:InitCheckbox(categories.LevelFrame, "Level")
	self:InitCheckbox(categories.MissionFrame, "Mission")
	
	local confirm = gui.ConfirmButton
	self.ConfirmStage = 1
	
	confirm.Activated:Connect(function()
		if self.ConfirmStage == 3 then
			self.Confirmed:Fire(self.CategoriesDeleting)
			self:Destroy()
			
		elseif self.ConfirmStage == 1 then
			confirm.Visible = false
			wait(1)
			confirm.Text = "Are you sure?"
			confirm.Visible = true
			self.ConfirmStage = 2
			wait(1)
			self.ConfirmStage = 3
			wait(5)
			confirm.Text = "Confirm"
			self.ConfirmStage = 1
		end
	end)
	
	gui.Parent = self.Parent
	self.Gui = gui
end

function TransferGui:Destroy()
	self.Gui:Destroy()
end

function TransferGui:InitCheckbox(frame, key)
	local button = frame.CheckButton
	local warning = frame.WarningLabel
	
	local function update()
		button.Text = self.CategoriesDeleting[key] and "X" or ""
		warning.Visible = not self.CategoriesDeleting[key]
	end
	
	update()
	button.Activated:Connect(function()
		self.CategoriesDeleting[key] = not self.CategoriesDeleting[key]
		update()
	end)
end

function TransferGui:InitReward(parent, name, nameText, unlockText)
	local image = parent:FindFirstChild(name.."Image")
	local label = parent:FindFirstChild(name.."Label")
	
	local unlocked = self.Info[name.."Unlocked"]
	
	image.UnlockLabel.Text = unlocked and "✅" or "❌"
	
	local formatOpen = unlocked and "<b>" or "<b><s>"
	local formatClose = unlocked and "</b>" or "</s></b>"
	label.Text = string.format(
		[[%s%s%s%s]],
		formatOpen,
		nameText,
		formatClose,
		unlocked and "" or "\n"..[[<font color="#999999">]]..unlockText..[[</font>]]
	)
end

return TransferGui