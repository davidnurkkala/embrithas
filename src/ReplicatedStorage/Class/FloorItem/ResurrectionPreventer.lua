local Super = require(script.Parent)
local ResurrectionPreventer = Super:Extend()

ResurrectionPreventer.Radius = 32
ResurrectionPreventer.RadiusSq = ResurrectionPreventer.Radius ^ 2
ResurrectionPreventer.RangeColor = Color3.fromRGB(225, 255, 255)

function ResurrectionPreventer:CreateRangeVisualizer(radius, color)
	local range = self.Storage.Models.RangeVisualizer:Clone()
	range.Root.Gui.Image.ImageColor3 = color
	range.Root.Size = Vector3.new(radius, 0, radius) * 2
	return range
end

function ResurrectionPreventer:OnCreated()
	self.Active = true
	
	-- model
	local model = Instance.new("Model")
	model.Name = "ResurrectionPreventer"
	local part = self.Storage.Weapons.CarryableResurrectionPreventer.Object:Clone()
	part.Anchored = true
	part.Parent = model
	model.PrimaryPart = part
	
	self.Model = model
	self.Model:SetPrimaryPartCFrame(self.StartCFrame * CFrame.new(0, 1.5, 0))
	
	self.Model.Parent = self.StartParent
	
	-- cooldown
	local cooldownTime = self.Cooldown or 0
	self.Cooldown = self:CreateNew"Cooldown"()
	self.Cooldown:Use(cooldownTime)
	
	self.InteractableId = self:GetService("InteractableService"):CreateInteractable{
		Model = self.Model,
		Radius = 8,
		Callback = function(player)
			self:OnActivated(player)
		end,
	}
end

function ResurrectionPreventer:OnActivated(player)
	if not self.Active then return end
	
	if not self.Cooldown:IsReady() then return end
	
	local legend = self:GetClass"Legend".GetLegendFromPlayer(player)
	if not legend then return end

	-- destroy myself
	self:GetService("InteractableService"):DestroyInteractable(self.InteractableId)
	self.Active = false
	self.Model:Destroy()

	local deltaY = -legend.Humanoid.HipHeight

	local range = self.Storage.Models.RangeVisualizer:Clone()
	range.Root.Gui.Image.ImageColor3 = self.RangeColor
	range.Root.Anchored = false
	range.Root.Massless = true
	range.Root.Size = Vector3.new(self.Radius, 0, self.Radius) * 2
	range.Root.Position = legend.Root.Position + Vector3.new(0, deltaY, 0)

	local w = Instance.new("Weld")
	w.Part0 = legend.Root
	w.Part1 = range.Root
	w.C0 = CFrame.new(0, deltaY, 0)
	w.Parent = range.Root

	range.Parent = workspace.Effects

	-- reset function
	local debounce = true
	local function reset(isDrop, equipWeapon)
		if not debounce then return end
		debounce = false

		range:Destroy()

		if equipWeapon then
			legend:EquipWeapon(legend.Inventory.Weapons[legend.Inventory.EquippedWeaponIndex])
		end

		if not isDrop then return end

		local position = legend:GetFootPosition()
		local cframe = CFrame.new(position)
		self:CreateNew"ResurrectionPreventer"{
			StartCFrame = cframe,
			StartParent = self.StartParent,
			Cooldown = 3,
		}
	end

	-- equip the custom weapons and abilities
	legend:EquipWeaponByObject(self:CreateNew"WeaponCarryable"{
		CarryableType = "ResurrectionPreventer",
		Legend = legend,
		Data = {AssetsName = "CarryableResurrectionPreventer", Level = 75},

		Use = function(weapon)
			reset(false, true)
		end,
		
		AttackHeavy = function(weapon)
			reset(true, true)

			return true
		end,
		
		OnUnequipped = function(weapon)
			reset(true, false)
		end
	})
end

return ResurrectionPreventer