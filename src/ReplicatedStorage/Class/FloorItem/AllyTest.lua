local Super = require(script.Parent)
local AllyTest = Super:Extend()

local TweenService = game:GetService("TweenService")

function AllyTest:OnCreated()
	local model = self.Storage.Models.LumberjackKnight:Clone()
	model:SetPrimaryPartCFrame(self.StartCFrame + Vector3.new(0, 4, 0))
	model.Parent = workspace
	model.AnimationController:LoadAnimation(model.Chop):Play()
	local ally = self:CreateNew"Ally"{
		Name = "Slayer Alliance Woodcutter",
		Model = model,
	}
	ally.MaxHealth.Base = 1000
	ally.Health = ally.MaxHealth:Get()
	self:GetWorld():AddObject(ally)
	
	local tree = self.Storage.Models.IskithPlankTree:Clone()
	tree:SetPrimaryPartCFrame(self.StartCFrame * CFrame.new(-1, 0, -5.5))
	tree.Parent = self.Room.Dungeon.Model
end

return AllyTest