local Models = game:GetService("ReplicatedStorage").Models

local weapons = {
	[1] = {
		Name = "Rookie Sword",
		Class = "WeaponSwordAndShield",
		AssetsName = "IronSwordAndShield",
		Description = "Not exactly pristine and not entirely sharp. Given to rookies not expected to survive so as not to waste resources. Good luck!",
		Image = "rbxassetid://5228960349",
	},
	[2] = {
		Name = "Iron Hatchet",
		Class = "WeaponAxeAndBuckler",
		AssetsName = "TestAxeAndBuckler",
		Description = "A light iron hatchet with an agile buckler. Maybe more useful for chopping wood.",
		Image = "rbxassetid://5067540085",
		UpgradeMaterials = {Iron = 0.1},
	},
	[3] = {
		Name = "Iron Battleaxe",
		Class = "WeaponBattleaxe",
		AssetsName = "TestBattleaxe",
		Description = "A hefty iron battleaxe weighty enough to cleave through enemies.",
		Image = "rbxassetid://5067539479",
		UpgradeMaterials = {Iron = 0.1},
	},
	[4] = {
		Name = "Iron Sword",
		Class = "WeaponSwordAndShield",
		AssetsName = "IronSwordAndShield",
		Description = "An iron sword and a sturdy shield. It should serve to slice up monsters well enough.",
		Image = "rbxassetid://5228960349",
		UpgradeMaterials = {Iron = 0.1},
	},
	[5] = {
		Name = "Iron Greatsword",
		Class = "WeaponGreatsword",
		AssetsName = "TestGreatsword",
		Description = "The length of this iron blade makes it unwieldy in the tight corridors of a dungeon -- but that never stopped anyone, right?",
		Image = "rbxassetid://5067539703",
		UpgradeMaterials = {Iron = 0.1},
	},
	[6] = {
		Name = "Hunting Bow",
		Class = "WeaponBowAndDagger",
		AssetsName = "TestBowAndDagger",
		Description = "A hunting bow and an iron dagger. The pair of them are decent for stabbing both up close and at a distance.",
		Image = "rbxassetid://5067563385",
		UpgradeMaterials = {Iskith = 0.1},
	},
	[7] = {
		Name = "Orc Greatclub",
		Class = "WeaponMaul",
		AssetsName = "UrvokClub",
		Description = "A hefty hunk of lumber that's almost too heavy to swing around.",
		Image = "rbxassetid://5067196069",
		Rarity = "Rare",
		UpgradeMaterials = {Iskith = 0.1},
		Perks = {
			"While under half health, slam is larger.",
		},
		
		Args = {
			UrvokActive = false,
			UrvokBonus = 0.5,
			
			CustomOnUpdated = function(self, dt)
				local ratio = self.Legend.Health / self.Legend.MaxHealth:Get()
				
				if self.UrvokActive and (ratio > 0.5) then
					self.Radius.Percent = self.Radius.Percent - self.UrvokBonus
					self.UrvokActive = false
					
				elseif (not self.UrvokActive) and (ratio < 0.5) then
					self.Radius.Percent = self.Radius.Percent + self.UrvokBonus
					self.UrvokActive = true
				end
			end
		}
	},
	[8] = {
		Name = "Rusty Rookie's Sword",
		Class = "WeaponSwordAndShield",
		AssetsName = "RustyRookieSword",
		Description = "The sword of a rookie that didn't make it. Their will to survive lives on, though. Grants a burst of speed when the shield first absorbs damage.",
		Image = "rbxassetid://5228960475",
		Rarity = "Rare",
		Perks = {
			"Move at double speed for 1 second upon blocking with a full shield.",
		},
		
		Args = {
			OnWillBlockDamage = function(self, damage)
				local duration = 1
				local speedBonus = 1
				
				if self.Block == self.BlockMax then
					self.Legend:AddStatus("Status", {
						Type = "Buffed",
						Time = duration,
						OnStarted = function()
							self.Legend.Speed:ModPercent(speedBonus)
						end,
						OnEnded = function()
							self.Legend.Speed:ModPercent(-speedBonus)
						end
					})
				end
			end,
		}
	},
	[9] = {
		Name = "Iron Halberd",
		Class = "WeaponHalberd",
		AssetsName = "IronHalberd",
		Description = "The result of someone asking \"what if I put an axe on a long stick?\" An effective but basic iron polearm.",
		Image = "rbxassetid://5071099241",
		UpgradeMaterials = {Iron = 0.1},
	},
	[10] = require(script.Steel).Halberd,
	[11] = {
		Name = "Corsair Sabers",
		Class = "WeaponSabers",
		AssetsName = "IronSabers",
		Description = "Neiss' elite non-magical soldiers, the Corsairs, were sent ahead of you. They didn't make it back.",
		Image = "rbxassetid://5140475755",
		UpgradeMaterials = {Iron = 0.1},
		Args = {
			DescriptionHeavy = "Slam the ground, damaging and pushing away nearby enemies.",
			
			CooldownHeavyTime = 6,
			AttackHeavy = function(self)
				if not self.CooldownHeavy:IsReady() then return end
				self.CooldownHeavy:Use()
				self.CooldownLight:Use()
				
				self.Legend:AnimationPlay("SaberSlam", 0)
				self.Legend:SoundPlay("AdrenalineRush")
				
				local range = 20
				
				self:GetClass("AbilityWarCry"):PushEnemies(self.Legend:GetPosition(), range)
				self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
					Position = self.Legend:GetPosition(),
					Range = range,
					Callback = function(enemy)
						self:GetService("DamageService"):Damage{
							Source = self.Legend,
							Target = enemy,
							Amount = self:GetDamage(),
							Weapon = self,
							Type = "Bludgeoning",
						}
						
						self:HitEffects(enemy, false)
					end
				})
				
				self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
					Position = self.Legend:GetPosition(),
					Radius = range,
					Duration = 0.25,
				})

				return true
			end
		}
	},
	[12] = {
		Name = "Iron Spear",
		Class = "WeaponSpear",
		AssetsName = "IronSpear",
		Description = "A hard iron tip on a sturdy wooden pole. Good for stabbing things from further away.",
		Image = "rbxassetid://5186668394",
		UpgradeMaterials = {Iron = 0.1},
	},
	[13] = {
		Name = "Iskith Druid Staff",
		Class = "WeaponStaffHealing",
		AssetsName = "WoodenStaff",
		Description = "The Iskith -- who live in a forest beneath an active volcano -- are quite familiar with the line between life and death. This staff reflects that knowledge.",
		Image = "rbxassetid://5196003444",
		UpgradeMaterials = {Iskith = 0.1, Worldstone = 0.01},
	},
	[14] = {
		Name = "Embriguard Spear",
		Class = "WeaponSpear",
		AssetsName = "EmbriguardSpear",
		Description = "A spear commonly used by the legendary Embriguard, guardians of the City of Peace. Despite their legend, the weapon itself is quite mundane.",
		Image = "rbxassetid://5206523898",
		UpgradeMaterials = {Steel = 0.1},
		Rarity = "Rare",
	},
	[15] = {
		Name = "Veteran's Blade",
		Class = "WeaponGreatsword",
		AssetsName = "VeteranBlade",
		Description = "A weapon rarely awarded to accomplished slayers. It is a symbol of skill, dedication, and achievement. It is an honor to wield one of these.",
		Image = "rbxassetid://5206523959",
	},
	[16] = {
		Name = "Blacksmith's Maul",
		Class = "WeaponMaul",
		AssetsName = "BlacksmithMaul",
		Description = "A hilariously oversized blacksmith's hammer, this weapon represents your dedication to the craft of weapon upgrading.",
		Image = "rbxassetid://5206523747",
	},
	[17] = {
		Name = "Golden Blacksmith's Maul",
		Class = "WeaponMaul",
		AssetsName = "BlacksmithMaulGolden",
		Description = "A heartfelt thanks to the truly dedicated for engaging with the process of collecting materials for a staggeringly well-crafted weapon.",
		Image = "rbxassetid://5206523837",
	},
	[18] = {
		Name = "Kakastan Lightning Staff",
		Class = "WeaponStaffLightning",
		AssetsName = "LightningStaff",
		Description = "The Kakastans are well known for their lightning magic, but since the Jolians took their sacred mountain, it's become much rarer.",
		Image = "rbxassetid://5229028375",
		UpgradeMaterials = {Steel = 0.1, Worldstone = 0.01},
		Rarity = "Rare",
	},
	[19] = {
		Name = "Executioner's Greatsword",
		Class = "WeaponGreatsword",
		AssetsName = "ExecutionerGreatsword",
		Description = "A tool for a macabre duty, not a weapon of war. The undead that once wielded it didn't know the difference.",
		Image = "rbxassetid://5230341045",
		UpgradeMaterials = {Steel = 0.1},
		Rarity = "Rare",
		Perks = {
			"Instantly fill rage upon killing an enemy, but spin attacks deal less damage.",
		},
		
		Args = {
			AttackHeavyDamageMultiplier = 0.35,
			
			OnDealtDamage = function(self, damage)
				if damage.Target.Health <= 0 then
					self.Rage = 120
				end
			end
		},
	},
	[20] = {
		Name = "Blade of Vengeance",
		Class = "WeaponSwordAndShield",
		AssetsName = "VengeanceSwordAndShield",
		Description = "The College mage that designed this weapon lost her husband at Rookie's Grave. Each sword is filled with her anger and his desperation.",
		Image = "rbxassetid://5239853155",
		UpgradeMaterials = {MetallicCorruption = 0.1},
		Rarity = "Rare",
		Perks = {
			"Deals up to 50% more damage depending on how depleted its shield is.",
		},
		
		Args = {
			OnWillDealDamage = function(self, damage)
				if damage.Weapon ~= self then return end
				
				local ratio = self.Block / self.BlockMax
				local bonus = 0.5 * (1 - ratio)
				
				damage.Amount = damage.Amount * (1 + bonus)
			end
		},
	},
	[21] = {
		Name = "Jolian Infantry Pistol",
		Class = "WeaponSaberAndPistol",
		AssetsName = "JolianInfantryPistol",
		Description = "A peculiar weapon from a foreign land. Uses a poorly understood technique called \"chemistry\" to launch a metal pellet at high speeds.",
		Image = "rbxassetid://5256307578",
		UpgradeMaterials = {Steel = 0.1},
		Rarity = "Rare",
	},
	[22] = {
		Name = "Soldier's Crossbow",
		Class = "WeaponCrossbowAndShortsword",
		AssetsName = "IronCrossbowAndShortsword",
		Description = "A heavy ranged weapon that uses metal rather than wood to propel bolts. More expensive -- and therefore rarer -- than traditional bows.",
		Image = "rbxassetid://5267682976",
		UpgradeMaterials = {Iskith = 0.1, Iron = 0.01},
	},
	[23] = {
		Name = "Lorithguard Sword",
		Class = "WeaponSwordAndShield",
		AssetsName = "LorithguardSword",
		Description = "Weapon of the accursed Lorithguard, turned to shadows at the Great Corruption. While mysteriously uncorrupted, this weapon's use of Worldstone is controversial.",
		Image = "rbxassetid://5301113157",
		UpgradeMaterials = {Iron = 0.1, Worldstone = 0.01},
		Rarity = "Rare",
		Perks = {
			function(self)
				return string.format("While mana is above %d%%, use mana to restore block.", self.ManaThreshold * 100)
			end,
		},
		Args = {
			UsesMana = true,
			
			ManaThreshold = 0.25,
			
			CustomOnUpdated = function(self, dt)
				local manaThreshold = self.Legend.MaxMana:Get() * self.ManaThreshold
				if self.Legend.Mana <= manaThreshold then return end
				
				local blockPerMana = 0.03 * self.BlockMax
				local blockPerSecond = 0.5 * self.BlockMax
				
				if (self.Block < self.BlockMax) and (self.Legend.Mana > 0) then
					local block = math.min(blockPerSecond * dt, self.BlockMax - self.Block)
					local mana = math.min(self.Legend.Mana, block / blockPerMana)
					block = mana * blockPerMana
					
					self.Legend.Mana = self.Legend.Mana - mana
					self.Legend.ManaRegenCooldown:Use()
					self.Block = self.Block + block
				end 
			end,
		}
	},
	[24] = {
		Name = "Orcish Strongbow",
		Class = "WeaponBowAndDagger",
		AssetsName = "OrcBowAndDagger",
		Description = "A vicious, savage, primitive weapon wielded by orcs, who favor strength above all things.",
		Image = "rbxassetid://5344908827",
		UpgradeMaterials = {Iskith = 0.1, Iron = 0.01},
		Rarity = "Rare",
		Perks = {
			"Shoots three arrows simultaneously which each deal half damage.",
		},
		Args = {
			AttackLightDamageMultiplier = 0.5,
			
			ProjectileCount = 3,
			ProjectileAngle = 30,
		}
	},
	[25] = {
		Name = "Orcish Shaman Staff",
		Class = "WeaponStaffHealing",
		AssetsName = "OrcStaff",
		Description = "A tool which employs crudely modified Orcish transformation magic in order to close wounds and restore flesh. Violent, too, like all orcish things.",
		Image = "rbxassetid://5428964197",
		UpgradeMaterials = {Iskith = 0.1, Worldstone = 0.01},
		Rarity = "Rare",
		Perks = {
			"Upon killing an enemy, apply the healing staff regeneration to all nearby allies.",
		},
		Args = {
			OnDealtDamage = function(self, damage)
				if damage.Target.Health <= 0 then
					local position = self.Legend:GetFootPosition()
					
					local range = 32
					
					self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
						Position = position,
						Radius = range,
						Color = Color3.fromRGB(46, 85, 46),
						Duration = 0.5,
						Style = Enum.EasingStyle.Quint,
					})
					self.Staff.Burst:Play()
					
					self.Targeting:TargetCircle(self.Targeting:GetMortals(), {
						Position = position,
						Range = range,
						Callback = function(ally)
							self:HealTarget(ally)
						end
					})
				end
			end
		}
	},
	[26] = require(script.LorithguardHammer),
	[27] = require(script.MercenarySabers),
	[28] = require(script.StaffOfShadows),
	[29] = require(script.ShadowScythe),
	[30] = require(script.MercenaryGreatmace),
	[31] = {
		Name = "Iron Handaxes",
		Class = "WeaponHandaxes",
		AssetsName = "IronHandaxes",
		Description = "Dangerous weapons from the land of Evrig. Weighted for throwing with brutal efficiency.",
		Image = "rbxassetid://5498039446",
		UpgradeMaterials = {Iron = 0.1},
	},
	[32] = require(script.Bluesteel).Handaxes,
	[33] = require(script.Bluesteel).Battleaxe,
	[34] = {
		Name = "Spiked Axe & Buckler",
		Class = "WeaponAxeAndBuckler",
		AssetsName = "SpikedAxeAndBuckler",
		Description = "An imposing weapon which trades some defensive capability for an offensive counterattack.",
		Image = "rbxassetid://5647961750",
		UpgradeMaterials = {Steel = 0.1},
		Perks = {
			"Has one fewer parry, but strikes for double damage enemies that are parried.",
		},
		Args = {
			BaseParriesMax = 1,
			OnParried = function(self, damage)
				if not damage.Source:IsA(self:GetClass("Enemy")) then return end
				if not damage.Source.Active then return end
				
				self:GetService"DamageService":Damage{
					Source = self.Legend,
					Target = damage.Source,
					Amount = self:GetDamage() * 2,
					Weapon = self,
					Type = "Piercing",
				}
			end,
		}
	},
	[35] = {
		Name = "Twitch Bit Hammer",
		Class = "WeaponMaul",
		AssetsName = "TwitchBitHammer",
		Description = "A weapon commemorating Davidii's Twitch channel reaching 1,000 followers.",
		Image = "rbxassetid://5651241892",
		UpgradeMaterials = {Worldstone = 0.1},
	},
	[36] = {
		Name = "Evrig Torch",
		Class = "WeaponTorch",
		AssetsName = "EvrigTorch",
		Description = "",
		Image = "",
	},
	[37] = require(script.JolianFireLance),
	[38] = {
		Name = "Iron Rapier",
		Class = "WeaponRapier",
		AssetsName = "IronRapier",
		Description = "A weapon wielded by the nobility of the Kingdom of Sketh. Notoriously difficult to master.",
		Image = "rbxassetid://5673074193",
		UpgradeMaterials = {Iron = 0.1},
	},
	[39] = require(script.Steel).Rapier,
	[40] = require(script.Bluesteel).Crossbow,
	[41] = require(script.Bluesteel).Sword,
	[42] = require(script.Bluesteel).Axe,
	[43] = {
		Name = "Iron Dual Dirks",
		Class = "WeaponDualDirks",
		AssetsName = "IronDualDirks",
		Description = "Longer than a dagger, shorter than a shortsword. Light enough to use two.",
		Image = "rbxassetid://5686741768",
		UpgradeMaterials = {Iron = 0.1},
	},
	[44] = require(script.Steel).Dirks,
	[45] = require(script.Bluesteel).Claws,
	[46] = {
		Name = "Jolian Musket",
		Class = "WeaponMusket",
		AssetsName = "JolianMusket",
		Description = "What is best described as a large Jolian pistol. An inscrutable weapon that propels small projectiles at unbelievable speeds.",
		Image = "rbxassetid://5703376457",
		UpgradeMaterials = {Steel = 0.1, Coal = 0.01},
		Rarity = "Rare",
	},
	[47] = {
		Name = "Cryptkeeper's Bellaxe",
		Class = "WeaponBattleaxe",
		AssetsName = "CryptkeeperBellaxe",
		Description = "A weapon from a forgotten ancient sect which honored their dead with dolorous bells.",
		Image = "rbxassetid://5733023202",
		UpgradeMaterials = {Steel = 0.1, MetallicCorruption = 0.01},
		Rarity = "Mythic",
		Perks = {
			"Charge attacks create a large stunning shockwave with minor damage.",
		},
		Args = {
			OnLeapAttacked = function(self, target)
				local radius = 64
				local here = target:GetPosition()
				
				self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
					Position = here,
					Radius = radius,
					Duration = 0.25,
					Color = BrickColor.new("Bronze").Color,
				})
				
				local radiusSq = radius ^ 2
				local enemies = self:GetService("TargetingService"):GetEnemies()
				for _, enemy in pairs(enemies) do
					local delta = (enemy:GetPosition() - here) * Vector3.new(1, 0, 1)
					local distanceSq = delta.X ^ 2 + delta.Z ^ 2
					if distanceSq <= radiusSq then
						self:GetService("DamageService"):Damage{
							Source = self.Legend,
							Target = enemy,
							Amount = self:GetDamage() * 0.2,
							Type = "Bludgeoning",
						}
						
						if not enemy.Resilient then
							enemy:AddStatus("StatusStunned", {
								Time = 1,
							})
						end
					end
				end
				
				self.Legend:SoundPlayByObject(self.Assets.Sounds.Bell)
			end
		}
	},
	[48] = require(script.ReclaimedJukumaiStaff),
	[49] = {
		Name = "Slayer Scout's Javelin",
		Class = "WeaponJavelin",
		AssetsName = "SlayerScoutJavelin",
		Description = "Slayer Alliance scouts need to pack light, and this javelin is more versatile and less cumbersome than a bow and arrows.",
		Image = "rbxassetid://5734981133",
		UpgradeMaterials = {Iskith = 0.1, Iron = 0.01},
	},
	[50] = require(script.PurifiedJukumaiStaff),
	[51] = require(script.ValiantJukumaiStaff),
	[52] = {
		Name = "Mana Bow",
		Class = "WeaponBowAndDagger",
		AssetsName = "ManaBow",
		Description = "An intriguing spell that summons an ethereal bow to fire magical arrows at enemies.",
		Image = "rbxassetid://5765358813",
		UpgradeMaterials = {Worldstone = 0.1, Steel = 0.01},
		Rarity = "Rare",
		Perks = {
			"Costs mana to fire.",
			"Arrows home in on the nearest target.",
			"Melee attacks grant mana.",
		},
		Args = {
			PrimaryStatName = "Agility",
			UsesMana = true,
			ProjectileModel = Models.ManaArrow,
			ManaCost = 7.5,
			ProjectileHoming = true,
			ProjectileHomingRotationSpeed = math.pi * 3,
			ProjectileHomingRange = 32,
			ProjectileSpeed = 128,
			DamageTags = {"Magical"},
			
			OnAttackedHeavy = function(self)
				self.Legend.Mana = math.min(self.Legend.Mana + self.ManaCost / 2, self.Legend.MaxMana:Get())
			end,
			GetManaCost = function(self)
				local cost = self.ManaCost
				if self:HasModifier("Efficient") then
					cost *= 0.5
				end
				return cost
			end,
			CustomAttackLightAble = function(self)
				local cost = self:GetManaCost()
				return self.Legend:CanUseMana(cost)
			end,
			OnAttackedLight = function(self)
				self.Legend:UseMana(self:GetManaCost())
			end,
		}
	},
	[53] = {
		Name = "3rd Age Pirate Cutlasses",
		Class = "WeaponSabers",
		AssetsName = "PirateSabers",
		Description = "During its peak, the coasts of Lorithas teemed with waterborne thieves. Weapons such as these were popular among them.",
		Image = "rbxassetid://5805125325",
		UpgradeMaterials = {Steel = 0.1},
		Rarity = "Rare",
		Perks = {
			[[Dual strikes grant stacks of "Swagger."]]
		},
		Args = {
			DescriptionHeavy = "Expend all Swagger to spin rapidly, damaging enemies. Spin longer the more Swagger expended.",
			SpinRangeSq = 12 ^ 2,
			
			OnEquip = function(self)
				self:FireRemote("AimAmmoUpdated", self.Legend.Player, {Type = "Show"})
			end,
			
			OnUnequip = function(self)
				self:FireRemote("AimAmmoUpdated", self.Legend.Player, {Type = "Hide"})
			end,
			
			OnUpdated = function(self, dt)
				if not self.Spinning then
					self:FireRemote("AimAmmoUpdated", self.Legend.Player, {
						Type = "Update",
						Ammo = self.Swagger or 0,
						AimWord = "Spin Attack",
						AmmoWord = "Swagger",
						Ratio = self.AttackNumber / 3,
					})
				end
			end,
			AttackHeavy = function(self)
				if not self.CooldownHeavy:IsReady() then return end
				
				if not (self.Swagger and self.Swagger > 0) then return end
				
				local secondsPerSwagger = 0.6
				local spinsPerSecond = 5
				local duration = self.Swagger * secondsPerSwagger
				local maxDuration = duration
				
				self.CooldownHeavy:Use(duration)
				self.CooldownLight:Use(duration)
				
				spawn(function()
					self.Spinning = true
					
					self.Right.Trail.Enabled = true
					self.Left.Trail.Enabled = true
					
					local interval = 1 / spinsPerSecond
					
					self.Legend:AnimationPlay("SaberSpin", nil, nil, spinsPerSecond)
					
					self.Legend:Channel(duration, "Swagger Spin", "Normal", {
						Interval = interval,
						CustomOnTicked = function(t, dt)
							if not self:IsEquipped() then
								return t:Fail()
							end

							self:FireRemote("AimAmmoUpdated", self.Legend.Player, {
								Type = "Update",
								Ammo = 0,
								AimWord = "Spin Attack",
								AmmoWord = "Swagger",
								Ratio = duration / maxDuration,
							})

							for _, enemy in pairs(self:GetService("TargetingService"):GetEnemies()) do
								local delta = (enemy:GetPosition() - self.Legend:GetPosition())
								local distanceSq = delta.X ^ 2 + delta.Z ^ 2
								if distanceSq < self.SpinRangeSq then
									self:HitEnemy(enemy, self:GetDamage())
								end
							end

							self.Legend:SoundPlayByObject(self.Assets.Sounds.Spin)
						end,
					})
					
					self.CooldownHeavy:Use(0.25)
					self.CooldownLight:Use(0.25)
					
					self.Legend:AnimationStop("SaberSpin")
					
					self.Right.Trail.Enabled = false
					self.Left.Trail.Enabled = false
					
					self.Spinning = false
				end)
				
				self.Swagger = 0

				return true
			end,
			OnDualHitEnemy = function(self)
				self.Swagger = (self.Swagger or 0) + 1
			end,
		}
	},
	[54] = {
		Name = "Grimstone Greatsword",
		Class = "WeaponGreatsword",
		AssetsName = "GrimstoneGreatsword",
		Description = "A weapon wielded by the Terrorknights, the ancient jailors of Lorithas.",
		Image = "rbxassetid://5805150643",
		UpgradeMaterials = {MetallicCorruption = 0.1},
		Rarity = "Mythic",
		Perks = {
			"Drastically increase movement speed while spinning.",
		},
		Args = {
			OnSpinAttack = function(self)
				local legend = self.Legend
				local amount = 2
				legend:AddStatus("Status", {
					Time = 0.4,
					Type = "GrimstoneGreatswordSpeedBuff",
					
					Category = "Good",
					ImagePlaceholder = "GRMST\nSPD",
					
					OnStarted = function()
						legend.Speed.Percent += amount
					end,
					OnEnded = function()
						legend.Speed.Percent -= amount
					end
				})
			end
		}
	},
	[55] = {
		Name = "Grimstone Javelin",
		Class = "WeaponJavelin",
		AssetsName = "GrimstoneJavelin",
		Description = "The Terrorknights had creative ways of preventing the escape of their wards.",
		Image = "rbxassetid://5805293134",
		UpgradeMaterials = {MetallicCorruption = 0.1},
		Rarity = "Mythic",
		Perks = {
			"Targets struck by thrown javelins are pulled in but take less damage. Does not affect resilient enemies.",
		},
		Args = {
			ImpaleDamage = 0.5,
			OnThrownJavelinHitEnemy = function(self, enemy)
				if enemy.Health <= 0 then
					self:SetJavelinState(true)
					return
				end
				
				if enemy.Resilient then return end
				
				enemy:AddStatus("StatusStunned", {
					Time = 0,
				})
				
				local here = self.Legend:GetPosition()
				local there = enemy:GetPosition()
				local delta = (there - here) * Vector3.new(1, 0, 1)
				there = here + delta.Unit * 2
				here = enemy:GetPosition()
				delta = (there - here) * Vector3.new(1, 0, 1)
				
				local distance = delta.Magnitude
				local speed = 256
				local duration = distance / speed
				
				self:TweenNetwork{
					Object = enemy.Root,
					Goals = {CFrame = enemy.Root.CFrame + delta},
					Duration = duration,
					EasingStyle = Enum.EasingStyle.Linear,
				}
				
				local a0 = Instance.new("Attachment", self.Legend.Model.RightHand)
				local a1 = Instance.new("Attachment", enemy.Root)
				local beam = self.Storage.Models.GrimstoneJavelinBeam:Clone()
				beam.Attachment0 = a0
				beam.Attachment1 = a1
				beam.Parent = workspace.Effects
				delay(duration, function()
					a0:Destroy()
					a1:Destroy()
					beam:Destroy()
				end)
			end
		}
	},
	[56] = {
		Name = "Cleavers",
		Class = "WeaponHandaxes",
		AssetsName = "Cleavers",
		Description = "A small portion of the collection of brutal weapons owned by the Terror Warden.",
		Image = "rbxassetid://5821700995",
		UpgradeMaterials = {Steel = 0.1},
		Rarity = "Rare",
		Perks = {
			"Targets struck by the thrown cleaver are slowed to a crawl and bleed for extra damage for a short duration."
		},
		Args = {
			ThrowOffset = CFrame.Angles(0, math.pi / 2, 0),
			
			OnThrownAxeHitEnemy = function(self, enemy)
				local slow = 0.8
				local duration = 3
				local dps = self:GetDamage() * 0.25
				local resilient = enemy.Resilient
				
				enemy:AddStatus("Status", {
					Type = "CleaversBleed",
					Time = duration,
					Interval = 0.2,
					OnStarted = function()
						if resilient then return end
						enemy.Speed.Percent -= slow
					end,
					OnTicked = function(status, dt)
						self:GetService("DamageService"):Damage{
							Source = self.Legend,
							Target = enemy,
							Amount = dps * dt,
							Weapon = self,
							Type = "Internal",
						}
					end,
					OnEnded = function()
						if resilient then return end
						enemy.Speed.Percent += slow
					end
				})
			end
		}
	},
	[57] = {
		Name = "Corsair Longsword",
		Class = "WeaponLongsword",
		AssetsName = "CorsairLongsword",
		Description = "A weapon steeped in bravado and poise. Shields are for cowards!",
		Image = "rbxassetid://5896443464",
		UpgradeMaterials = {Iron = 0.1},
	},
	[58] = require(script.OrcChieftanGreatsword),
	
	-- lijack123 was here 11/6/2020
	[59] = require(script.OrcElderStaff),
	[60] = {
		Name = "Festive Urvok's Club",
		Class = "WeaponMaul",
		AssetsName = "UrvokClubFestive",
		Description = "Merry Christmas!",
		Image = "rbxassetid://6133950109",
		Rarity = "Rare",
		UpgradeMaterials = {Iskith = 0.1},
		Perks = {
			"While under half health, slam is larger.",
		},

		Args = {
			UrvokActive = false,
			UrvokBonus = 0.5,

			CustomOnUpdated = function(self, dt)
				local ratio = self.Legend.Health / self.Legend.MaxHealth:Get()

				if self.UrvokActive and (ratio > 0.5) then
					self.Radius.Percent = self.Radius.Percent - self.UrvokBonus
					self.UrvokActive = false

				elseif (not self.UrvokActive) and (ratio < 0.5) then
					self.Radius.Percent = self.Radius.Percent + self.UrvokBonus
					self.UrvokActive = true
				end
			end
		}
	},
	[61] = {
		Name = "Kickstarter Axe",
		Class = "WeaponAxeAndBuckler",
		AssetsName = "KickstarterAxeAndBuckler",
		Description = "Words can't express my gratitude for your support, so I gave you a deadly weapon instead. A personal thank you from David. Good luck, slayer!",
		Image = "rbxassetid://6308744794",
		UpgradeMaterials = {Steel = 0.1},
	},
	[62] = {
		Name = "Golden Battleaxe",
		Class = "WeaponBattleaxe",
		AssetsName = "GoldenBattleaxe",
		Description = "Gave up at least 7 Rare weapons when transferring to Embrithas.",
		Image = "rbxassetid://6385945109",
		UpgradeMaterials = {Gold = 0.1},
	},
	[63] = {
		Name = "Diamond Longsword",
		Class = "WeaponLongsword",
		AssetsName = "DiamondLongsword",
		Description = "Gave up at least 7 Mythic weapons when transferring to Embrithas.",
		Image = "rbxassetid://6386017312",
		UpgradeMaterials = {Gold = 0.01, Gemstones = 0.01},
	},
	[64] = {
		Name = "Giant Spyglass",
		Class = "WeaponMaul",
		AssetsName = "GiantSpyglass",
		Description = "Gave up mission completions with at least 3 raids when transferring to Embrithas.",
		Image = "rbxassetid://6386120061",
		UpgradeMaterials = {Gold = 0.1},
	},
	[65] = {
		Name = "Blade of Discord",
		Class = "WeaponLongsword",
		AssetsName = "BladeOfDiscord",
		Description = "A weapon that sows chaos where it slashes. What? Did you think the word \"discord\" was in reference to something else?",
		Image = "rbxassetid://7009405765",
		UpgradeMaterials = {Bluesteel = 0.1},
		SalvageDisabled = true,
	},
	[66] = {
		Name = "Iron-ringed Wand",
		Class = "WeaponWand",
		AssetsName = "IronRingedWand",
		Description = "A basic mage's wand. Good for intellectual types who don't like to get too close to the action.",
		Image = "rbxassetid://7043051269",
		UpgradeMaterials = {Iskith = 0.1, Iron = 0.01, Worldstone = 0.01},
	},
	[67] = {
		Name = "Shadow Wand",
		Class = "WeaponWand",
		AssetsName = "ShadowWand",
		Description = "A wand made with shadow-infused worldstone. Pulses as though it has a will of its own.",
		Image = "rbxassetid://7043156795",
		UpgradeMaterials = {Iskith = 0.1, Steel = 0.01, Worldstone = 0.01},
		Rarity = "Rare",
		Perks = {
			"Explosion deals 50% less damage but afflicts enemies with shadow.",
			"Projectiles that hit shadow-afflicted targets deal 50% more damage and refund their mana cost.",
		},
		Args = {
			ProjectileModel = Models.ShadowBolt,
			ProjectileModelHeavy = Models.ShadowBoltLarge,
			HeavyColor = Color3.new(0, 0, 0),
			GetLightDamage = function(self, enemy)
				local damage = self:GetSuper().GetLightDamage(self)
				if enemy:HasStatusType("ShadowAfflicted") then
					damage *= 1.5
				end
				return damage
			end,
			OnLightHit = function(self, enemy)
				if enemy:HasStatusType("ShadowAfflicted") then
					self.Legend:AddMana(self.ManaCostLight)
				end
			end,
			GetHeavyDamage = function(self)
				return self:GetSuper().GetHeavyDamage(self) * 0.5
			end,
			OnHeavyHit = function(self, enemy)
				local status = enemy:GetStatusByType("ShadowAfflicted")
				if status then
					status:Restart()
				else
					enemy:AddStatus("StatusShadowAfflicted", {
						Time = 5,
					})
				end
			end,
		}
	},
	[68] = {
		Name = "Erstwhile Vainglory",
		Class = "WeaponFiaraSword",
		AssetsName = "FiaraSword",
		Description = "An unimaginably well-crafted weapon once wielded by Fiara, the relatively unknown but unmistakably skilled bodyguard of Lorithas' High King.",
		Image = "rbxassetid://7051385339",
		Rarity = "Legendary",
	},
	[69] = {
		Name = "Pickaxe",
		Class = "WeaponMaul",
		AssetsName = "Pickaxe",
		Description = "A tool for breaking rocks. Wait, you're not seriously considering fighting with this, are you?",
		Image = "rbxassetid://7067599554",
		Perks = {
			"Gain bonus resources when mining in mineshafts.",
		},
		UpgradeMaterials = {Iron = 0.1},
	},
	[70] = {
		Name = "Hestinian Ignition Bow",
		Class = "WeaponBowAndDagger",
		AssetsName = "HestinianIgnitionBow",
		Description = "Designed by the military scientists in Hestingrav, this bow fires oil-soaked arrowheads that are ignited upon loosing by a small worldstone device embedded in the bow itself.",
		Image = "rbxassetid://7080308755",
		Perks = {
			function(self)
				return string.format("Arrows deal %d%% less damage.", (1 - self.AttackLightDamageMultiplier) * 100)
			end,
			function(self)
				return string.format("Enemies struck by arrows take %d physical heat damage over %d seconds. This effect does not stack.", self:GetBurnDamage(), self.BurnDuration)
			end,
		},
		Rarity = "Rare",
		UpgradeMaterials = {Steel = 0.1, Iskith = 0.01},
		SalvageDisabled = true,
		Args = {
			ProjectileModel = Models.FireArrow,
			
			AttackLightDamageMultiplier = 0.375,
			BurnDuration = 3,
			
			StatusType = "HibBurning",
			
			GetBurnDamage = function(self)
				return self:GetDamagePerSecond() * self.BurnDuration * 0.8
			end,
			
			OnLightHitEnemy = function(self, enemy)
				local status = enemy:GetStatusByType(self.StatusType)
				if status then
					status:UpdateDamage(self:GetBurnDamage())
					status:Restart()
				else
					enemy:AddStatus("StatusBurning", {
						Source = self.Legend,
						Type = self.StatusType,
						Time = self.BurnDuration,
						Damage = self:GetBurnDamage(),
					})
				end
			end,
		}
	}
}

