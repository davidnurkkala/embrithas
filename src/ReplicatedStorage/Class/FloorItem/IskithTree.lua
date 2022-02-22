local Super = require(script.Parent)
local IskithTree = Super:Extend()

local TweenService = game:GetService("TweenService")

IskithTree.ManaRange = 64
IskithTree.ManaRestored = 0.1

IskithTree.CanBeCompleted = true
IskithTree.IsCompleted = false

function IskithTree:OnCreated()
	self.Active = true
	
	self.Model = self.Storage.Models.IskithTree:Clone()
	self.Model:SetPrimaryPartCFrame(self.StartCFrame)
	self.Model.Parent = self.StartParent
	
	self.Completed = self:CreateNew"Event"()
	
	local function onTouched(...) self:OnTouched(...) end
	self:SafeTouched(self.Model.Collider, onTouched)
end

function IskithTree:OnTouched(part)
	if not self.Active then return end
	
	local legend = self:GetClass"Legend".GetLegendFromPart(part)
	if not legend then return end
	
	self.Active = false
	
	local theta = math.pi * 2 * math.random()
	local radius = 5.5
	local dx = math.cos(theta) * radius
	local dz = math.sin(theta) * radius
	local there = self.StartCFrame.Position
	local here = there + Vector3.new(dx, 0, dz)
	local cframe = CFrame.new(here, there) * CFrame.new(1, 0, 0) + Vector3.new(0, 64, 0)
	
	local model = self.Storage.Models.LumberjackKnight:Clone()
	model:SetPrimaryPartCFrame(cframe)
	model.Parent = workspace
	
	local ally = self:CreateNew"Ally"{
		Model = model,
		Name = "Slayer Alliance Woodcutter",
	}
	local level = self.Room.Dungeon.Level + (self:GetRun():GetDifficultyData().LevelDelta or 0)
	local health = self:GetClass("Legend").GetMaxHealthFromLevel(level) * 10
	ally.MaxHealth.Base = health
	ally.Health = ally.MaxHealth:Get()
	self:GetWorld():AddObject(ally)
	
	ally:AnimationPlay("BigOrcJump")
	delay(5/6, function()
		self:TweenNetwork{
			Object = model.PrimaryPart,
			Goals = {CFrame = cframe + Vector3.new(0, -60, 0)},
			Duration = 1/6,
			Style = Enum.EasingStyle.Quint,
			Direction = Enum.EasingDirection.Out,
		}
		wait(1/6)
		ally:AnimationPlay("WoodcutterChop")
	end)
	
	local EffectsService = self:GetService("EffectsService")
	
	EffectsService:RequestEffectAll("Dialogue", {
		Name = "Slayer Alliance Woodcutter",
		Image = "rbxassetid://5651417472",
		Text = "All right, slayers. Keep the undead off me while I cut down this tree.",
	})
	
	local radius = 64
	local duration = 60
	local enemyCount = 10 + (15 * #game:GetService("Players"):GetPlayers())
	local pauseTime = duration / enemyCount
	
	local function spawnEnemy()
		local theta = math.pi * 2 * math.random()
		local dx = math.cos(theta) * radius
		local dz = math.sin(theta) * radius
		
		local enemy = self:GetService("EnemyService"):CreateEnemy(self:GetRun():RequestEnemy(), self.Room.Dungeon.Level){
			StartCFrame = self.StartCFrame + Vector3.new(dx, 4, dz)
		}
		self:GetWorld():AddObject(enemy)
		self.Room:AddEnemy(enemy)
	end
	
	for _ = 1, enemyCount do
		wait(pauseTime)
		if not ally.Active then
			break
		end
		spawnEnemy()
	end
	
	if ally.Active then
		local root = self.Model.Root
		self:TweenNetwork{
			Object = root,
			Goals = {CFrame = root.CFrame * CFrame.Angles(0, 0, math.pi / 2)},
			Duration = 4,
			Style = Enum.EasingStyle.Bounce,
			Direction = Enum.EasingDirection.Out,
		}.Completed:Connect(function()
			EffectsService:RequestEffectAll("FadeModel", {
				Model = self.Model,
				Duration = 1,
			})
			wait(1)
			self.Model:Destroy()
		end)
		EffectsService:RequestEffectAll("Dialogue", {
			Name = "Slayer Alliance Woodcutter",
			Image = "rbxassetid://5651417472",
			Text = "Great work, slayers. Call me again when you need me.",
		})
		
		local min = 5
		local max = 10
		max = math.max(5, math.floor(max * self:GetRun():GetDifficultyData().LootChance or 1))
		local amount = math.random(min, max)
		
		for _, player in pairs(game:GetService("Players"):GetPlayers()) do
			self:GetService("InventoryService"):AddItem(player, "Materials", {Id = 6, Amount = amount})
		end
		
		ally:AnimationPlay("BigOrcJump")
		delay(0.5, function()
			self:TweenNetwork{
				Object = model.PrimaryPart,
				Goals = {CFrame = model.PrimaryPart.CFrame + Vector3.new(0, 60, 0)},
				Duration = 0.5,
				Style = Enum.EasingStyle.Quint,
				Direction = Enum.EasingDirection.Out,
			}
			wait(0.5)
			ally:Deactivate()
		end)
		
		self.IsCompleted = true
		self.Completed:Fire()
	else
		self:GetRun():Defeat()
	end
end

return IskithTree