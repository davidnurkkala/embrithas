local Super = require(script.Parent)
local Ability = Super:Extend()

Ability.Type = "Offense"

Ability.UsesMana = true
Ability.ManaCost = 50
Ability.Range = 64
Ability.BounceRange = 32

function Ability:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 1
end

function Ability:GetDamage()
	return self:GetPowerHelper("Dominance")
end

function Ability:GetBounceCount()
	return math.floor(self:Lerp(3, 8, self:GetUpgrades() / 10))
end

function Ability:GetDescription()
	return string.format(
		"Shoot a lightning bolt in the targeted direction. If it hits an enemy, they will take %d damage and the bolt will bounce to the nearest unaffected enemy. The bolt can affect a total of %d targets. Costs %d mana.",
		self:GetDamage(),
		self:GetBounceCount(),
		self.ManaCost
	)
end

function Ability:BoltEffect(a, b)
	local segmentCount = math.floor((b - a).Magnitude / 3)
	self:GetService("EffectsService"):RequestEffectAll("ElectricSpark", {
		Start = a,
		Finish = b,
		SegmentCount = segmentCount,
		Radius = 3,
		Duration = 0.5,
		PartArgs = {
			BrickColor = BrickColor.new("Electric blue"),
			Material = Enum.Material.Neon,
		}
	})
end

function Ability:Strike(enemy, startPosition, victims, bounceNumber)
	self:GetService("DamageService"):Damage{
		Source = self.Legend,
		Target = enemy,
		Amount = self:GetDamage(),
		Type = "Electrical",
		Tags = {"Magical"},
	}
	
	local here = enemy:GetPosition()
	self:BoltEffect(startPosition, here)
	
	if bounceNumber >= self:GetBounceCount() then return end
	
	table.insert(victims, enemy)

	local targetDistancePairs = {}

	self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
		Position = here,
		Range = self.BounceRange,
		Callback = function(target, data)
			if target == enemy then return end
			if table.find(victims, target) then return end

			local pair = {
				Target = target,
				DistanceSq = data.DistanceSq,
			}
			table.insert(targetDistancePairs, pair)
		end,
	})

	if #targetDistancePairs == 0 then return end

	table.sort(targetDistancePairs, function(a, b)
		return a.DistanceSq < b.DistanceSq
	end)

	self:Strike(targetDistancePairs[1].Target, here, victims, bounceNumber + 1)
end

function Ability:OnActivatedServer()
	local manaCost = self.ManaCost

	if not self.Legend:CanUseMana(manaCost) then return false end
	self.Legend:UseMana(manaCost)

	self.Legend:AnimationPlay("MagicCast", 0)

	delay(0.1, function()
		self.Legend:SoundPlayByObject(self.Storage.Sounds.ElectricSpark)
		
		local target = nil
		self.Targeting:TargetMeleeNearest(self.Targeting:GetEnemies(), {
			Width = 6,
			Length = self.Range,
			CFrame = self.Legend:GetAimCFrame(),
			Callback = function(enemy)
				target = enemy
			end,
		})
		
		if target then
			self:Strike(target, self.Legend:GetPosition(), {}, 1)
		else
			local here = self.Legend:GetPosition()
			local there = here + self.Legend:GetAimCFrame().LookVector * self.Range
			self:BoltEffect(here, there)
		end
	end)

	self.Legend.InCombatCooldown:Use()

	return true
end

return Ability