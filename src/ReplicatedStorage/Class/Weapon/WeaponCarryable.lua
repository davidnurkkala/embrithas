local Super = require(script.Parent)
local WeaponCarryable = Super:Extend()

WeaponCarryable.DisplayName = ""
WeaponCarryable.DescriptionLight = ""
WeaponCarryable.DescriptionHeavy = ""
WeaponCarryable.ForceWalking = true

WeaponCarryable.CooldownLightTime = 10
WeaponCarryable.CooldownHeavyTime = 0.1

WeaponCarryable.PreventAbilityUse = true

WeaponCarryable.SheathAble = false

function WeaponCarryable:OnCreated()
	Super.OnCreated(self)
end

function WeaponCarryable:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	
	self.Legend:SoundPlay("AdrenalineRush")

	local range = 32

	self:GetClass("AbilityWarCry"):PushEnemies(self.Legend:GetPosition(), range)

	self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
		Position = self.Legend:GetPosition(),
		Radius = range,
		Duration = 0.25,
	})
end

function WeaponCarryable:OnUpdated(dt)
	if self.CustomOnUpdated then
		self:CustomOnUpdated(dt)
	end
	
	if self.ForceWalking then
		local sprinting = self.Legend:GetStatusByType("Sprinting")
		if sprinting then
			sprinting:Stop()
		end
		
		self.Legend.InCombatCooldown:Use()
	end
end

function WeaponCarryable:Equip()
	local object = self.Assets.Object:Clone()
	object.Parent = self.Legend.Model
	object.Weld.Part0 = self.Legend.Model.UpperTorso
	object.Weld.Part1 = object
	self.Object = object
	
	self.Legend:SetRunAnimation("SingleWeapon")
	self.Legend:AnimationPlay("CarryableCarry", 0)

	if self.OnEquipped then
		self:OnEquipped()
	end
end

function WeaponCarryable:Unequip()
	self.Object:Destroy()
	self.Legend:AnimationStop("CarryableCarry")

	if self.OnUnequipped then
		self:OnUnequipped()
	end
end

return WeaponCarryable