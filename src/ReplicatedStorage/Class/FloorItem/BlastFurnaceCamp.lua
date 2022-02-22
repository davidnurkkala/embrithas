local Super = require(script.Parent)
local BlastFurnaceCamp = Super:Extend()

BlastFurnaceCamp.MaxIron = 10

function BlastFurnaceCamp:Dialogue(text)
	self:GetService("EffectsService"):RequestEffectAll("Dialogue", {
		Name = "Faris",
		Image = "rbxassetid://5706733990",
		Text = text,
	})
end

function BlastFurnaceCamp:OnCreated()
	self.MaxIron = math.floor(self.MaxIron * self:GetRun():GetDifficultyData().LootChance or 1)
	self.IronDeposits = {}
	self.HopperCooldowns = {}
	
	self.Model = self.Storage.Models.BlastFurnaceCamp:Clone()
	self.Model:SetPrimaryPartCFrame(self.StartCFrame)
	
	self.Model.Parent = self.StartParent

	local faris = self.Model.Faris
	faris.AnimationController:LoadAnimation(faris.Idle):Play()

	local breakables = {
		self.Model.Table1,
		self.Model.Table2,
		self.Model.Chair
	}
	local jokeTriggered = false
	local function onBroken()
		if jokeTriggered then return end
		jokeTriggered = true
		self:Dialogue("Come now, slayers. Did you really need to break my things?")
	end
	for _, breakable in pairs(breakables) do
		self:GetClass("DungeonFeature"):SetUpBreakable(breakable, breakable.PrimaryPart, onBroken)
	end
	
	self:SafeTouched(self.Model.FurnaceTrigger, function(...) self:OnFurnaceTouched(...) end)
	
	local interactableService = self:GetService("InteractableService")
	interactableService:CreateInteractable{
		Model = self.Model.Shield,
		Radius = 6,
		Callback = function(player)
			self:OnShieldActivated(player)
		end
	}
	interactableService:CreateInteractable{
		Model = self.Model.Hopper,
		Radius = 6,
		Callback = function(player)
			self:OnHopperActivated(player)
		end
	}
end

function BlastFurnaceCamp:GetPlayerDeposit(player)
	for _, deposit in pairs(self.IronDeposits) do
		if deposit.Player == player then
			return deposit
		end
	end
	return nil
end

function BlastFurnaceCamp:DepositIron(player, amount)
	if typeof(amount) ~= "number" then return end
	if amount > self.MaxIron then return end
	if amount ~= amount then return end
	amount = math.floor(amount)
	if amount <= 0 then return end

	local deposit = self:GetPlayerDeposit(player)
	if not deposit then
		deposit = {
			Player = player,
			Amount = 0,
		}
		table.insert(self.IronDeposits, deposit)
	end	
	amount = math.min(amount, self.MaxIron - deposit.Amount)

	local inventoryService = self:GetService("InventoryService")
	if not inventoryService:RemoveMaterial(player, 1, amount) then return end
	
	deposit.Amount += amount

	self:FireRemote("NotificationRequested", player, {
		Title = string.format("You deposited %d iron.", amount),
		Content = string.format("There's %d of yours in the hopper.", deposit.Amount),
	})
end

function BlastFurnaceCamp:OnHopperActivated(player)
	local legend = self:GetClass"Legend".GetLegendFromPlayer(player)
	if not legend then return end

	local player = legend.Player
	if not player then return end

	local inventoryService = self:GetService("InventoryService")
	local inventory = inventoryService:GetInventory(player)
	if not inventory then return end

	if self.HopperCooldowns[player] then return end
	self.HopperCooldowns[player] = true

	local ironAmount = 0
	for _, material in pairs(inventory.Materials) do
		if material.Id == 1 then
			ironAmount = material.Amount
			break
		end
	end

	if ironAmount == 0 then
		self:FireRemote("NotificationRequested", player, {
			Title = "No iron!",
			Content = "You have no iron to convert into steel.",
		})
	else
	local result, amount = self.Storage.Remotes.PromptAmount:InvokeClient(player, {
			PromptText = string.format("How much iron would you like to put in? You have %d and can put in a maximum of %d.", ironAmount, self.MaxIron),
			MinValue = 0,
			MaxValue = self.MaxIron,
			SmallStep = 1,
			LargeStep = 3,
			ConfirmText = "Confirm",
			CancelText = "Cancel",
		})
		if result and (amount > 0) then
			self:DepositIron(player, amount)
		end
	end

	wait(1)
	self.HopperCooldowns[player] = false
