local Super = require(script.Parent)
local IronOreRock = Super:Extend()

function IronOreRock:OnCreated()
	self.Active = true
			
	self.Model = self.Storage.Models.IronOreRock:Clone()
	self.Model:SetPrimaryPartCFrame(self.StartCFrame * CFrame.new(0, 2.5, 0) * CFrame.Angles(0, math.pi * 2 * math.random(), 0))
	
	self.Model.Parent = self.StartParent
	
	self.InteractableId = self:GetService("InteractableService"):CreateInteractable{
		Model = self.Model,
		Radius = 8,
		Callback = function(player)
			self:OnActivated(player)
		end,
	}
	
	self.Character = self:CreateNew"Character"{
		Model = workspace,
		Name = "a jolt of lightning",
		Telegraphs = {},
	}
end

function IronOreRock:LightningStrike(position)
	local radius = 8
	local radiusSq = radius ^ 2
	local pause = 0.9
	
	self:GetService("EffectsService"):RequestEffectAll("TelegraphCircle", {
		Position = position,
		Radius = radius,
		Duration = pause,
	})
	
	delay(pause, function()
		local targets = self:GetService("TargetingService"):GetMortals()
		for _, target in pairs(targets) do
			if target:DistanceToSquared(position) < radiusSq then
				self:GetService("DamageService"):Damage{
					Source = self.Character,
					Target = target,
					Amount = target.MaxHealth:Get() * 0.5,
					Type = "Electrical",
				}
			end
		end
		
		self:GetService("EffectsService"):RequestEffectAll("Thunderstrike", {
			Position = position,
		})
	end)
end

function IronOreRock:OnActivated(player)
	if not self.Active then return end
	
	local legend = self:GetClass("Legend").GetLegendFromPlayer(player)
	if not legend then return end
	
	if legend.IronOreRockCarrying then return end
	
	legend.IronOreRockCarrying = true
	
	spawn(function()
		while legend.Active and legend.IronOreRockCarrying do
			local position = legend:GetFootPosition() + legend:GetFlatVelocity()
			
			local r = 8
			local dx = math.random(-r, r)
			local dz = math.random(-r, r)
			
			self:LightningStrike(position + Vector3.new(dx, 0, dz))
			
			wait(self:RandomFloat(0.5, 2))
		end
	end)
	
	-- give iron
	local sack = self.Storage.Models.Sack:Clone()
	
	local w = Instance.new("Weld")
	w.Part0 = legend.Model.UpperTorso
	w.Part1 = sack
	w.C0 = CFrame.new(0, 0, 1.5)
	w.Parent = sack
	
	sack.Parent = legend.Model
	
	self.Active = false
	self:Disappear()
end

function IronOreRock:Disappear()
	self:GetService("InteractableService"):DestroyInteractable(self.InteractableId)
	
	self.Model.Iron:Destroy()
	
	delay(1, function()
		self:GetService("EffectsService"):RequestEffectAll("FadeModel", {
			Model = self.Model,
			Duration = 1,
		})
		game:GetService("Debris"):AddItem(self.Model, 1)
	end)
end

return IronOreRock