local abilities = {
	[1] = {
		Name = "Combat Roll",
		Class = "AbilityCombatRoll",
		Image = "rbxassetid://5032181017",
		Description = "Quickly roll out of harm's way.",
	},
	[2] = {
		Name = "War Cry",
		Class = "AbilityWarCry",
		Image = "rbxassetid://5121252085",
		Description = "Bellow out an intimidating war cry, pushing enemies away from you and cancelling their attacks. Does not affect resilient targets like bosses.",
	},
	[3] = {
		Name = "Sprint",
		Class = "AbilitySprint",
		Image = "rbxassetid://5121251901",
		Description = "Sprint, even during combat.",
	},
	[4] = {
		Name = "Fire Strike",
		Class = "AbilityStrikeFire",
		Image = "rbxassetid://5825253802",
		Description = "Hurl a bolt of fire at the nearest enemy, setting them ablaze.",
		UpgradeMaterials = {Worldstone = 0.1},
	},
	[5] = {
		Name = "Earth Strike",
		Class = "AbilityStrikeEarth",
		Image = "rbxassetid://5825254037",
		Description = "Launch a boulder at the nearest enemy, harming and stunning them and nearby targets.",
		UpgradeMaterials = {Worldstone = 0.1},
	},
	[6] = {
		Name = "Frost Strike",
		Class = "AbilityStrikeFrost",
		Image = "rbxassetid://5579003829",
		Description = "Fling icicles at nearby enemies, damaging them.",
		UpgradeMaterials = {Worldstone = 0.1},
	},
	[7] = {
		Name = "Lightning Strike",
		Class = "AbilityStrikeLightning",
		Image = "rbxassetid://5825253963",
		Description = "Conjure a lightning bolt from yourself to the nearest enemy which damages them and then leaps to the next target.",
		UpgradeMaterials = {Worldstone = 0.1},
	},
	[8] = {
		Name = "Wind Strike",
		Class = "AbilityStrikeWind",
		Image = "rbxassetid://5579004036",
		Description = "Summon a powerful gust of wind which blows away the nearest enemy.",
		UpgradeMaterials = {Worldstone = 0.1},
	},
	[9] = {
		Name = "Combat Teleport",
		Class = "AbilityCombatTeleport",
		Image = "rbxassetid://5584617149",
		Description = "Instantly teleport in the direction you're moving.",
	},
	[10] = {
		Name = "Distant Blessing",
		Class = "AbilityDistantBlessing",
		Image = "rbxassetid://5703645884",
		Description = "Heal yourself and nearby allies.",
		UpgradeMaterials = {Worldstone = 0.1},
	},
	[11] = {
		Name = "Mana Darts",
		Class = "AbilityManaDarts",
		Image = "rbxassetid://5758458605",
		Description = "Shoot mana darts at a nearby enemy, dealing damage.",
		UpgradeMaterials = {Worldstone = 0.1},
	},
	[12] = {
		Name = "Hold Fast",
		Class = "AbilityHoldFast",
		Image = "rbxassetid://5768744089",
		Description = "Block nearly all of incoming damage for a moment."
	},
	[13] = {
		Name = "Taunt",
		Class = "AbilityTaunt",
		Image = "rbxassetid://5805447262",
		Description = "Force nearby enemies to target you for a duration.",
	},
	[14] = {
		Name = "Mana Blast",
		Class = "AbilityManaBlast",
		Image = "rbxassetid://5670415600",
		Description = "Blast a linear area with mana, dealing damage.",
		UpgradeMaterials = {Worldstone = 0.1},
	},
	[15] = {
		Name = "Blessed Water Flask",
		Class = "AbilityBlessedWaterFlask",
		Image = "rbxassetid://7024572293",
		Description = "Throw a flask of blessed water to a location, damaging spiritual enemies like Undead and Shadows and healing allies.",
		UpgradeMaterials = {Worldstone = 0.1},
	},
	[16] = {
		Name = "Rain of Projectiles",
		Class = "AbilityRainOfProjectiles",
		Image = "rbxassetid://7033902731",
		Description = "Requires a ranged weapon. Rain projectiles from a projectile weapon down on a targeted area.",
	},
	[17] = {
		Name = "Ricochet",
		Class = "AbilityRicochet",
		Image = "rbxassetid://7033902625",
		Description = "Requires a ranged weapon. Fire a bouncing projectile that hits multiple enemies.",
	},
	[18] = {
		Name = "Fan of Projectiles",
		Class = "AbilityFanOfProjectiles",
		Image = "rbxassetid://7033902784",
		Description = "Requires a ranged weapon. Fire many projectiles in a fan, hitting a wide area.",
	},
	[19] = {
		Name = "Explosive Projectile",
		Class = "AbilityExplosiveProjectile",
		Image = "rbxassetid://7033902842",
		Description = "Requires a ranged weapon. Fire an explosive projectile, dealing damage to enemies in an area.",
	},
	[20] = {
		Name = "Projectile Barrage",
		Class = "AbilityProjectileBarrage",
		Image = "rbxassetid://7034299360",
		Description = "Requires a ranged weapon. Unleash a barrage of projectiles.",
	},
	[21] = {
		Name = "Flurry",
		Class = "AbilityFlurry",
		Image = "rbxassetid://7057712081",
		Description = "Requires a dual-wield weapon. Unleash a flurry of attacks."
	},
	[22] = {
		Name = "Spin Attack",
		Class = "AbilitySpinAttack",
		Image = "rbxassetid://7057711993",
		Description = "Requires a dual-wield weapon. Spin for a duration, dealing damage to enemies around you.",
	},
	[23] = {
		Name = "Ferocious Charge",
		Class = "AbilityFerociousCharge",
		Image = "rbxassetid://7057712159",
		Description = "Requires a dual-wield weapon. Charge at the targeted enemy and other enemies in a chain, dealing damage to each and remaining untargetable during the attack."
	},
	[24] = {
		Name = "Honorable End",
		Class = "AbilityHonorableEnd",
		Image = "rbxassetid://7062504518",
		Description = "Requires a longsword. Immediately plunge your own sword into your chest.",
	}
}

