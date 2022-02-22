local Super = require(script.Parent)
local AbilityCombatTeleport = Super:Extend()

AbilityCombatTeleport.Type = "Movement"

AbilityCombatTeleport.Distance = 16
AbilityCombatTeleport.ManaCost = 10
AbilityCombatTeleport.UsesMana = true

function AbilityCombatTeleport:OnCreated()
	Super.OnCreated(self)
end

function AbilityCombatTeleport:GetDescription()
	return string.format(
		"Immediately teleport %d feet in the direction of movement. Costs %d mana.",
		self.Distance,
		self.ManaCost
	)
end

function AbilityCombatTeleport:OnActivatedServer()
	local manaCost = self.ManaCost
	if self.Legend.Weapon and self.Legend.Weapon.Data and self.Legend.Weapon.Data.Id == 48 then
		manaCost = 0
	end
	
	if not self.Legend:CanUseMana(manaCost) then return false end
	
	local distance = self.Distance
	
	local humanoid = self.Legend.Humanoid
	local direction = humanoid.MoveDirection
	if direction:FuzzyEq(Vector3.new()) then
		return false
	end
	
	self.Legend:UseMana(manaCost)
	
	local root = self.Legend.Root
	
	local here = root.Position
	local there = root.Position + direction * distance
	local ray = Ray.new(here, there - here)
	local dungeon = workspace:FindFirstChild("Dungeon")
	local partHit, point = self:Raycast(ray, {}, function(part)
		if dungeon then
			return not part:IsDescendantOf(dungeon)
		else
			return false
		end
	end)
	if partHit then
		point = point - direction
	end
	local there = point
	local delta = there - here
	root.CFrame = root.CFrame + delta
	
	self.Legend:SoundPlayByObject(self.Storage.Sounds.CombatTeleport)
	
	self:GetService("EffectsService"):RequestEffectAll("CombatTeleport", {
		A = here,
		B = there,
	})
	
	return true
end

return AbilityCombatTeleport