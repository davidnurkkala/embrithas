local Super = require(script.Parent)
local Ability = Super:Extend()

Ability.Type = "Offense"

Ability.Radius = 16
Ability.Range = 64
Ability.HealingCooldown = 30

function Ability:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 10
end

function Ability:GetDescription()
	return string.format(
		[[Hurl a flask of Goddess-blessed water to the targeted location within %d feet. The water splashes in an area %d feet in radius. The water deals %d magical disintegration damage to spiritual enemies such as Undead and Shadows. Mortals hit by the water are also healed for %d health, but a mortal cannot be healed by blessed water more than once per %d seconds.]],
		self.Range,
		self.Radius,
		self:GetDamage(),
		self:GetHealing(),
		self.HealingCooldown
	)
end

function Ability:GetDamage()
	return self:Lerp(150, 300, self:GetUpgrades() / 10)
end

function Ability:GetHealing()
	return self:Lerp(50, 100, self:GetUpgrades() / 10)
end

function Ability:OnActivatedServer()
	local duration = 0.25
	local position = self.Targeting:GetClampedAimPosition(self.Legend, self.Range)
	
	self.Legend:AnimationPlay("LeftHandThrow")
	
	local effectsService = self:GetService("EffectsService") 
	effectsService:RequestEffectAll("LobProjectile", {
		Start = self.Legend:GetPosition(),
		Finish = position,
		Height = 16,
		Duration = duration,
		FadeDuration = 0,
		Model = self.Storage.Models.BlessedWaterFlask,
	})
	
	delay(duration, function()
		-- actually deal damage
		self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
			Position = position,
			Range = self.Radius,
			Callback = function(enemy)
				if not enemy:HasTag("Spiritual") then return end
				
				self:GetService("DamageService"):Damage{
					Source = self.Legend,
					Target = enemy,
					Amount = self:GetDamage(),
					Weapon = self,
					Type = "Disintegration",
					Tags = {"Magical"},
				}
			end,
		})
		
		-- heal allies
		local statusType = "AbilityBlessedWaterFlaskCooldown"
		
		self.Targeting:TargetCircle(self.Targeting:GetMortals(), {
			Position = position,
			Range = self.Radius,
			Callback = function(ally)
				if ally:HasStatusType(statusType) then return end
				
				self:GetService("DamageService"):Heal{
					Source = self.Legend,
					Target = ally,
					Amount = self:GetHealing(),
				}
				
				ally:AddStatus("Status", {
					Time = self.HealingCooldown,
					Type = statusType,
					
					ImagePlaceholder = "BWF\nHEAL\nCD",
				})
			end,
		})
		
		-- sounds
		for _, soundName in pairs{"GlassBreak1", "Heal1"} do
			effectsService:RequestEffectAll("Sound", {
				Sound = self.Storage.Sounds[soundName],
				Position = position,
			})
		end
		
		-- visuals
		effectsService:RequestEffectAll("Shockwave", {
			Duration = 0.25,
			StartSize = Vector3.new(),
			EndSize = Vector3.new(self.Radius * 2.5, 2, self.Radius * 2.5),
			CFrame = CFrame.new(position),
			PartArgs = {
				Material = Enum.Material.Neon,
				BrickColor = BrickColor.new("Gold"),
			}
		})
		for d = 0.25, 0.75, 0.25 do
			effectsService:RequestEffectAll("AirBlast", {
				Position = position,
				Radius = self.Radius,
				Duration = d,
				PartArgs = {
					Material = Enum.Material.Neon,
				}
			})
		end
	end)
	
	return true
end

return Ability