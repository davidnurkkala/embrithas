local talents = {
	----------------------
	-- strength talents --
	----------------------
	[1] = {
		Name = "Brute",
		Image = "rbxassetid://5648264245",
		ImagePlaceholder = "STR\nI",
		Description = function(self)
			return string.format("Deal %d%% more Physical Bludgeoning damage.", self.DamageBuff * 100)
		end,
		Unlock = "have at least 60 base Strength",
		
		DamageBuff = 0.1,
		
		OnWillDealDamage = function(self, damage)
			local damageService = self:GetService("DamageService")
			
			if (damage.Type == "Bludgeoning") and damageService:IsDamagePhysical(damage) then
				damage.Amount *= 1 + self.DamageBuff
			end
		end,
	},
	[2] = {
		Name = "Tackle",
		Image = "rbxassetid://8822728",
		ImagePlaceholder = "STR\nII",
		Description = "Combat Roll becomes Tackle, an offensive movement ability that deals damage to enemies struck.",
		Exclusions = {6},
		Unlock = "have at least 130 base Strength",
	},
	[3] = {
		Name = "Rend",
		Image = "rbxassetid://977432572",
		ImagePlaceholder = "STR\nIII",
		Description = function(self)
			return string.format("Whenever you deal Physical Slashing damage, deal %d%% of it as additional Internal damage.", self.Portion * 100)
		end,
		Unlock = "have at least 190 base Strength",
		
		Portion = 0.2,
		
		OnWillDealDamage = function(self, damage)
			local damageService = self:GetService("DamageService")
			
			if (damage.Type == "Slashing") and damageService:IsDamagePhysical(damage) then
				damageService:Damage{
					Source = damage.Source,
					Target = damage.Target,
					Amount = damage.Amount * self.Portion,
					Type = "Internal",
				}
			end
		end,
	},
	[4] = {
		Name = "Goliath",
		Image = "rbxassetid://1549320310",
		ImagePlaceholder = "STR\nIV",
		Description = function(self)
			return string.format("When you deal Physical Bludgeoning damage, become empowered for %4.1f seconds. While empowered, dealing Physical Bludgeoning damage will stun targets for %4.1f seconds. This effect has %4.1f second cooldown.", self.Duration, self.StunDuration, self.Cooldown)
		end,
		Unlock = "have at least 250 base Strength",
		
		StatusType = "GoliathEmpowered",
		CooldownStatusType = "GoliathEmpoweredCooldown",
		
		Duration = 2,
		Cooldown = 20,
		StunDuration = 2,
		
		OnDealtDamage = function(self, damage)
			if (damage.Type ~= "Bludgeoning") then return end
			
			local damageService = self:GetService("DamageService")
			if (not damageService:IsDamagePhysical(damage)) then return end
			
			local effectsService = self:GetService("EffectsService")
			
			-- if not empowered and not on cooldown, empower
			if (not self.Legend:HasStatusType(self.StatusType)) and (not self.Legend:HasStatusType(self.CooldownStatusType)) then
				-- effects
				effectsService:RequestEffectAll("AnchoredSpinningShockwave", {
					Anchor = self.Legend.Root,
					Offset = CFrame.new(0, -2, 0),
					RotationSpeed = math.pi * 2,
					StartSize = Vector3.new(0, 8, 0),
					EndSize = Vector3.new(8, 4, 8),
					GrowDuration = 0.1,
					HoldDuration = self.Duration - 0.2,
					ShrinkDuration = 0.1,
					PartArgs = {
						Color = Color3.new(1, 0.721569, 0.203922),
					}
				})
				self.Legend:SoundPlayByObject(self.Storage.Sounds.AdrenalineRush)
				
				-- status
				self.Legend:AddStatus("Status", {
					Type = self.StatusType,
					Time = self.Duration,
					
					Category = "Good",
					ImagePlaceholder = "GLTH",
					
					OnEnded = function()
						-- cooldown status
						self.Legend:AddStatus("Status", {
							Type = self.CooldownStatusType,
							Time = self.Cooldown,
							
							ImagePlaceholder = "GLTH\nCD"
						})
					end,
				})
			end
			
			-- if empowered, stun
			if self.Legend:HasStatusType(self.StatusType) then
				if damage.Target.Resilient then return end
				
				-- effects
				local part = damage.Target.Model:FindFirstChild("Head") or damage.Target.Root
				effectsService:RequestEffectAll("AirBlast", {
					Position = part.Position,
					Radius = 6,
					Duration = 0.25,
					Color = Color3.new(1, 1, 1),
				})
				
				-- stun
				damage.Target:AddStatus("StatusStunned", {
					Time = self.StunDuration,
				})
			end
		end,
	},
	
	---------------------
	-- agility talents --
	---------------------
	[5] = {
		Name = "Finesse",
		Image = "rbxassetid://395408386",
		ImagePlaceholder = "AGI\nI",
		Description = function(self)
			return string.format("Deal %d%% more Physical Piercing damage.", self.DamageBuff * 100)
		end,
		Unlock = "have at least 60 base Agility",

		DamageBuff = 0.1,

		OnWillDealDamage = function(self, damage)
			local damageService = self:GetService("DamageService")

			if (damage.Type == "Piercing") and damageService:IsDamagePhysical(damage) then
				damage.Amount *= 1 + self.DamageBuff
			end
		end,
	},
	[6] = {
		Name = "Juke",
		Image = "rbxassetid://322255173",
		ImagePlaceholder = "AGI\nII",
		Description = "Combat Roll becomes Juke, a faster, shorter-range movement ability that has a shorter cooldown.",
		Exclusions = {2},
		Unlock = "have at least 130 Agility",
	},
	[7] = {
		Name = "Fast Hands",
		Image = "rbxassetid://2819702",
		ImagePlaceholder = "AGI\nIII",
		Description = function(self)
			return string.format("Sheath weapons %d%% faster.", self.Buff * 100)
		end,
		Unlock = "have at least 190 base Agility",
		
		Buff = 1,
		
		OnEquipped = function(self)
			self.Legend.SheathingSpeed.Percent += self.Buff
		end,
		
		OnUnequipped = function(self)
			self.Legend.SheathingSpeed.Percent -= self.Buff
		end,
	},
	[8] = {
		Name = "Untouchable",
		Image = "rbxassetid://5516679540",
		ImagePlaceholder = "AGI\nIV",
		Description = function(self)
			return string.format("You dodge incoming attacks, negating all damage. You can only dodge once every %4.1f seconds.", self.Cooldown)
		end,
		Unlock = "have at least 250 base Agility",
		
		Cooldown = 12.5,
		CooldownStatusType = "TalentUntouchableCooldown",
		
		OnWillTakeDamage = function(self, damage)
			if self.Legend:HasStatusType(self.CooldownStatusType) then return end
			if damage.Unblockable then return end
			if damage.Amount <= 0 then return end
			
			self:GetService("EffectsService"):RequestEffect(self.Legend.Player, "TextFeedback", {
				Duration = 0.5,
				TextArgs = {
					Text = "<i>Dodged!</i>",
					RichText = true,
					TextColor3 = Color3.new(1, 1, 1),
				},
			})
			
			damage.Amount = 0
			
			self.Legend:AddStatus("Status", {
				Type = self.CooldownStatusType,
				Time = self.Cooldown,
				
				ImagePlaceholder = "UNTCH\nCD",
			})
		end,
	},
	
	--------------------------
	-- constitution talents --
	--------------------------
	[9] = {
		Name = "Tenacious",
		Image = "rbxassetid://265790768",
		ImagePlaceholder = "CON\nI",
		Description = function(self)
			return string.format("Reduce the duration of movement-affecting status effects (like stuns) by %d%%", self.Reduction * 100)
		end,
		Unlock = "have at least 60 base Constitution",
		
		Reduction = 0.5,
		ReducedStatusTypes = {"Stunned", "Slowed", "Frosty"},
		
		OnEquipped = function(self)
			self.Connection = self.Legend.StatusAdded:Connect(function(status)
				if table.find(self.ReducedStatusTypes, status.Type) then
					status:MultiplyTime(self.Reduction)
				end
			end)
		end,
		
		OnUnequipped = function(self)
			self.Connection:Disconnect()
		end,
	},
	
	[10] = {
		Name = "Second Wind",
		Image = "rbxassetid://22378866",
		ImagePlaceholder = "CON\nII",
		Description = function(self)
			return string.format("Every time an enemy dies nearby, you recover %4.2f%% of your maximum health.", self.Healing * 100)
		end,
		Unlock = "have at least 130 base Constitution",
		
		Healing = 0.025,
		RangeSq = 64 ^ 2,
		
		OnEquipped = function(self)
			self.Connection = self:GetService("EnemyService").EnemyDied:Connect(function(enemy)
				if self.Legend:DistanceToSquared(enemy:GetPosition()) <= self.RangeSq then
					self:GetService("DamageService"):Heal{
						Source = self.Legend,
						Target = self.Legend,
						Amount = self.Legend.MaxHealth:Get() * self.Healing
					}
				end
			end)
		end,
		
		OnUnequipped = function(self)
			self.Connection:Disconnect()
		end,
	},
	
	[11] = {
		Name = "Adaptation",
		Image = "rbxassetid://152243437",
		ImagePlaceholder = "CON\nIII",
		Description = function(self)
			return string.format(
				"Upon taking damage, gain %d%% resistance to that type of damage for %d seconds. This effect can stack up to %d times per damage type.",
				self.Resistance * 100,
				self.Duration,
				self.MaxStacks
			)
		end,
		Unlock = "have at least 190 base Constitution",
		
		Resistance = 0.05,
		Duration = 10,
		MaxStacks = 7,
		
		PlaceholderNamesByDamageType = {
			Slashing = "SLSH",
			Piercing = "PRC",
			Bludgeoning = "BLDG",
			Heat = "HEAT",
			Cold = "COLD",
			Internal = "INTRL",
			Disintegration = "DIS",
			Psychic = "PSY",
			Electrical = "ELEC",
		},
		
		OnDamaged = function(self, damage)
			local statusType = "TalentAdaptation"..damage.Type.."Resistant"
			local status = self.Legend:GetStatusByType(statusType)
			if status then
				status.Stacks = math.min(self.MaxStacks, status.Stacks + 1)
				status:Restart()
			else
				local placeholder = "ADAPT\n"..self.PlaceholderNamesByDamageType[damage.Type]
				self.Legend:AddStatus("Status", {
					Time = self.Duration,
					Type = statusType,
					
					Category = "Good",
					ImagePlaceholder = placeholder,
					
					DamageType = damage.Type,
					Stacks = 1,
					Resistance = self.Resistance,
					OnWillTakeDamage = function(status, damage)
						if damage.Type == status.DamageType then
							local blocked = status.Resistance * status.Stacks
							damage.Amount *= (1 - blocked)
						end
					end,
				})
			end
		end,
	},
	
	[12] = {
		Name = "Indomitable",
		Image = "rbxassetid://1454450383",
		ImagePlaceholder = "CON\nIV",
		Description = function(self)
			return string.format(
				"Upon taking fatal damage, deny death and become invulnerable for %4.2f seconds. This effect can only occur once every %d seconds.",
				self.Duration,
				self.Cooldown
			)
		end,
		Unlock = "have at least 250 base Constitution",
		
		Duration = 5,
		Cooldown = 120,
		CooldownStatusType = "TalentIndomitableCooldown",
		
		OnWillTakeDamage = function(self, damage)
			if self.Legend:HasStatusType(self.CooldownStatusType) then return end
			
			if damage.Amount >= self.Legend.Health then
				-- logic
				damage.Amount = 0
				
				self.Legend:AddStatus("Status", {
					Time = self.Duration,
					Type = "TalentIndomitableInvulnerability",
					
					Category = "Good",
					ImagePlaceholder = "INDMT",
					
					OnStarted = function(status)
						self.Legend.Invulnerable += 1
						
						status.Object = Instance.new("ForceField", self.Legend.Model)
					end,
					OnEnded = function(status)
						self.Legend.Invulnerable -= 1
						
						status.Object:Destroy()
						
						self.Legend:AddStatus("Status", {
							Time = self.Cooldown,
							Type = self.CooldownStatusType,

							ImagePlaceholder = "INDMT\nCD",
						})
					end,
				})
				
				-- special effects
				self.Legend:AnimationPlay("WarCry")
				
				self.Legend:SoundPlayByObject(self.Storage.Sounds.AdrenalineRush)
				self.Legend:SoundPlayByObject(self.Storage.Sounds.Explosion1)
				self.Legend:SoundPlayByObject(self.Storage.Sounds.HealingBurst2)
				
				local effectsService = self:GetService("EffectsService")
				
				-- shockwaves
				for radius = 6, 18, 6 do
					effectsService:RequestEffectAll("Shockwave", {
						Duration = 0.5,
						CFrame = CFrame.new(self.Legend:GetFootPosition()) * CFrame.Angles(0, radius, 0),
						StartSize = Vector3.new(),
						EndSize = Vector3.new(radius * 2, radius / 3, radius * 2),
						PartArgs = {
							Color = Color3.new(1, 1, 1)
						},
					})
				end
				
				-- air blast
				effectsService:RequestEffectAll("AirBlast", {
					Position = self.Legend:GetPosition(),
					Color = Color3.new(1, 1, 1),
					Radius = 8,
					Duration = 0.5,
				})
			end
		end,
	},
	
	--------------------------
	-- perseverance talents --
	--------------------------
	[13] = {
		Name = "Recharge",
		Image = "rbxassetid://2699868788",
		ImagePlaceholder = "PER\nI",
		Description = function(self)
			return string.format("Every time an enemy dies nearby, you recover %4.2f%% of your maximum mana.", self.Restoration * 100)
		end,
		Unlock = "have at least 60 base Perseverance",

		Restoration = 0.075,
		RangeSq = 64 ^ 2,

		OnEquipped = function(self)
			self.Connection = self:GetService("EnemyService").EnemyDied:Connect(function(enemy)
				if self.Legend:DistanceToSquared(enemy:GetPosition()) <= self.RangeSq then
					self.Legend.Mana = math.min(self.Legend.MaxMana:Get(), self.Legend.Mana + self.Legend.MaxMana:Get() * self.Restoration)
				end
			end)
		end,

		OnUnequipped = function(self)
			self.Connection:Disconnect()
		end,
	},
	
	[14] = {
		Name = "Determination",
		Image = "rbxassetid://365982183",
		ImagePlaceholder = "PER\nII",
		Description = function(self)
			return string.format("Whenever you spend mana, deal Psychic damage to nearby enemies equivalent to %d%% of the amount of mana spent.", self.Ratio * 100)
		end,
		Unlock = "have at least 130 base Perseverance",
		
		Ratio = 2.25,
		Radius = 16,
		
		OnManaUsed = function(self, amount)
			local targeting = self:GetService("TargetingService")
			targeting:TargetCircle(targeting:GetEnemies(), {
				Position = self.Legend:GetPosition(),
				Range = self.Radius,
				Callback = function(enemy)
					self:GetService("DamageService"):Damage{
						Source = self.Legend,
						Target = enemy,
						Amount = amount * self.Ratio,
						Type = "Psychic",
						Tags = {"Magical"},
						Weapon = self,
					}
				end
			})
		end,
	},
	
	[15] = {
		Name = "Fortitude",
		Image = "rbxassetid://239447545",
		ImagePlaceholder = "PER\nIII",
		Description = function(self)
			return string.format(
				"Upon using a Movement ability, gain a mana shield for %d seconds. While active, damage you take is first blocked by your mana pool at a %d%% efficiency.",
				self.Duration,
				self.Efficiency * 100
			)
		end,
		Unlock = "have at least 190 base Perseverance",
		
		Duration = 5,
		Efficiency = 0.75,
		StatusType = "TalentFortitudeManaShield",
		
		OnEquipped = function(self)
			self.Connection = self.Legend.AbilityActivated:Connect(function(ability)
				if ability.Type ~= "Movement" then return end
				
				local status = self.Legend:GetStatusByType(self.StatusType)
				if status then
					status:Restart()
				else
					self.Legend:AddStatus("Status", {
						Time = self.Duration,
						Type = self.StatusType,
						
						Category = "Good",
						ImagePlaceholder = "MANA\nSHLD",
						
						OnStarted = function(status)
							local attachment = Instance.new("Attachment")
							attachment.Name = status.Type.."EmitterAttachment"
							attachment.Parent = status.Character.Root
							
							local emitter = self.Storage.Emitters.ManaShieldEmitter:Clone()
							emitter.Parent = attachment
							
							status.Attachment = attachment
							status.Emitter = emitter
							
							spawn(function()
								emitter:Emit(1)
							end)
						end,
						OnEnded = function(status)
							local emitter = status.Emitter 
							emitter.Enabled = false
							game:GetService("Debris"):AddItem(status.Attachment, emitter.Lifetime.Max)
						end,
						OnWillTakeDamage = function(status, damage)
							local legend = status.Character
							
							local requiredMana = damage.Amount / self.Efficiency
							local manaSpent = math.min(requiredMana, legend.Mana)
							local damageBlocked = manaSpent * self.Efficiency
							
							damage.Amount -= damageBlocked
							legend:UseMana(manaSpent)
							
							if legend.Mana <= 0 then
								status:Stop()
							end
						end,
					})
				end
			end)
		end,
		
		OnUnequipped = function(self)
			self.Connection:Disconnect()
		end,
	},
	
	[16] = {
		Name = "Deep Spirit",
		Image = "rbxassetid://1000906569",
		ImagePlaceholder = "PER\nIV",
		Description = function(self)
			return string.format("You cannot have less than %d mana.", self.ManaFloor)
		end,
		Unlock = "have at least 250 base Perseverance",
		
		ManaFloor = 10,
		
		OnUpdated = function(self, dt)
			if self.Legend.Mana <= self.ManaFloor then
				self.Legend.Mana = self.ManaFloor
			end
		end,
	},
	
	-----------------------
	-- dominance talents --
	-----------------------
	[17] = {
		Name = "Relentless",
		Image = "rbxassetid://130457798",
		ImagePlaceholder = "DOM\nI",
		Description = function(self)
			return string.format("Non-resilient enemies with %d%% of their maximum health or less take %d%% more damage from your attacks.", self.Threshold * 100, self.Bonus * 100)
		end,
		Unlock = "have at least 60 Dominance",
		
		Threshold = 0.2,
		Bonus = 3,
		
		OnWillDealDamage = function(self, damage)
			local target = damage.Target
			local ratio = target.Health / target.MaxHealth:Get()
			if ratio <= self.Threshold then
				damage.Amount *= self.Bonus
			end
		end,
	},
	
	[18] = {
		Name = "Presence",
		Image = "rbxassetid://21181476",
		ImagePlaceholder = "DOM\nII",
		Description = function(self)
			return string.format(
				"Enemies that you damage and enemies that damage you take %d%% increased Magic damage from all sources for %d seconds.",
				self.Buff * 100,
				self.Duration
			)
		end,
		Unlock = "have at least 130 base Dominance",
		
		Buff = 0.25,
		Duration = 5,
		StatusType = "TalentPresenceMagicDamage",
		
		ApplyStatus = function(self, target)
			local status = target:GetStatusByType(self.StatusType)
			if status then
				status:Restart()
			else
				target:AddStatus("Status", {
					Time = self.Duration,
					Type = self.StatusType,
					
					Category = "Bad",
					ImagePlaceholder = "MAGIC\nVULN",
					
					OnWillTakeDamage = function(status, damage)
						if not self:GetService("DamageService"):DoesDamageHaveTag(damage, "Magical") then return end
						
						damage.Amount *= (1 + self.Buff)
					end,
				})
			end
		end,
		
		OnDamaged = function(self, damage)
			if damage.Source ~= self.Legend then
				self:ApplyStatus(damage.Source)
			end
		end,
		
		OnDealtDamage = function(self, damage)
			if damage.Target ~= self.Legend then
				self:ApplyStatus(damage.Target)
			end
		end,
	},
	
	[19] = {
		Name = "Ensouled Strike",
		Image = "rbxassetid://66412823",
		ImagePlaceholder = "DOM\nIII",
		Description = function(self)
			return string.format(
				"Upon slaying an enemy, gain an Ensouled Strike for %d seconds. Dealing magical damage to a target consumes the Ensouled Strike to deal %d%% of your Dominance as magical disintegration damage to that target. The damage that Ensouled Strike itself deals cannot grant you another Ensouled Strike.",
				self.Duration,
				self.Ratio * 100
			)
		end,
		Unlock = "have at least 190 base Dominance",
		
		Duration = 5,
		Ratio = 1.25,
		StatusType = "TalentEnsouledStrike",
		
		OnDealtDamage = function(self, damage)
			if damage.Weapon == self then return end
			
			local status = self.Legend:GetStatusByType(self.StatusType)
			if status then
				local damageService = self:GetService("DamageService")
				if damage.Weapon == self then return end
				if not damageService:DoesDamageHaveTag(damage, "Magical") then return end
				
				self.Legend:RemoveStatus(status)
				
				damageService:Damage{
					Source = self.Legend,
					Target = damage.Target,
					Amount = self.Legend.Dominance:Get() * self.Ratio,
					Type = "Disintegration",
					Tags = {"Magical"},
					Weapon = self,
				}
			else
				if damage.Target.Health > 0 then return end
				
				self.Legend:AddStatus("Status", {
					Time = self.Duration, 
					Type = self.StatusType,
					
					Category = "Good",
					ImagePlaceholder = "SOUL\nSTRK",
				})
			end
		end,
	},
	
	[20] = {
		Name = "Critical Mass",
		Image = "rbxassetid://5375466483",
		ImagePlaceholder = "DOM\nIV",
		Description = function(self)
			return string.format(
				"Spent mana is saved into a pool that can hold %d mana and drains mana at a rate of %d mana per second. If this pool exceeds its maximum, gain Critical Mass for %d seconds. While you have Critical Mass, all mana costs are reduced by %d%% and your Magical damage is increased by %d%%.",
				self.PoolSize,
				self.PoolDrainRate,
				self.Duration,
				self.Discount * 100,
				self.Buff * 100
			)
		end,
		Unlock = "have at least 250 base Dominance",
		
		PoolSize = 100,
		PoolDrainRate = 2,
		Duration = 5,
		Discount = 0.5,
		Buff = 0.2,
		StatusType = "TalentCriticalMass",
		
		OnEquipped = function(self)
			self.Pool = 0
			
			self:FireRemote("CriticalMassUpdated", self.Legend.Player, {Type = "Show"})
		end,
		
		OnUnequipped = function(self)
			self:FireRemote("CriticalMassUpdated", self.Legend.Player, {Type = "Hide"})
		end,
		
		OnUpdated = function(self, dt)
			self.Pool = math.max(0, self.Pool - self.PoolDrainRate * dt)
			
			local status = self.Legend:GetStatusByType(self.StatusType)
			if status then
				self:FireRemote("CriticalMassUpdated", self.Legend.Player, {Type = "Update", Ratio = 1 - status:GetProgress()})
			else
				self:FireRemote("CriticalMassUpdated", self.Legend.Player, {Type = "Update", Ratio = self.Pool / self.PoolSize})
			end
		end,
		
		OnManaUsed = function(self, amount)
			if self.Legend:HasStatusType(self.StatusType) then return end
			
			self.Pool += amount
			if self.Pool >= self.PoolSize then
				self.Pool = 0
				
				self.Legend:AddStatus("Status", {
					Time = self.Duration,
					Type = self.StatusType,
					
					Category = "Good",
					ImagePlaceholder = "CRIT\nMASS",
					
					OnWillDealDamage = function(status, damage)
						if self:GetService("DamageService"):DoesDamageHaveTag(damage, "Magical") then
							damage.Amount *= (1 + self.Buff)
						end
					end,
					
					OnWillUseMana = function(status, manaUse, isCheck)
						manaUse.Amount *= (1 - self.Discount)
					end,
				})
				
				-- sounds
				self.Legend:SoundPlayByObject(self.Storage.Sounds.MagicEerie)
				self.Legend:SoundPlayByObject(self.Storage.Sounds.MagicTechno)
				
				-- visuals
				local effectsService = self:GetService("EffectsService")
				
				-- shockwaves
				local cframe = CFrame.new(self.Legend:GetFootPosition())
				local big = Vector3.new(16, 1, 16)
				local small = Vector3.new(0, 4, 0)
				local color = Color3.fromRGB(0, 170, 255)
				local duration = 0.5
				effectsService:RequestEffectAll("Shockwave", {
					Duration = duration,
					CFrame = cframe,
					StartSize = big,
					EndSize = small,
					PartArgs = {
						Color = color
					},
				})
				effectsService:RequestEffectAll("Shockwave", {
					Duration = duration,
					CFrame = cframe,
					StartSize = small,
					EndSize = big,
					PartArgs = {
						Color = color
					},
				})
				
				-- sphere
				effectsService:RequestEffectAll("AirBlast", {
					Duration = duration,
					Position = self.Legend:GetPosition(),
					Color = color,
					Radius = 8,
				})
			end
		end,
	},
	
	[21] = {
		Name = "Aggressive Aid",
		Image = "rbxassetid://3432712951",
		ImagePlaceholder = "COM\nI",
		Description = function(self)
			return string.format(
				"Whenever you deal damage to an enemy, %d%% of that damage is converted into healing for a nearby ally. The lowest-health ally within range is prioritized. You cannot heal yourself in this way.",
				self.Ratio * 100
			)
		end,
		Unlock = "have at least 60 base Compassion",
		
		Ratio = 0.05,
		Range = 64,
		
		OnDealtDamage = function(self, damage)
			local healing = damage.Amount * self.Ratio
			
			local foundAlly = false
			local allyRatioPairs = {}
			local targetingService = self:GetService("TargetingService")
			targetingService:TargetCircle(targetingService:GetMortals(), {
				Position = self.Legend:GetPosition(),
				Range = self.Range,
				Callback = function(target)
					if target ~= self.Legend then
						local ratio = target.Health / target.MaxHealth:Get()
						local pair = {Ally = target, Ratio = ratio}
						table.insert(allyRatioPairs, pair)
						
						foundAlly = true
					end
				end,
			})
			
			if not foundAlly then
				return
			end
			
			table.sort(allyRatioPairs, function(a, b)
				return a.Ratio < b.Ratio
			end)
			
			local target = allyRatioPairs[1].Ally
			
			if target == self.Legend then
				healing *= (1 - self.SelfPenalty)
			end
			
			self:GetService("DamageService"):Heal{
				Source = self.Legend,
				Target = target,
				Amount = healing,
			}
		end,
	},
	
	[22] = {
		Name = "Salvation",
		Image = "rbxassetid://2690000",
		ImagePlaceholder = "COM\nII",
		Description = function(self)
			return string.format(
				"Your healing affecting allies under %d%% health is increased by %d%%",
				self.Threshold * 100,
				self.Bonus * 100
			)
		end,
		Unlock = "have at least 130 base Compassion",
		
		Threshold = 0.3,
		Bonus = 0.5,
		
		OnWillHeal = function(self, healing)
			local target = healing.Target
			local ratio = target.Health / target.MaxHealth:Get()
			if ratio <= self.Threshold then
				healing.Amount *= (1 + self.Bonus)
			end
		end,
	},
	
	[23] = {
		Name = "Empower",
		Image = "rbxassetid://926503896",
		ImagePlaceholder = "COM\nIII",
		Description = function(self)
			return string.format(
				"Whenever you heal an ally, empower them for up to %d seconds. When an empowered ally deals damage, they stop being empowered and you deal %d%% of your Compassion as magical disintegration damage to their target. Allies can only be empowered once every %d seconds.",
				self.Duration,
				self.Ratio * 100,
				self.Cooldown
			)
		end,
		Unlock = "have at least 190 base Compassion",
		
		Ratio = 1,
		Duration = 5,
		Cooldown = 5,
		StatusType = "TalentEmpower",
		CooldownStatusType = "TalentEmpowerCooldown",
		
		OnHealed = function(self, healing)
			local target = healing.Target
			if target:HasStatusType(self.StatusType) or target:HasStatusType(self.CooldownStatusType) then return end
			
			target:AddStatus("Status", {
				Time = self.Duration,
				Type = self.StatusType,
				
				Category = "Good",
				ImagePlaceholder = "EMPWR",
				
				OnWillDealDamage = function(status, damage)
					status.Character:RemoveStatus(status)
					
					status.Character:AddStatus("Status", {
						Time = self.Cooldown,
						Type = self.CooldownStatusType,
						
						ImagePlaceholder = "EMPWR\nCD",
					})
					
					self:GetService("DamageService"):Damage{
						Target = damage.Target,
						Source = self.Legend,
						Amount = self.Legend.Compassion:Get() * self.Ratio,
						Type = "Disintegration",
						Tags = {"Magical"},
						Weapon = self,
					}
					
					damage.Target:SoundPlayByObject(self.Storage.Sounds.CompassionHit)
					
					self:GetService("EffectsService"):RequestEffectAll("Flash", {
						CFrame = CFrame.new(damage.Target:GetPosition()),
						StartSize = Vector3.new(),
						EndSize = Vector3.new(8, 12, 8),
						Duration = 0.25,
						PartArgs = {
							Color = Color3.fromRGB(255, 255, 127),
						}
					})
				end,
			})
		end,
	},
	
	[24] = {
		Name = "Selfless",
		Image = "rbxassetid://255504345",
		ImagePlaceholder = "COM\nIV",
		Description = function(self)
			return string.format(
				"%d%% of the healing you do is granted to you as a shield that lasts up to %d seconds. This shield cannot exceed %d%% of your maximum health.",
				self.HealingRatio * 100,
				self.Duration,
				self.MaxHealthRatio * 100
			)
		end,
		Unlock = "have at least 250 base Compassion",
		
		HealingRatio = 0.5,
		MaxHealthRatio = 0.25,
		Duration = 10,
		
		StatusType = "TalentSelfless",
		
		OnHealed = function(self, heal)
			local shieldAmount = heal.Amount * self.HealingRatio
			local maxShieldAmount = self.Legend.MaxHealth:Get() * self.MaxHealthRatio
			
			local status = self.Legend:GetStatusByType(self.StatusType)
			if status then
				status:Restart()
				status.Amount = math.min(status.Amount + shieldAmount, maxShieldAmount)
			else
				self.Legend:AddStatus("Status", {
					Time = self.Duration,
					Type = self.StatusType,
					
					ReplicationDisabled = true,
					
					IsShield = true,
					Amount = math.min(shieldAmount, maxShieldAmount), 
				})
			end
		end,
	}
}

for id, talent in pairs(talents) do
	talent.Id = id
end

return talents