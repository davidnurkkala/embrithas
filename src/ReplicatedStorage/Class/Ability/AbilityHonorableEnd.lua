local Super = require(script.Parent)
local Ability = Super:Extend()

Ability.Type = "Utility"

function Ability:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 69
end

function Ability:GetDescription(level)
	return "Requires a longsword to use. Immediately plunge your own blade into your chest."
end

function Ability:IsLobby()
	return self:GetService("GameService").IsLobby
end

function Ability:OnActivatedServer()
	if not self.Legend.Weapon:IsA(self:GetClass("WeaponLongsword")) then return end
	
	self.Legend:AnimationPlay("LongswordHonor")
	
	delay(1, function()
		self.Legend.Weapon:HitEffects(self.Legend)
		
		if self:IsLobby() then
			self.Legend.Health = 1
		else
			self.Legend.Health = 0
		end
	end)
	
	self.Legend.InCombatCooldown:Use()
	return true
end

return Ability