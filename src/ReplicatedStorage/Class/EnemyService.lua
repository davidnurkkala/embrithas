local Super = require(script.Parent)
local EnemyService = Super:Extend()

local function breakJoints(self)
	self.Model:BreakJoints()
	for _, desc in pairs(self.Model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CanCollide = true
		end
	end
end

local function onConstructDied(self)
	self:SoundPlay("Death")
	self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
		Position = self:GetPosition(),
		Radius = 6,
		Color = Color3.fromRGB(0, 170, 255),
		Duration = 0.5,
	})
	self:Ragdoll()
	delay(2, function() self:FadeAway(1) end)
end

local Resistances = {
	Orc = {
		Bludgeoning = 0.25,
		Internal = 0.25,
		Piercing = -0.25,
		Psychic = 1,
	},
	Skeleton = {
		Bludgeoning = -0.5,
		Piercing = 0.5,
		Internal = 1,
		Cold = 1,
	},
	Shadow = {
		Physical = 0.25,
		Magical = -0.25,
	},
	MadeOfRock = {
		Bludgeoning = -0.5,
		Piercing = 0.25,
		Slashing = 0.75,
		Heat = 1,
		Cold = 1,
		Internal = 1,
	},
	Ghost = {
		Physical = 0.9,
		Magical = -0.9,
		Internal = 1,
	},
}

