local Super = require(script.Parent)
local WeaponStaff = Super:Extend()

WeaponStaff.Range = 10
WeaponStaff.DisplayName = "Staff"
WeaponStaff.DescriptionLight = "Whack enemies. Successful hits hasten your mana regeneration."
WeaponStaff.UsesMana = true

WeaponStaff.CooldownLightTime = 0.6
WeaponStaff.CooldownHeavyTime = 1

function WeaponStaff:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
end

function WeaponStaff:AttackLight(dt)
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:UseMinimum(self.CooldownLight.Time)
	
	self:AttackSound()
	self.Legend:AnimationPlay("StaffAttackLight"..self.AttackNumber, 0)
	
	local didAttack = false
	
	local callback = function(enemy)
		local damage = self:GetService"DamageService":Damage{
			Source = self.Legend,
			Target = enemy,
			Amount = self:GetDamage(),
			Weapon = self,
			Type = "Bludgeoning",
		}

		self:HitEffects(enemy)

		didAttack = true
	end
	
	if self.AttackNumber == 1 then
		self.Targeting:TargetCone(self.Targeting:GetEnemies(), {
			CFrame = self.Legend:GetAimCFrame(),
			Angle = 90,
			Range = 12,
			Callback = callback,
		})
	else
		self.Targeting:TargetMelee(self.Targeting:GetEnemies(), {
			CFrame = self.Legend:GetAimCFrame(),
			Width = 6,
			Length = 12,
			Callback = callback,
		})
	end
	
	self.AttackNumber = (self.AttackNumber + 1) % 3
	
	if didAttack then
		self.Legend.ManaRegenCooldown:ReduceBy(1)
		
		self.Attacked:Fire()
	end
	
	return true
end

function WeaponStaff:AddParts()
	local staff = self.Assets.Staff:Clone()
	staff.Parent = self.Legend.Model
	staff.Weld.Part0 = self.Legend.Model.RightHand
	staff.Weld.Part1 = staff
	self.Staff = staff
end

function WeaponStaff:ClearParts()
	self:ClearPartsHelper(self.Staff)
end

function WeaponStaff:Equip()
	self:Unsheath()
end

function WeaponStaff:Unequip()
	self:ClearParts()
end

function WeaponStaff:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Staff.Weld, self.Legend.Model.UpperTorso,
		CFrame.new(0, 0, 1),
		CFrame.Angles(0, 0, math.pi / 4),
		CFrame.Angles(0, math.pi / 2, 0)
	)

	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponStaff:Unsheath()
	self:ClearParts()
	self:AddParts()
	
	self.Legend:SetRunAnimation("SingleWeapon")
end

return WeaponStaff