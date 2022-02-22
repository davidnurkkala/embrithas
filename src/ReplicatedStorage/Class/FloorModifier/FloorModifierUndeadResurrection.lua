local Super = require(script.Parent)
local Modifier = Super:Extend()

function Modifier:OnStarted()
	local function onEnemyCreated(...)
		self:OnEnemyCreated(...)
	end
	self:AddConnection(self:GetService("EnemyService").EnemyCreated:Connect(onEnemyCreated))
end

function Modifier:IsEnemyWithinResurrectionPreventerRange(enemy)
	local rangeSq = self:GetClass("ResurrectionPreventer").Radius ^ 2
	for _, legend in pairs(self:GetClass("Legend").Instances) do
		if legend.Weapon and legend.Weapon.CarryableType == "ResurrectionPreventer" then
			local delta = legend:GetPosition() - enemy:GetPosition()
			local distanceSq = delta.X ^ 2 + delta.Z ^ 2
			if distanceSq <= rangeSq then
				return true
			end
		end
	end
	return false
end

function Modifier:OnEnemyCreated(enemy)
	enemy.Died:Connect(function()
		if self:IsEnemyWithinResurrectionPreventerRange(enemy) then return end
		
		enemy.Resurrecting = true
		
		local name = enemy.BaseName
		local level = enemy.Level
		local room = enemy.Room
		local startCFrame = enemy.StartCFrame
		local initialStartCFrame = CFrame.new(enemy:GetPosition())
		
		local effect = self.Storage.Models.UndeadResurrection:Clone()
		effect:SetPrimaryPartCFrame(initialStartCFrame)
		effect.Parent = workspace.Effects
		
		delay(self:RandomFloat(3, 6), function()
			enemy.Resurrecting = false
			
			local emitter = effect.Root.EmitterAttachment.Emitter
			emitter.Enabled = false
			game:GetService("Debris"):AddItem(effect, emitter.Lifetime.Max)
			
			local effectsService = self:GetService("EffectsService")
			effectsService:RequestEffectAll("AirBlast", {
				Position = initialStartCFrame.Position,
				Radius = 12,
				Duration = 0.5,
				Color = Color3.fromRGB(28, 9, 62),
			})
			effectsService:RequestEffectAll("Sound", {
				Position = initialStartCFrame.Position,
				Sound = self.Storage.Sounds.CastDark,
			})
			
			local enemyService = self:GetService("EnemyService")
			local newEnemy = enemyService:CreateEnemy(name, level, false){
				NoExperience = true,
				StartCFrame = initialStartCFrame,
			}
			enemyService:ApplyDifficultyToEnemy(newEnemy)
			self:GetWorld():AddObject(newEnemy)
			room:AddEnemy(newEnemy)
			
			-- ensure stuck check can still work
			newEnemy.StartCFrame = startCFrame
		end)
	end)
end

function Modifier:OnEnded()
	self:CleanConnections()
end

return Modifier