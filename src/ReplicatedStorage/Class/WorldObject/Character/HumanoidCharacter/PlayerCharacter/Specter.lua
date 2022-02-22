local Super = require(script.Parent)
local Specter = Super:Extend()

function Specter:OnCreated()
	Super.OnCreated(self)
	
	local levitation = Instance.new("BodyPosition")
	levitation.MaxForce = Vector3.new(0, 1e9, 0)
	levitation.Position = Vector3.new(0, 32, 0)
	levitation.Parent = self.Root
	
	self:AnimationPlay("SpecterFloating")
	
	-- ghostify
	if self.Model:FindFirstChild("Body Colors") then
		self.Model["Body Colors"]:Destroy()
	end
	
	-- have to do this a frame later because
	-- humanoids are psychotic :(
	spawn(function()
		for _, desc in pairs(self.Model:GetDescendants()) do
			if desc:IsA("MeshPart") then
				desc.TextureID = ""
			end
			
			if desc:IsA("SpecialMesh") then
				desc.TextureId = ""
			end
			
			if desc:IsA("BasePart") then
				desc.Color = Color3.new(1, 1, 1)
				desc.Transparency = math.max(desc.Transparency, 0.5)
			end
			
			if
				desc:IsA("Pants") or
				desc:IsA("Shirt") or
				desc:IsA("Decal")
			then
				desc:Destroy()
			end
		end
	end)
end

function Specter:UpdateStatus()
	local run = self:GetService("GameService").CurrentRun
	local points = run.Points
	local pointsRequired = run:GetPointsRequiredForExtraLife()
	local lives = run.LivesRemaining
	
	self:FireRemote("StatusUpdated", self.Player, {
		Health = 0,
		MaxHealth = 1,
		Points = points,
		PointsRequired = pointsRequired,
		Lives = lives,
		Mana = 0,
		MaxMana = 0,
		ManaVisible = false,
	})
end

function Specter:OnUpdated()
	self:UpdateStatus()
	
	if not self.Model.Parent then
		self:Deactivate()
	end
end

return Specter