end

function BlastFurnaceCamp:GetShieldedLegend()
	for _, legend in pairs(self:GetClass("Legend").Instances) do
		local status = legend:GetStatusByType("FarisHeatShield")
		if status then
			return legend, status
		end
	end
	return nil, nil
end

function BlastFurnaceCamp:OnShieldActivated(player)
	if self.ShieldDebounce then return end
	
	local legend = self:GetClass"Legend".GetLegendFromPlayer(player)
	if not legend then return end

	local shieldedLegend, shield = self:GetShieldedLegend()

	if shieldedLegend == nil then
		self.ShieldDebounce = true
		
		local faris = self.Model.Faris
		faris.AnimationController:LoadAnimation(self.Storage.Animations.MagicCast):Play()
		wait(0.1)
		faris.HumanoidRootPart.Cast:Play()

		legend:AddStatus("Status", {
			Type = "FarisHeatShield",
			Infinite = true,
			OnStarted = function(s)
				local attachment = Instance.new("Attachment")
				local emitter = self.Storage.Models.FarisHeatShieldEmitter:Clone()
				emitter.Parent = attachment
				attachment.Parent = legend.Root
				s.Attachment = attachment
			end,
			OnEnded = function(s)
				s.Attachment:Destroy()
			end,
		})

		self.ShieldedLegendDiedConnection = legend.Died:Connect(function()
			if legend:HasStatusType("FarisHeatShield") then
				if self.ShieldedLegendDiedConnection then
					self.ShieldedLegendDiedConnection:Disconnect()
					self.ShieldedLegendDiedConnection = nil
				end
				
				self:Dialogue(
					string.format(
						"I lost focus on %s's heat shield because they were defeated. I'm sorry, slayers, but you'll have to return to me to get another.",
						legend.Player.Name
					)
				)
			end
		end)

		self:Dialogue(
			string.format(
				"All right, I'm maintaining the heat shield on %s. If you'd like me to change to someone else, have them return to me and I'll remove it.",
				legend.Player.Name
			)
		)

		self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
			Position = self.Model.Shield.PrimaryPart.Position - Vector3.new(0, 3, 0),
			Color = Color3.new(1, 1, 1),
			Radius = 12,
			Duration = 0.75,
		})

		wait(1)
		self.ShieldDebounce = false

	elseif legend == shieldedLegend then
		if self.ShieldedLegendDiedConnection then
			self.ShieldedLegendDiedConnection:Disconnect()
			self.ShieldedLegendDiedConnection = nil
		end
		
		self.ShieldDebounce = true
		
		local faris = self.Model.Faris
		faris.AnimationController:LoadAnimation(self.Storage.Animations.MagicCast):Play()
		wait(0.1)
		faris.HumanoidRootPart.Cast:Play()
		
		shield:Stop()

		self:Dialogue(
			string.format(
				"Very well, I've removed the heat shield from %s. Whoever would like to have it, step up now.",
				legend.Player.Name
			)
		)

		wait(1)
		self.ShieldDebounce = false
	end
end

function BlastFurnaceCamp:OnFurnaceTouched(part)
	local legend = self:GetClass"Legend".GetLegendFromPart(part)
	if not legend then return end

	local weapon = legend.Weapon
	if not weapon:IsA(self:GetClass("WeaponCarryable")) then return end
	if weapon.CarryableType ~= "LavaCore" then return end
	weapon:Use()

	for _, deposit in pairs(self.IronDeposits) do
		self:GetService("InventoryService"):AddItem(deposit.Player, "Materials", {Id = 2, Amount = deposit.Amount})
	end
	self.IronDeposits = {}
end

return BlastFurnaceCamp