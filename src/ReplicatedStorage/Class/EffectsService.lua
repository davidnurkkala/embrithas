local Super = require(script.Parent)
local EffectsService = Super:Extend()

function EffectsService:OnCreated()
	self.EffectId = 0
end

function EffectsService:RequestEffect(player, effectName, args)
	self.EffectId = self.EffectId + 1
	
	local id = self.EffectId
	args.Id = id
	self:FireRemote("EffectRequested", player, effectName, args)
	
	return id
end

function EffectsService:RequestEffectAll(effectName, args)
	self.EffectId = self.EffectId + 1
	
	local id = self.EffectId
	args.Id = id
	self:FireRemoteAll("EffectRequested", effectName, args)
	
	return id
end

function EffectsService:CancelEffect(id)
	self:FireRemoteAll("EffectCanceled", id)
end

function EffectsService:ChangeEffect(id, args)
	self:FireRemoteAll("EffectChanged", id, args)
end

local Singleton = EffectsService:Create()
return Singleton