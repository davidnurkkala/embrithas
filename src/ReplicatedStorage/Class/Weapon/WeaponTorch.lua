local Super = require(script.Parent)
local WeaponTorch = Super:Extend()

WeaponTorch.Range = 10
WeaponTorch.Radius = 24
WeaponTorch.DisplayName = "Torch"
WeaponTorch.DescriptionLight = "Smack enemies and set them on fire."
WeaponTorch.DescriptionHeavy = "Drop the torch."

WeaponTorch.CooldownLightTime = 1
WeaponTorch.CooldownHeavyTime = 0.1

WeaponTorch.SheathAble = false

function WeaponTorch:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
end

function WeaponTorch:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:Use(self.CooldownLight.Time)

	self:AttackSound()
	self.Legend:AnimationPlay("GreatswordAttackLight"..self.AttackNumber, 0)
	self.AttackNumber = (self.AttackNumber + 1) % 2

	local didAttack = false

	self.Targeting:TargetCone(self.Targeting:GetEnemies(), {
		CFrame = self.Legend:GetAimCFrame(),
		Angle = 110,
		Range = 14,
		Callback = function(enemy)
			local damage = self:GetService"DamageService":Damage{
				Source = self.Legend,
				Target = enemy,
				Amount = self:GetDamage(),
				Weapon = self,
				Type = "Bludgeoning",
			}

			self:HitEffects(enemy)
			
			if not enemy:HasStatusType("Burning") then
				enemy:AddStatus("StatusBurning", {
					Time = 5,
					Damage = self:GetDamage(),
					Source = self.Legend,
					Weapon = self,
				})
			end

			didAttack = true
		end
	})

	if didAttack then
		self.Attacked:Fire()
	end

	return true
end

function WeaponTorch:Equip()
	local torch = self.Assets.Torch:Clone()
	torch.Parent = self.Legend.Model
	torch.Weld.Part0 = self.Legend.Model.RightHand
	torch.Weld.Part1 = torch
	self.Torch = torch
	
	self.Legend:SetRunAnimation("SingleWeapon")
	self.Legend:AnimationPlay("TorchIdle")
	
	-- visualize range
	local deltaY = -self.Legend.Humanoid.HipHeight
	
	local range = self.Storage.Models.RangeVisualizer:Clone()
	range.Root.Gui.Image.ImageColor3 = Color3.fromRGB(225, 127, 70)
	range.Root.Anchored = false
	range.Root.Massless = true
	range.Root.Size = Vector3.new(self.Radius, 0, self.Radius) * 2
	range.Root.Position = self.Legend.Root.Position + Vector3.new(0, deltaY, 0)
	
	local w = Instance.new("Weld")
	w.Part0 = self.Legend.Root
	w.Part1 = range.Root
	w.C0 = CFrame.new(0, deltaY, 0)
	w.Parent = range.Root
	
	range.Parent = workspace.Effects
	
	self.RangeVisualizer = range
end

function WeaponTorch:Unequip()
	if self.OnUnequipped then
		self:OnUnequipped()
	end
	
	self.Torch:Destroy()
	self.RangeVisualizer:Destroy()
	self.Legend:AnimationStop("TorchIdle")
end

return WeaponTorch