EnemyService.EnemyData = {
	["Orc"] = {
		HitsToKill = 3,
		TimeToDie = 2,
		Class = "EnemyMeleeBasic",
		Resistances = Resistances.Orc,
	},
	["Orc Archer"] = {
		HitsToKill = 4,
		TimeToDie = 1.5,
		Class = "EnemyRangerBasic",
		Resistances = Resistances.Orc,
	},
	["Orc Bulwark"] = {
		HitsToKill = 2,
		TimeToDie = 3.5,
		Class = "EnemyCharger",
		Resistances = Resistances.Orc,
	},
	["Orc Sapper"] = {
		HitsToKill = 0.5,
		TimeToDie = 1,
		Class = "EnemyReckless",
		Resistances = Resistances.Orc,
		Args = {
			CustomOnDestroyed = function(self)
				if not (self.Model and self.Model:FindFirstChild("Barrel")) then return end
				self.Model.Barrel:Destroy()
			end
		}
	},
	["Orc Shaman"] = {
		HitsToKill = 4,
		TimeToDie = 2,
		Class = "EnemyHealer",
		Resistances = Resistances.Orc,
	},
	["Orc Miner"] = {
		HitsToKill = 3,
		TimeToDie = 2.5,
		Class = "EnemyMeleeBasic",
		Resistances = Resistances.Orc,
		Args = {
			AttackRadius = 8,
			AttackDelay = 0.75,
			RetreatDuration = 0.2,
		},
	},
	["Orc Brute"] = {
		HitsToKill = 2,
		TimeToDie = 3,
		Class = "EnemyMaul",
		Resistances = Resistances.Orc,
		Args = {
			ShockwaveRadius = 4.5,
		}
	},
	["Orc Berserker"] = {
		HitsToKill = 3,
		TimeToDie = 3.5,
		Class = "EnemyGreatsword",
		Resistances = Resistances.Orc,
		Args = {
			DamageType = "Bludgeoning",
		}
	},
	["Orc Lieutenant"] = {
		HitsToKill = 3,
		TimeToDie = 10,
		Class = "EnemyOrcBoss",
		Resistances = Resistances.Orc,
		Args = {
			MusicDisabled = true,
			AttackPatternRandomized = true,
		}
	},
	["Orc Boss"] = {
		HitsToKill = 4,
		TimeToDie = 30,
		Class = "EnemyOrcBoss",
		Resistances = Resistances.Orc,
	},
	["Elder Orc Shaman"] = {
		HitsToKill = 3,
		TimeToDie = 0.5 * 60 * 10,
		Class = "EnemyElderOrcShaman",
		Resistances = Resistances.Orc,
	},
	["Orc Juggernaut"] = {
		HitsToKill = 3,
		TimeToDie = 0.75 * 60 * 10,
		Class = "EnemyOrcJuggernaut",
		Resistances = Resistances.Orc,
	},
	["Orc Aegis"] = {
		HitsToKill = 3,
		TimeToDie = 5,
		Class = "EnemyOrcAegis",
		Resistances = Resistances.Orc,
	},
	["Orc Grenadier"] = {
		HitsToKill = 2,
		TimeToDie = 2,
		Class = "EnemyOrcGrenadier",
		Resistances = Resistances.Orc,
	},
	["Orc Pistoleer"] = {
		HitsToKill = 4,
		TimeToDie = 2,
		Class = "EnemyOrcPistoleer",
		Resistances = Resistances.Orc,
	},
	["Orc Chieftan"] = {
		HitsToKill = 3,
		TimeToDie = 0.75 * 60 * 10,
		Class = "EnemyOrcChieftan",
		Resistances = Resistances.Orc,
	},
	["Skeleton"] = {
		HitsToKill = 3,
		TimeToDie = 2,
		Class = "EnemyMeleeBasic",
		Resistances = Resistances.Skeleton,
		Tags = {"Spiritual"},
		Args = {
			Ragdoll = breakJoints
		},
	},
	["Skeleton Warrior"] = {
		HitsToKill = 2,
		TimeToDie = 5,
		Class = "EnemySwordAndShield",
		Resistances = Resistances.Skeleton,
		Tags = {"Spiritual"},
		Args = {
			Ragdoll = breakJoints
		},
	},
	["Bone Archer"] = {
		HitsToKill = 4,
		TimeToDie = 1.5,
		Class = "EnemyRangerBasic",
		Resistances = Resistances.Skeleton,
		Tags = {"Spiritual"},
		Args = {
			Ragdoll = breakJoints,
			Tracking = true,
		},
	},
	["Training Dummy"] = {
		HitsToKill = 10,
		TimeToDie = 1,
		Class = "EnemyDummy",
		Args = {
			Resilient = true,
			NoExperience = true,
		},
	},
	["Corrupted Golem"] = {
		HitsToKill = 3,
		TimeToDie = 60,
		Class = "EnemyCorruptedGolem",
		Resistances = Resistances.MadeOfRock,
	},
	["Osseous Aberration"] = {
		HitsToKill = 3,
		TimeToDie = 40,
		Class = "EnemySkeletonBoss",
		Resistances = Resistances.Skeleton,
		Tags = {"Spiritual"},
	},
	["Shadow Assassin"] = {
		HitsToKill = 2,
		TimeToDie = 0.5,
		Class = "EnemyAssassin",
		Resistances = Resistances.Shadow,
		Tags = {"Spiritual"},
	},
	["Armored Shadow"] = {
		HitsToKill = 3,
		TimeToDie = 5,
		Class = "EnemySwordAndShield",
		Resistances = Resistances.Shadow,
		Tags = {"Spiritual"},
		Args = {
			ChargeDistance = 24,
			ChargeWidth = 8,
			AttackRadius = 8,
		},
	},
	["Mystic Shadow"] = {
		HitsToKill = 4,
		TimeToDie = 1,
		Class = "EnemyTurretBasic",
		Resistances = Resistances.Shadow,
		Tags = {"Spiritual"},
		Args = {
			RestDuration = {1.5, 3},
		},
	},
	["Null"] = {
		HitsToKill = 2,
		TimeToDie = 4,
		Class = "EnemyNull",
		Resistances = {
			Magical = 1,
		},
		Tags = {"Spiritual"},
	},
	["Raging Shadow"] = {
		HitsToKill = 3,
		TimeToDie = 2.5,
		Class = "EnemyGreatsword",
		Resistances = Resistances.Shadow,
		Tags = {"Spiritual"},
	},
	["Shadow Warrior"] = {
		HitsToKill = 3,
		TimeToDie = 2.5,
		Class = "EnemyMaul",
		Resistances = Resistances.Shadow,
		Tags = {"Spiritual"},
	},
	["Immortal Shadow"] = {
		HitsToKill = 4,
		TimeToDie = 10,
		Class = "EnemyDefender",
		Resistances = Resistances.Shadow,
		Tags = {"Spiritual"},
		Args = {
			Predictive = true,
			RunAnimation = "RunSwordShield",
			RunAnimationSpeed = 0.5,
			
			AttackAnimation = "SwordShieldAttack1",
			AttackAnimationSpeed = 0.5,
			
			IdleAnimation = "None",
		}
	},
	["Forgotten Shadows"] = {
		HitsToKill = 3,
		TimeToDie = 0.5 * 60 * 10,
		Class = "EnemyForgottenShadows",
		Resistances = Resistances.Shadow,
		Tags = {"Spiritual"},
	},
	["Forsaken Shadows"] = {
		HitsToKill = 3,
		TimeToDie = 0.35 * 60 * 10,
		Class = "EnemyForsakenShadows",
		Resistances = Resistances.Shadow,
		Tags = {"Spiritual"},
	},
	["Stone Corruption"] = {
		HitsToKill = 4,
		TimeToDie = 10,
		Class = "EnemyStoneCorruption",
		Resistances = Resistances.MadeOfRock,
		Args = {
			Predictive = true,
			RunAnimation = "WalkDualWield",
		}
	},
	["Frozen Corruption"] = {
		HitsToKill = 4,
		TimeToDie = 2,
		Class = "EnemyElementalCorruption",
		Resistances = {
			Internal = 1,
			Heat = -1,
			Cold = 1,
		},
		Args = {
			ProjectileSound = "IceCast",
			ProjectileHitSound = "IceShatter2",
			ProjectileModel = Super.Storage.Models.FrostBolt,
			ProjectileAttackDelay = 0.75,
			ProjectileCooldownTime = 1,
			ProjectileSpeed = 16,
			OnProjectileHit = function(self, projectile, character)
				self:ApplyFrostyToLegend(character, self.Damage)
			end,
			CustomOnDestroyed = function(self)
				-- ijrs was here
				-- ijrs was here again
				-- tothetix was here
				-- fire_king66 was here
				-- magikarpgod2 was here 6/28/2021
				
				local position = self:GetPosition()
				local footPosition = self:GetFootPosition()
				local duration = 1
				
				self:AttackCircle{
					Position = footPosition,
					Duration = duration,
					Radius = 4,
					OnHit = function() end,
				}
				
				local st = math.pi * 2 * math.random()
				for s = 0, 4 do
					local t = st + (math.pi * 2 / 5) * s
					local direction = Vector3.new(math.cos(t), 0, math.sin(t))
					
					self:TelegraphDirectional{
						Duration = duration,
						
						Length = 4,
						Width = 1,
						CFrame = CFrame.new(footPosition, footPosition + direction) * CFrame.new(0, 0, -4),
						
						Callback = function()
							self:FireProjectile(direction, position)
						end,
					}
				end
			end
		}
	},
	["Corrupted Lightning"] = {
		HitsToKill = 5,
		TimeToDie = 3,
		Class = "EnemyCorruptedLightning",
	},
	["Fiery Corruption"] = {
		HitsToKill = 4,
		TimeToDie = 2.5,
		Class = "EnemyElementalCorruption",
		Resistances = {
			Internal = 1,
			Heat = 1,
			Cold = -1,
		},
		Args = {
			DeathBurnDuration = 5,
			ProjectileSpeed = 26,
			
			CustomOnDied = function(self)
				self.Root.Anchored = true
				self:SoundPlay("Death")
				self.Model.UpperTorso.EmitterAttachment.Emitter.Enabled = false
				
				local duration = self.DeathBurnDuration + 2
				self:GetService("EffectsService"):RequestEffectAll("FadeModel", {
					Model = self.Model,
					Duration = duration
				})
				game:GetService("Debris"):AddItem(self.Model, duration)
			end,
			CustomOnDestroyed = function(self)
				local fire = self.EnemyData.EmitterPart:Clone()
				local position = self:GetFootPosition()
				
				self:AttackActiveCircle{
					Position = position,
					Radius = 8,
					Delay = 1,
					Duration = self.DeathBurnDuration,
					Interval = 0.2,
					
					OnHit = function(legend, dt)
						self:GetService"DamageService":Damage{
							Source = self,
							Target = legend,
							Amount = self.Damage * dt,
							Type = "Heat",
							Tags = {"Magical"},
						}
					end,
					
					OnStarted = function(t)
						fire.Position = self.Root.Position
						fire.Parent = workspace.Effects
					end,
					
					OnCleanedUp = function(t)
						fire.Attachment.Emitter.Enabled = false
						game:GetService("Debris"):AddItem(fire, fire.Attachment.Emitter.Lifetime.Max)
					end
				}
			end
		}
	},
	["Zombie"] = {
		HitsToKill = 3,
		TimeToDie = 2.5,
		Class = "EnemyZombie",
		Resistances = {
			Physical = 0.25,
			Slashing = -0.6,
		},
		Tags = {"Spiritual"},
		Args = {
			Predictive = true,
			RunAnimation = "ZombieWalk",
			AttackAnimation = "ZombieAttack",
			IdleAnimation = "ZombieIdle",
		}
	},
	["Zombie Defender"] = {
		HitsToKill = 4,
		TimeToDie = 10,
		Class = "EnemyDefender",
		Resistances = {
			Physical = 0.5,
			Slashing = -0.6,
		},
		Tags = {"Spiritual"},
		Args = {
			Predictive = true,
			RunAnimation = "ZombieWalk",
			AttackAnimation = "ZombieAttack",
			IdleAnimation = "ZombieIdle",
		}
	},
	["Ghost"] = {
		HitsToKill = 30,
		TimeToDie = 1,
		Class = "EnemyGhost",
		Resistances = Resistances.Ghost,
		Tags = {"Spiritual"},
		Args = {
			AttackDelay = 0.5,
			AttackRadius = 4,
		}
},
	["Skeleton Berserker"] = {
		HitsToKill = 3,
		TimeToDie = 3,
		Class = "EnemyBerserker",
		Resistances = Resistances.Skeleton,
		Tags = {"Spiritual"},
	},
	["Lost Champion"] = {
		HitsToKill = 3,
		TimeToDie = 60,
		Class = "EnemyLostChampion",
		Resistances = Resistances.Skeleton,
		Tags = {"Spiritual"},
	},
	["Bone Spider Colossus"] = {
		HitsToKill = 3,
		TimeToDie = 1 * 60 * 10,
		Class = "EnemyBoneSpider",
		Resistances = Resistances.Skeleton,
		Tags = {"Spiritual"},
		Args = {
			Ragdoll = breakJoints,
		}
	},
	["Cryptkeeper"] = {
		HitsToKill = 3,
		TimeToDie = 0.75 * 60 * 10,
		Class = "EnemyCryptkeeper",
		Resistances = Resistances.Skeleton,
		Tags = {"Spiritual"},
	},
	["Jukumai Necromancer"] = {
		HitsToKill = 3,
		TimeToDie = 0.5 * 60 * 10,
		Class = "EnemyJukumai",
		Resistances = {
			Magical = 0.5,
			Cold = 1,
			Internal = 1,
			Psychic = -0.25,
		},
		Tags = {"Spiritual"},
	},
	["Animated Construct"] = {
		HitsToKill = 3,
		TimeToDie = 2,
		Class = "EnemyMeleeBasic",
		Resistances = Resistances.MadeOfRock,
		Args = {
			CustomOnDied = onConstructDied,
		}
	},
	["Projected Construct"] = {
		HitsToKill = 4,
		TimeToDie = 2,
		Class = "EnemyRangerBasic",
		Resistances = Resistances.MadeOfRock,
		Args = {
			CustomOnDied = onConstructDied,
			Tracking = true,
			ProjectileModel = Super.Storage.Models.ManaArrow,
		},
	},
	["Blaster Construct"] = {
		HitsToKill = 1.5,
		TimeToDie = 5,
		Class = "EnemyBlasterConstruct",
		Resistances = Resistances.MadeOfRock,
		Args = {
			CustomOnDied = onConstructDied,
		}
	},
	["Terrorknight"] = {
		HitsToKill = 3,
		TimeToDie = 5,
		Class = "EnemyTerrorknight",
	},
	["Terrorknight Jailor"] = {
		HitsToKill = 5,
		TimeToDie = 5,
		Class = "EnemyTerrorknightJailor",
	},
	["Terrorknight Summoner"] = {
		HitsToKill = 5,
		TimeToDie = 7,
		Class = "EnemyTerrorknightSummoner",
	},
	["Chained One"] = {
		HitsToKill = 4,
		TimeToDie = 2.5,
		Class = "EnemyMeleeBasic",
		Resistances = Resistances.Ghost,
		Tags = {"Spiritual"},
		Args = {
			Predictive = true,
			AttackAnimation = "GhostAttack",
			RunAnimation = "FieryCorruptionRun",
			RetreatDuration = 0,
			AttackRadius = 12,
			AttackDelay = 1.5,
		},
	},
	["Imprisoned One"] = {
		HitsToKill = 0.5,
		TimeToDie = 2,
		Class = "EnemyReckless",
		Resistances = Resistances.Ghost,
		Tags = {"Spiritual"},
		Args = {
			AttackDelay = 2.25,
			AttackRadius = 24,
			AttackRange = 8,
		}
	},
	["Warden's Soul Cage"] = {
		HitsToKill = 3,
		TimeToDie = 1.5 * 60,
		Class = "EnemyCageBoss",
	},
	["Shadow of Fiara, the High King's Hound"] = {
		HitsToKill = 4,
		TimeToDie = 10 * 60,
		Class = "EnemyHkh",
	}
}

