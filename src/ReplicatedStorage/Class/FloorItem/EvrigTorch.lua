local Super = require(script.Parent)
local EvrigTorch = Super:Extend()

function EvrigTorch:CreateRangeVisualizer(radius, color)
	local range = self.Storage.Models.RangeVisualizer:Clone()
	range.Root.Gui.Image.ImageColor3 = color
	range.Root.Size = Vector3.new(radius, 0, radius) * 2
	return range
end

function EvrigTorch:OnCreated()
	self.Active = true
	
	-- model
	self.Model = self.Storage.Models.EvrigTorch:Clone()
	self.Model:SetPrimaryPartCFrame(self.StartCFrame * CFrame.new(0, 3, 0))
	
	local warmthRadius = self:GetClass("WeaponTorch").Radius
	
	local warmthRange = self:CreateRangeVisualizer(warmthRadius, Color3.fromRGB(225, 127, 70))
	warmthRange:SetPrimaryPartCFrame(self.StartCFrame)
	warmthRange.Parent = self.Model
	
	self.Model.Parent = self.StartParent
	
	-- be warm
	spawn(function() self:GetRun():SetCurrentHeatSource(self) end)
	
	-- cooldown
	local cooldownTime = self.Cooldown or 0
	self.Cooldown = self:CreateNew"Cooldown"()
	self.Cooldown:Use(cooldownTime)
	
	-- on touched
	self.InteractableId = self:GetService("InteractableService"):CreateInteractable{
		Model = self.Model,
		Radius = 8,
		Callback = function(player)
			self:OnActivated(player)
		end,
	}
end

function EvrigTorch:OnActivated(player)
	if not self.Active then return end
	
	if not self.Cooldown:IsReady() then return end
	
	local legend = self:GetClass"Legend".GetLegendFromPlayer(player)
	if not legend then return end
	
	self:GetService("InteractableService"):DestroyInteractable(self.InteractableId)
	self.Active = false
	self.Model:Destroy()
	
	legend:EquipWeaponByObject(self:CreateNew"WeaponTorch"{
		Legend = legend,
		Data = self:GetService("WeaponService"):GetWeaponData({Id = 36, Level = 20}),
		
		OnUnequipped = function(weapon)
			local position = legend:GetFootPosition()
			local cframe = CFrame.new(position)
			self:CreateNew"EvrigTorch"{
				StartCFrame = cframe,
				StartParent = self.StartParent,
				Cooldown = 3,
			}
		end,
		
		AttackHeavy = function()
			legend:EquipWeapon(legend.Inventory.Weapons[legend.Inventory.EquippedWeaponIndex])

			return true
		end
	})
	
	self:GetRun():SetCurrentHeatSource(legend)
end

return EvrigTorch