local trinkets = require(script.Trinkets)

local materials = {
	[1] = {
		Name = "Iron Ingot",
		Image = "rbxassetid://5152781345",
		Description = "A basic metal. Durable, dependable, and malleable, but prone to rusting.",
		InternalName = "Iron",
	},
	[2] = {
		Name = "Steel Ingot",
		Image = "rbxassetid://5152781811",
		Description = "Lighter and more flexible than iron. A strictly -- albeit slightly -- better metal in nearly every respect.",
		InternalName = "Steel",
	},
	[3] = {
		Name = "Bloodsteel Ingot",
		Image = "rbxassetid://5152781001",
		Description = "A metal found beneath the sites of great battles. Always rough to the touch no matter how polished, making it ideal for lacerating foes.",
		InternalName = "Bloodsteel",
	},
	[4] = {
		Name = "Bluesteel Ingot",
		Image = "rbxassetid://5152781182",
		Description = "Evrig's main export, bluesteel is actually a mysterious ice mined from the Great Glacier. It has many metal-like attributes, however, and is highly magical.",
		InternalName = "Bluesteel",
	},
	[5] = {
		Name = "Emberwood Planks",
		Image = "rbxassetid://5152781265",
		Description = "An import from the pyroclastic crags of the Jolian Empire's homeland, emberwood is hot to the touch and extremely durable.",
		InternalName = "Emberwood",
	},
	[6] = {
		Name = "Iskith Planks",
		Image = "rbxassetid://5152781458",
		Description = "Wood from the iskith tree, native to the heavily-forested island of Iskis. Light, flexible, and rot-resistant.",
		InternalName = "Iskith",
	},
	[7] = {
		Name = "Lorithwood Planks",
		Image = "rbxassetid://5152781538",
		Description = "Planks cut from corrupted worldtrees in Lorithas. Corruption grows from them, making them difficult to work with, and only College carpenters dare try.",
		InternalName = "Lorithwood",
	},
	[8] = {
		Name = "Metallic Corruption",
		Image = "rbxassetid://5152781626",
		Description = "An invention of the College of Reclamation, it's metal carefully exposed to corruption. The orderly structure keeps it contained, or so the College artificers claim. The rarer the metal, the more can be made.",
		InternalName = "MetallicCorruption",
	},
	[9] = {
		Name = "Worldmetal",
		Image = "rbxassetid://5152781911",
		Description = "Worldstone that has been refined in the Goddessforge of Embrithas. Extremely rare, as it is impossible to make anywhere else.",
		InternalName = "Worldmetal",
	},
	[10] = {
		Name = "Worldstone",
		Image = "rbxassetid://5152781984",
		Description = "The source of all magic. Extremely common on this world, but, according to legend, extremely rare throughout the universe.",
		InternalName = "Worldstone",
	},
	[11] = {
		Name = "Shadow-infused Worldstone",
		Image = "rbxassetid://5471923265",
		Description = "What remains of a life snuffed out by the Great Corruption suspended in Worldstone. Its uncorruptedness and its tragedy lend it a strange neutrality.",
		InternalName = "ShadowWorldstone",
	},
	[12] = {
		Name = "Coal",
		Image = "rbxassetid://5534583257",
		Description = "A soft, darkly-colored rock that can be set aflame. Used in the creation of steel.",
		InternalName = "Coal",
	},
	[13] = {
		Name = "Imbued Gold",
		Image = "rbxassetid://5910129438",
		Description = "A gold-worldstone alloy used in the creation of magical jewelry.",
		InternalName = "Gold",
	},
	[14] = {
		Name = "Gemstones",
		Image = "rbxassetid://5910128446",
		Description = "Various precious jewels from deep within the world. Similar to worldstone, but not quite as general-purpose.",
		InternalName = "Gemstones",
	},
}

local categories = {
	Weapons = weapons,
	Abilities = abilities,
	Trinkets = trinkets,
	Materials = materials,
}

for _, category in pairs(categories) do
	for id, itemData in pairs(category) do
		itemData.Id = id
	end
end

return categories