EnemyService.HealthBonus = {
	Start = 0.25,
	Step = 0.025,
	Min = 0.05
}

function EnemyService:OnCreated()
	self.EnemyCreated = self:CreateNew"Signal"()
	self.EnemyDied = self:CreateNew"Signal"()
end

function EnemyService:GetHealthBonus(playerCount)
	if playerCount == 1 then return 0 end
	
	local total = 0
	local current = self.HealthBonus.Start
	for _ = 2, playerCount do
		total += current
		current = math.max(current - self.HealthBonus.Step, self.HealthBonus.Min)
	end
	return total
end

function EnemyService:GetHealthFromTimeToDie(timeToDie, level)
	local statService = self:GetClass("StatService") 
	
	local playerDps = statService:GetPower(level, statService:GetAverageStatInvestment() * level)
	local baseHealth = playerDps * timeToDie
	return baseHealth
end

function EnemyService:CreateEnemy(enemyName, level, levelScaling)
	if levelScaling == nil then levelScaling = true end
	
	local data = self.EnemyData[enemyName]
	
	return function(args)
		local difficulty = self:GetRun():GetDifficultyData()
		if levelScaling then
			level += (difficulty.LevelDelta or 0)
		end
		level = math.max(level, 1)
		
		local legendHealthAtLevel = self:GetClass("Legend").GetMaxHealthFromLevel(level)
		args.Damage = math.ceil(legendHealthAtLevel / data.HitsToKill)
		args.Damage *= (difficulty.DamageMultiplier or 1)
		args.EnemyData = self.Storage.Enemies:FindFirstChild(enemyName)
		args.BaseName = enemyName
		args.Level = level
		args.Resistances = data.Resistances
		args.Tags = data.Tags
		
		if data.Args then
			for key, val in pairs(data.Args) do
				args[key] = val
			end
		end
		
		local enemy = self:CreateNew(data.Class)(args)
		
		local playerCount = #game:GetService("Players"):GetPlayers()
		local healthBonus = 1 + self:GetHealthBonus(playerCount)
		
		local baseHealth = self:GetHealthFromTimeToDie(data.TimeToDie, level)
		enemy.MaxHealth.Base = baseHealth * healthBonus * (difficulty.HealthMultiplier or 1) * (args.HealthMultiplier or 1)
		enemy.Health = enemy.MaxHealth:Get()
		
		if difficulty.Armor then
			enemy.Armor.Base += difficulty.Armor
		end
		
		self.EnemyCreated:Fire(enemy)
		enemy.Died:Connect(function()
			self.EnemyDied:Fire(enemy)
		end)
		
		return enemy
	end
