local Super = require(script.Parent)
local WeaponStaffHealing = Super:Extend()

WeaponStaffHealing.DisplayName = "Staff of Healing"
WeaponStaffHealing.DescriptionHeavy = "Use mana to cause the targeted ally to regenerate health over time."

WeaponStaffHealing.HealingRange = 24
WeaponStaffHealing.HealingRangeSq = WeaponStaffHealing.HealingRange ^ 2

WeaponStaffHealing.ManaCost = 30

function WeaponStaffHealing:GetHealing()
	return self:GetPowerHelper("Compassion") * 0.4
end

function WeaponStaffHealing:GetDescription(level, itemData)
	return string.format("%s\n⚕️ %4.1f", Super.GetDescription(self, level, itemData, false), self:GetHealing()).."\n"..self:GetMechanicsDescription(itemData)
end

function WeaponStaffHealing:GetChestAttachment(target)
	local model = target.Model
	local torso = model:FindFirstChild("UpperTorso") or target.Root or model.PrimaryPart
	local attachment = torso:FindFirstChild("ChestAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "ChestAttachment"
		attachment.Parent = torso
	end
	return attachment
end

function WeaponStaffHealing:HealTarget(target)
	local duration = 5
	local amount = self:GetHealing()
	local perSecond = amount / duration
	
	target:AddStatus("StatusRegenerating", {
		Time = duration,
		HealingPerSecond = perSecond,
		Source = self.Legend,
	})
	
	return true
end

function WeaponStaffHealing:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	
	local manaCost = self.ManaCost
	if not self.Legend:CanUseMana(manaCost) then return end
	
	local didAttack = false
	
	self.Targeting:TargetCircleNearest(self.Targeting:GetMortals(), {
		Position = self.Legend.AimPosition,
		Range = 8,
		Callback = function(target)
			-- effects
			local duration = 0.5

			if target ~= self.Legend then
				self:FireRemote("FacePartCalled", self.Legend.Player, target.Root, duration)
			end

			self.Legend:SoundPlayByObject(self.Assets.Sounds.Heal)
			self.Legend:AnimationPlay("StaffCast")

			local beam = self.Staff.Beam
			beam.Attachment1 = self:GetChestAttachment(target)
			delay(duration, function()
				beam.Attachment1 = nil
			end)
			
			-- actual healing
			didAttack = self:HealTarget(target)
		end,
	})
	
	if didAttack then
		self.Legend:UseMana(manaCost)

		self.CooldownHeavy:Use()
		self.CooldownLight:Use()
	end

	return true
end

return WeaponStaffHealing