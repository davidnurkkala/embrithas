local Super = require(script.Parent)
local CorruptionCrystal = Super:Extend()

local TweenService = game:GetService("TweenService")

CorruptionCrystal.ManaRange = 64
CorruptionCrystal.ManaRestored = 0.1

function CorruptionCrystal:OnCreated()
	self.Active = true
	
	self.Model = self.Storage.Models.CorruptionCrystal:Clone()
	self.Model:SetPrimaryPartCFrame(self.StartCFrame)
	
	local sphere = self:CreateHitSphere(3)
	sphere.CFrame = self.StartCFrame
	sphere.Parent = self.Model
	
	self.Model.Parent = self.StartParent
	
	local function onTouched(...) self:OnTouched(...) end
	self:SafeTouched(sphere, onTouched)
end

function CorruptionCrystal:OnTouched(part)
	if not self.Active then return end
	
	local legend = self:GetClass"Legend".GetLegendFromPart(part)
	if not legend then return end
	
	local run = self:GetService("GameService").CurrentRun
	local points = 10
	run:AddPoints(points)
	self:GetService("LogService"):AddEvent{Type = "pointsAcquired", Player = legend.Player, Amount = points}
	
	for _, legend in pairs(self:GetClass"Legend".Instances) do
		if legend:IsPointInRange(self.StartCFrame.Position, self.ManaRange) then
			legend.Mana = math.min(legend.MaxMana:Get(), legend.Mana + self.ManaRestored * legend.MaxMana:Get())
			self:GetService("EffectsService"):RequestEffectAll("CorruptionMana", {
				Duration = 0.5,
				StartCFrame = self.StartCFrame,
				Root = legend.Root,
			})
		end
	end
	
	self.Active = false
	self:Disappear()
end

function CorruptionCrystal:Disappear()
	local part = self.Model.PrimaryPart
	local light = part.Light
	
	local duration = 1
	local tweenInfo = TweenInfo.new(duration)
	TweenService:Create(part, tweenInfo, {Transparency = 1}):Play()
	TweenService:Create(light, tweenInfo, {Range = 0, Brightness = 0}):Play()
	
	part.Shatter:Play()
	
	part.Emitter.Enabled = true
	delay(duration, function()
		part.Emitter.Enabled = false
	end)
	
	game:GetService("Debris"):AddItem(self.Model, duration + part.Emitter.Lifetime.Max)
end

return CorruptionCrystal