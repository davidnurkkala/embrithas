local Super = require(script.Parent)
local LavaCore = Super:Extend()

LavaCore.Radius = 16
LavaCore.RadiusSq = LavaCore.Radius ^ 2
LavaCore.RangeColor = Color3.fromRGB(225, 127, 70)

function LavaCore:CreateRangeVisualizer(radius, color)
	local range = self.Storage.Models.RangeVisualizer:Clone()
	range.Root.Gui.Image.ImageColor3 = color
	range.Root.Size = Vector3.new(radius, 0, radius) * 2
	return range
end

function LavaCore:OnCreated()
	self.Active = true
	
	-- model
	local model = Instance.new("Model")
	model.Name = "LavaCore"
	local part = self.Storage.Weapons.CarryableLavaCore.Object:Clone()
	part.Anchored = true
	part.Parent = model
	model.PrimaryPart = part
	
	self.Model = model
	self.Model:SetPrimaryPartCFrame(self.StartCFrame * CFrame.new(0, 1.5, 0))
	
	local flameRadius = self.Radius
	
	local fireRange = self:CreateRangeVisualizer(flameRadius, self.RangeColor)
	fireRange:SetPrimaryPartCFrame(self.StartCFrame)
	fireRange.Parent = self.Model
	
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

	-- damage
	spawn(function()
		while self.Model.Parent do
			LavaCore:DealDamage(self.StartCFrame.Position, wait(0.1))
		end
	end)
end

function LavaCore:GetDamageSource()
	if not self.DamageSource then
		self.DamageSource = self:CreateNew"Character"{
			Model = workspace,
			Name = "the oppressive heat of a Lava Core",
		}
	end
	return self.DamageSource
end

-- A11Noob was here
function LavaCore:DealDamage(position, dt)
	local mortals = self:GetService("TargetingService"):GetMortals()
	for _, mortal in pairs(mortals) do
		if not mortal:HasStatusType("FarisHeatShield") then
			local delta = mortal:GetPosition() - position
			local distanceSq = delta.X ^ 2 + delta.Z ^ 2
			if distanceSq < self.RadiusSq then
				self:GetService("DamageService"):Damage{
					Source = self:GetDamageSource(),
					Target = mortal,
					Amount = mortal.MaxHealth:Get() * 0.2 * dt,
					Type = "Heat",
				}
			end
		end
	end
end

function LavaCore:OnActivated(player)
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
		self:CreateNew"LavaCore"{
			StartCFrame = cframe,
			StartParent = self.StartParent,
			Cooldown = 1,
		}
	end

	local run = self:GetRun()
	local spawnCooldown = self:CreateNew"Cooldown"{Time = 2}
	local function trySpawnEnemy()
		if not spawnCooldown:IsReady() then return end
		spawnCooldown:Use()

		local dungeon = run.Dungeon
		local locations = dungeon:GetSpawnLocationsOnCircle(legend:GetPosition(), self.Radius)
		if #locations == 0 then return end
		local location = self:Choose(locations) + Vector3.new(0, 4, 0)
		
		local enemyService = self:GetService("EnemyService")
		local enemy = enemyService:CreateEnemy(run:RequestEnemy(), dungeon.Level){
			StartCFrame = CFrame.new(location)
		}
		enemyService:ApplyDifficultyToEnemy(enemy)
		self:GetWorld():AddObject(enemy)

		local effectsService = self:GetService("EffectsService")
		effectsService:RequestEffectAll("AirBlast", {
			Position = location,
			Color = self.RangeColor,
			Radius = 8,
			Duration = 0.25,
		})
		effectsService:RequestEffectAll("Sound", {
			Sound = self.Storage.Sounds.FireCast,
			Position = location,
		})
	end

	-- equip the custom weapons and abilities
	legend:EquipWeaponByObject(self:CreateNew"WeaponCarryable"{
		CarryableType = "LavaCore",
		Legend = legend,
		Data = {AssetsName = "CarryableLavaCore"},

		CustomOnUpdated = function(weapon, dt)
			trySpawnEnemy()
			LavaCore:DealDamage(weapon.Legend:GetPosition(), dt)
		end,

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

return LavaCore