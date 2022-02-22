return {
	Name = "Jolian Fire Lance",
	Class = "WeaponSpear",
	AssetsName = "JolianFireLance",
	Description = "A highly unusual weapon from the Jolian Empire capable of unleashing a barrage of fire.",
	Image = "rbxassetid://5669257729",
	Rarity = "Rare",
	Perks = {
		"Get a flame charge every five attacks. Attacking with a flame charge deals 50% damage to enemies in a large cone and burns them for 100% damage over 3 seconds.",
	},
	UpgradeMaterials = {Steel = 0.1},
	
	Args = {
		FireLanceAttackNumber = 0,
		FireLanceAttackCount = 5,
		
		Equip = function(self)
			self.FireLanceAttackNumber = self.Legend.FireLanceAttackNumber or 0
			
			self:GetClass("WeaponSpear").Equip(self)
			
			self:UpdateEmitter()
		end,
		
		Unequip = function(self)
			self.Legend.FireLanceAttackNumber = self.FireLanceAttackNumber
			
			self:GetClass("WeaponSpear").Unequip(self)
		end,
		
		GetTargets = function(self, cframe)
			local range = 32
			local angle = math.rad(15)
			
			local position = self.Legend:GetPosition()
			local vector = cframe.LookVector
			
			local targets = {}
			local enemies = self:GetService("TargetingService"):GetEnemies()
			for _, enemy in pairs(enemies) do
				local hereToEnemy = (enemy:GetPosition() - position) * Vector3.new(1, 0, 1)
				local distance = hereToEnemy.Magnitude
				if distance <= range then 
					local dot = vector:Dot(hereToEnemy / distance)
					local angleToEnemy = math.acos(dot)
					if angleToEnemy <= angle then
						table.insert(targets, enemy)
					end
				end
			end
			
			return targets
		end,
		
		UpdateEmitter = function(self)
			self.Spear.EmitterAttachment.ArmedEmitter.Enabled = (self.FireLanceAttackNumber == 0)
		end,
		
		OnAttacked = function(self, cframe)
			if not self.Spear then return end
			if not self.Spear:FindFirstChild("EmitterAttachment") then return end
			
			if self.FireLanceAttackNumber == 0 then
				self.Legend:SoundPlay("FireCast")
				self.Spear.EmitterAttachment.Emitter:Emit(256)
				
				local targets = self:GetTargets(cframe)
				for _, target in pairs(targets) do
					self:GetService("DamageService"):Damage{
						Source = self.Legend,
						Target = target,
						Amount = self:GetDamage() * 0.5,
						Type = "Heat",
					}
					
					target:AddStatus("StatusBurning", {
						Time = 3,
						Damage = self:GetDamage(),
						Source = self.Legend,
						Weapon = self,
					})
				end
			end
			self.FireLanceAttackNumber = (self.FireLanceAttackNumber + 1) % self.FireLanceAttackCount
			
			self:UpdateEmitter()
		end
	}
}