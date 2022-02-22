local Super = require(script.Parent)
local TrapFallingRocks = Super:Extend()

TrapFallingRocks.Radius = 8
TrapFallingRocks.Duration = 1
TrapFallingRocks.RestDuration = 3
TrapFallingRocks.Damage = 0.75

TrapFallingRocks.Active = true

function TrapFallingRocks:OnCreated()
	self.Character = self:CreateNew"Character"{
		Model = workspace,
		Name = "falling rocks",
		Telegraphs = {},
	}
	
	delay(self.RestDuration * math.random(), function()
		self:Cycle()
	end)
end

function TrapFallingRocks:Cycle()
	if not self.Active then return end
	if (self.Room ~= nil) and (not self.Room.Dungeon.Active) then return end
	
	self:GetClass("Enemy").AttackCircle(self.Character, {
		Position = self.StartCFrame.Position,
		Radius = self.Radius,
		Duration = self.Duration,
		Interval = 0.2,
		
		OnHit = function(legend)
			self:GetService("DamageService"):Damage{
				Source = self.Character,
				Target = legend,
				Amount = legend.MaxHealth:Get() * self.Damage,
				Type = "Bludgeoning",
			}
		end,
		
		Sound = self.Storage.Sounds.RockImpact1
	})
	
	local delta = Vector3.new(0, 64, 0)
	
	local rock = Instance.new("Part")
	rock.Anchored = true
	rock.CanCollide = false
	rock.Size = Vector3.new(self:RandomFloat(2, 4), self:RandomFloat(2, 4), self:RandomFloat(2, 4))
	rock.Material = Enum.Material.Slate
	rock.Color = Color3.new(0.25, 0.25, 0.25)
	rock.CFrame = CFrame.new(self.StartCFrame.Position + delta) * CFrame.Angles(math.pi * 2 * math.random(), 0, math.pi * 2 * math.random())
	rock.Parent = workspace.Effects
	
	self:TweenNetwork{
		Object = rock,
		Goals = {CFrame = rock.CFrame - delta},
		Duration = self.Duration,
		Direction = Enum.EasingDirection.In,
	}.Completed:Connect(function()
		self:TweenNetwork{
			Object = rock,
			Goals = {Transparency = 1},
			Duration = 1,
			Style = Enum.EasingStyle.Linear,
		}.Completed:Connect(function()
			rock:Destroy()
		end)
	end)
	
	delay(self.Duration + self.RestDuration * math.random(), function()
		self:Cycle()
	end)
end

return TrapFallingRocks