end

function EnemyService:MakeEnemyElite(enemy)
	if enemy.IsElite then return end
	
	enemy.Name = "Elite "..enemy.Name
	enemy.MaxHealth.Base = enemy.MaxHealth.Base * 2
	enemy.Health = enemy.MaxHealth:Get()
	
	enemy.StatusGui.IconLabel.Visible = true
	enemy.StatusGui.HealthFrame.Bar.BackgroundColor3 = Color3.fromRGB(85, 0, 255)
	
	enemy.IsElite = true
end

function EnemyService:ApplyDifficultyToEnemy(enemy)
	local difficulty = self:GetRun():GetDifficultyData()
	
	if difficulty.ModifierChance and (math.random() < difficulty.ModifierChance) then
		local count = 1
		if difficulty.ModifierTripleChance and (math.random() < difficulty.ModifierTripleChance) then
			count += 2
		elseif difficulty.ModifierDoubleChance and (math.random() < difficulty.ModifierDoubleChance) then
			count += 1
		end
		
		local modifiers = self:GetClass("Enemy").Modifiers
		for _ = 1, count do
			local modifier
			repeat
				modifier = self:Choose(modifiers)
			until (not modifier.IsUnique) or (not enemy:HasModifier(modifier.Name))
			enemy:AddModifier(modifier.Name)
		end
	end
	
	if difficulty.EliteChance and (math.random() < difficulty.EliteChance) then
		self:MakeEnemyElite(enemy)
	end
end

local Singleton = EnemyService:Create()
return Singleton