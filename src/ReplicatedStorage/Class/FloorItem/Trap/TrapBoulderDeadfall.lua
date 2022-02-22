local Super = require(script.Parent)
local TrapBomb = Super:Extend()

function TrapBomb:OnCreated()
	self.Cooldown = self:CreateNew"Cooldown"{Time = 3}
	
	local sphere = self:CreateHitSphere(3)
	sphere.Position = self.Model.__Root.Position
	sphere.Parent = self.Model
	self.Model.PrimaryPart = sphere
	
	self.Character = self:CreateNew"Character"{
		Model = self.Model,
		Name = "a falling boulder",
		Telegraphs = {},
	}
	
	local function onTouched(...) self:OnTouched(...) end
	self:SafeTouched(self.Model.PrimaryPart, onTouched)
end

function TrapBomb:OnTriggered(legend)
	if self.Room.State == "Completed" then return end
	
	if not self.Cooldown:IsReady() then return end
	self.Cooldown:Use()
	
	local position = self.Model.PrimaryPart.Position
	
	self:GetClass("Enemy").AttackCircle(self.Character, {
		Position = position,
		Radius = self.Radius,
		Duration = self.Delay,
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
	
	-- visual rock falling
	local delta = Vector3.new(0, 64, 0)
	
	local rock = Instance.new("Part")
	rock.Anchored = true
	rock.CanCollide = false
	rock.Size = Vector3.new(self:RandomFloat(2, 4), self:RandomFloat(2, 4), self:RandomFloat(2, 4))
	rock.Material = Enum.Material.Slate
	rock.Color = Color3.new(0.25, 0.25, 0.25)
	rock.CFrame = CFrame.new(position + delta) * CFrame.Angles(math.pi * 2 * math.random(), 0, math.pi * 2 * math.random())
	rock.Parent = workspace.Effects

	self:TweenNetwork{
		Object = rock,
		Goals = {CFrame = rock.CFrame - delta},
		Duration = self.Delay,
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
end

return TrapBomb
