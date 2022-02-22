local Super = require(script.Parent)
local AbilityManaBlast = Super:Extend()

AbilityManaBlast.Type = "Offense"

AbilityManaBlast.UsesMana = true
AbilityManaBlast.ManaCost = 25
AbilityManaBlast.CooldownTime = 4

AbilityManaBlast.Width = 6
AbilityManaBlast.WidthBoost = 2

function AbilityManaBlast:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = self.CooldownTime
end

function AbilityManaBlast:GetDamage()
	return self:GetPowerHelper("Dominance") * 1.5
end
function AbilityManaBlast:GetLength()
	return self:Lerp(48, 96, self:GetUpgrades() / 10)
end

function AbilityManaBlast:GetDescription()
	return string.format(
		"Channel briefly and unleash a mana blast towards your targeted location. The area struck is %d feet long and affected enemies take %d damage. Costs %d mana. Cooldown: %4.2fs.",
		self:GetLength(),
		self:GetDamage(),
		self.ManaCost,
		self.CooldownTime
	)
end

function AbilityManaBlast:OnActivatedServer()
	local manaCost = self.ManaCost
	
	if not self.Legend:CanUseMana(manaCost) then return false end
	
	local function fail(sound)
		self.Cooldown:Use(0)
		
		sound:Stop()
	end
	
	spawn(function()
		self.Legend:AnimationPlay("TwoHandBlast")
		
		local sound = self.Legend:SoundPlayByObject(self.Storage.Sounds.MagicCharge2)
		
		if self.Legend:Channel(0.5, "Mana Blast", "Normal") then
			if not self.Legend:CanUseMana(manaCost) then
				fail()
				return
			end
			self.Legend:UseMana(manaCost)
			
			local length = self:GetLength()
			
			local cframe = self.Legend:GetAimCFrame()
			cframe *= CFrame.new(0, 0, -length / 2)
			
			self.Targeting:TargetSquare(self.Targeting:GetEnemies(), {
				CFrame = cframe,
				Length = length,
				Width = self.Width + self.WidthBoost,
				Callback = function(enemy)
					self:GetService"DamageService":Damage{
						Source = self.Legend,
						Target = enemy,
						Amount = self:GetDamage(),
					Weapon = self,
						Type = "Disintegration",
						Tags = {"Magical"},
					}
				end,
			})
			
			self:GetService("EffectsService"):RequestEffectAll("LinearBlast", {
				CFrame = cframe,
				Length = length,
				Width = self.Width,
				Duration = 0.25,
				PartArgs = {
					Transparency = 0.5,
					Material = Enum.Material.Neon,
					Color = Color3.fromRGB(0, 170, 255),
				}
			})
			
			self.Legend:SoundPlayByObject(self.Storage.Sounds.MagicEerie)
		else
			fail(sound)
		end
	end)
	
	return true
end

return AbilityManaBlast