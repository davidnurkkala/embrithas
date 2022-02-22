local Super = require(script.Parent)
local AnimationClient = Super:Extend()

function AnimationClient:OnCreated()
	self:RecordAllAnimations()
	
	local function onDescendantAdded(...)
		self:OnDescendantAdded(...)
	end
	workspace.DescendantAdded:Connect(onDescendantAdded)
	for _, descendant in pairs(workspace:GetDescendants()) do
		onDescendantAdded(descendant)
	end
end

function AnimationClient:RecordAllAnimations()
	self.AnimationsById = {}
	
	local function onDescendantAdded(desc)
		if desc:IsA("Animation") then
			self.AnimationsById[desc.AnimationId] = desc
		end
	end
	self.Storage:WaitForChild("Animations").DescendantAdded:Connect(onDescendantAdded)
	for _, desc in pairs(self.Storage.Animations:GetDescendants()) do
		onDescendantAdded(desc)
	end
end

function AnimationClient:OnDescendantAdded(descendant)
	if not (descendant:IsA("Humanoid") or descendant:IsA("AnimationController")) then return end
	
	descendant.AnimationPlayed:Connect(function(track)
		local animation = self.AnimationsById[track.Animation.AnimationId]
		if not animation then return end
		
		local animationScript = animation:FindFirstChild("AnimationScript")
		if not animationScript then return end
		
		pcall(function()
			require(animationScript)(track, descendant)
		end)
	end) 
end

local Singleton = AnimationClient:Create()
return Singleton