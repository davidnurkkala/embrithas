local Super = require(script.Parent)
local AbilityCombatRoll = Super:Extend()

AbilityCombatRoll.Type = "Movement"
AbilityCombatRoll.ClientCooldown = 0.25

AbilityCombatRoll.Distance = 16
AbilityCombatRoll.CooldownTime = 1

AbilityCombatRoll.JukeCooldownReduction = 0.5
AbilityCombatRoll.JukeDistanceReduction = 0.5

function AbilityCombatRoll:OnCreated()
	Super.OnCreated(self)
end

function AbilityCombatRoll:GetSpeedFromLevel()
	return 56
end

function AbilityCombatRoll:GetTackleDamage()
	return self:GetPowerHelper("Strength")
end

function AbilityCombatRoll:GetJukeSpeed()
	return self:GetSpeedFromLevel() * 1.5
end

function AbilityCombatRoll:GetJukeDistance()
	return self.Distance * (1 - self.JukeDistanceReduction)
end

function AbilityCombatRoll:GetDescription()
	if self:IsTalentEquipped(2) then
		return string.format(
			"Ram %d feet at %4.1f feet per second in the direction of movement. Deal %d damage to any enemies you slam into.",
			self.Distance,
			self:GetSpeedFromLevel(),
			self:GetTackleDamage()
		)
		
	elseif self:IsTalentEquipped(6) then
		return string.format(
			"Rapidly move %d feet at %4.1f feet per second in the direction of movement. Has a cooldown which is %d%% shorter.",
			self:GetJukeDistance(),
			self:GetJukeSpeed(),
			self.JukeCooldownReduction * 100
		)
	else
		return string.format(
			"Roll %d feet at %4.1f feet per second in the direction of movement. Good for getting out of sticky situations.",
			self.Distance,
			self:GetSpeedFromLevel()
		)
	end
end

function AbilityCombatRoll:OnActivatedClient(player, abilityInfo)
	if player:FindFirstChild("PreventAbilityUse") then return end
	
	if self:IsTalentEquipped(2) then
		return self:Tackle(player, abilityInfo)
	elseif self:IsTalentEquipped(6) then
		return self:Juke(player, abilityInfo)
	else
		return self:Roll(player, abilityInfo)
	end
end

function AbilityCombatRoll:TackleDamage(duration)
	local width = 5
	local length = self.Distance
	
	local humanoid = self.Legend.Humanoid
	local direction = humanoid.MoveDirection
	if direction:FuzzyEq(Vector3.new()) then
		return
	end
	local position = self.Legend:GetFootPosition()
	position += direction * (length / 2)
	local cframe = CFrame.new(position, position + direction)
	
	local targeting = self:GetService("TargetingService")
	
	targeting:TargetSquare(targeting:GetEnemies(), {
		CFrame = cframe,
		Width = width,
		Length = length,
		Callback = function(enemy, data)
			if not self.Legend:CanSeePoint(enemy:GetPosition()) then return end
			
			delay(data.LengthWeight * duration, function()
				self:GetService"DamageService":Damage{
					Source = self.Legend,
					Target = enemy,
					Amount = self:GetTackleDamage(),
					Weapon = self,
					Type = "Bludgeoning",
				}
				
				enemy:SoundPlayByObject(self.Storage.Sounds.Bash2)
			end)
		end,
	})
	
	-- effects
	self:GetService("EffectsService"):RequestEffectAll("ForceWave", {
		Duration = 0.25,
		Root = self.Legend.Root,
		CFrame = cframe,
		StartSize = Vector3.new(4, 4, 8),
		EndSize = Vector3.new(5, 5, 10),
		PartArgs = {
			Color = Color3.new(1, 1, 1),
			Transparency = 0.5,
		}
	})
	self.Legend:SoundPlayByObject(self.Storage.Sounds.Swoosh1)
end

function AbilityCombatRoll:UpdateCooldownTime()
	if self:IsTalentEquipped(6) then
		self.Cooldown.Time = self.CooldownTime * (1 - self.JukeCooldownReduction)
		
	else
		self.Cooldown.Time = self.CooldownTime
	end
end

function AbilityCombatRoll:Equip()
	Super.Equip(self)
	
	self:UpdateCooldownTime()
end

function AbilityCombatRoll:OnActivatedServer()
	self:UpdateCooldownTime()
	
	if self:IsTalentEquipped(2) then
		local duration = self.Distance / self:GetSpeedFromLevel()
		
		local stopEthereality = self.Legend:StartTemporaryEthereality()
		delay(duration, stopEthereality)
		
		self:TackleDamage(duration)
	end
	
	return true
end

function AbilityCombatRoll:AnimatedDash(player, distance, speed, animationName, animationSpeedDividend)
	if player:FindFirstChild("PreventAbilityUse") then return end

	local t = distance / speed

	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local direction = humanoid.MoveDirection
	if direction:FuzzyEq(Vector3.new()) then
		return false
	end

	humanoid.AutoRotate = false

	self:GetService("FacerClient"):OnFaceDirectionCalled(humanoid.MoveDirection, t)

	local animation = game.ReplicatedStorage:WaitForChild("Animations"):WaitForChild(animationName)
	local track = humanoid:LoadAnimation(animation)
	track:Play(nil, nil, animationSpeedDividend / t)

	local mover = Instance.new("BodyVelocity")
	mover.MaxForce = Vector3.new(1e5, 0, 1e5)
	mover.Velocity = direction * speed

	root.CFrame = CFrame.new(root.Position, root.Position + direction * Vector3.new(1, 0, 1))
	mover.Parent = root

	delay(t, function()
		humanoid.AutoRotate = true
		mover:Destroy()
	end)

	return true
end

function AbilityCombatRoll:Juke(player, abilityInfo)
	return self:AnimatedDash(player, self:GetJukeDistance(), self:GetJukeSpeed(), "CombatRollJuke", 1)
end

function AbilityCombatRoll:Roll(player, abilityInfo)
	return self:AnimatedDash(player, self.Distance, self:GetSpeedFromLevel(), "CombatRoll", 0.7)
end

function AbilityCombatRoll:Tackle(player, abilityInfo)
	return self:AnimatedDash(player, self.Distance, self:GetSpeedFromLevel(), "CombatRollTackle", 1)
end

return AbilityCombatRoll