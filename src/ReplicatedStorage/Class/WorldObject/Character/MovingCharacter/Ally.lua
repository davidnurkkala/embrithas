local Super = require(script.Parent)
local Ally = Super:Extend()

Ally.Instances = {}



Ally.Level = 1

function Ally:OnCreated()
	Super.OnCreated(self)
	
	self:InitHitbox()
	self:SetUpStatusGui()
	
	table.insert(Ally.Instances, self)
end

function Ally:SetUpStatusGui()
	local statusGui = self.Storage.UI.StatusGui:Clone()
	statusGui.Adornee = self.Root
	statusGui.Parent = self.Model
	
	self.StatusGui = statusGui
end

function Ally:UpdateStatusGui()
	-- name may change when we update
	self.StatusGui.NameLabel.Text = (self.Name or self.Model.Name).." Lv."..self.Level
	
	local shieldAmount = self:GetShieldAmount()
	local totalBarAmount = math.max(self.Health + shieldAmount, self.MaxHealth:Get())

	-- update health
	local healthScalar = self.Health / totalBarAmount
	self.StatusGui.HealthFrame.Bar.Size = UDim2.new(healthScalar, 0, 1, 0)

	-- update shield
	local shieldScalar = shieldAmount / totalBarAmount
	self.StatusGui.HealthFrame.ShieldBar.Position = UDim2.new(healthScalar, 0, 0, 0)
	self.StatusGui.HealthFrame.ShieldBar.Size = UDim2.new(shieldScalar, 0, 1, 0)
end

function Ally:OnUpdated(dt)
	if self:GetPosition().Y < -100 then
		self:Deactivate()
	end
	
	self:UpdateStatusGui()
	
	Super.OnUpdated(self, dt)
end

function Ally:OnDied()
	self:SetCollisionGroup("Debris")
	
	self:SoundPlay("DeathMale")
	
	self:Ragdoll()
	delay(2, function()
		local duration = 1
		self:GetService("EffectsService"):RequestEffectAll("FadeModel", {
			Model = self.Model,
			Duration = duration
		})
		game:GetService("Debris"):AddItem(self.Model, duration)
	end)
	
	self.StatusGui:Destroy()
	
	self:Deactivate()
	
	self.Died:Fire()
end

function Ally:OnDestroyed()
	for index, enemy in pairs(Ally.Instances) do
		if enemy == self then
			table.remove(Ally.Instances, index)
			break
		end
	end
	
	for _, status in pairs(self.Statuses) do
		status:Stop()
	end
	self:UpdateStatuses(0)
	
	if self:IsAlive() then
		self.Model:Destroy()
	end
	
	if self.CustomOnDestroyed then
		self:CustomOnDestroyed()
	end
end

return Ally