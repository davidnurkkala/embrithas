local Super = require(script.Parent)
local EnemyTerrorknightSummoner = Super:Extend()

function EnemyTerrorknightSummoner:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	Super.OnCreated(self)
	
	self:AnimationPlay(self.IdleAnimation)
	
	self.Speed.Base = 10
	
	self.Cooldown = self:CreateNew"Cooldown"{Time = 12}
end

function EnemyTerrorknightSummoner:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyTerrorknightSummoner.DetectionRange = 128
EnemyTerrorknightSummoner.HoverRange = 32

EnemyTerrorknightSummoner.IdleAnimation = "TK_Idle"
EnemyTerrorknightSummoner.RunAnimation = "TK_Run"

EnemyTerrorknightSummoner.EnemyNames = {
	"Chained One",
	"Imprisoned One",
}

function EnemyTerrorknightSummoner:Summon()
	if not self.Cooldown:IsReady() then return end
	self.Cooldown:Use()
	
	self:AnimationPlay("TK_Cast")
	
	delay(1, function()
		self:SoundPlay("Hit")
		
		local cframe = self.Root.CFrame * CFrame.new(0, 0, -6)
		
		self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
			Position = cframe.Position,
			Radius = 6,
			Duration = 0.5,
			Color = Color3.new(1, 0, 0),
		})
		
		local enemyService = self:GetService("EnemyService")
		local enemy = enemyService:CreateEnemy(self:Choose(self.EnemyNames), self.Level, false){
			StartCFrame = cframe,
		}
		self:GetWorld():AddObject(enemy)
	end)
end

function EnemyTerrorknightSummoner:Flinch()
	-- don't
end

function EnemyTerrorknightSummoner:IsTargetValid()
	if not self.Target then
		return false
	end
	
	if not self:IsPointInRange(self.Target:GetPosition(), self.DetectionRange) then
		return false
	end
	
	if not self:CanSeePoint(self.Target:GetPosition()) then
		return false
	end
	
	return true
end

function EnemyTerrorknightSummoner:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if self:IsTargetValid() then
				machine:ChangeState("Hovering")
			end
			self:StuckCheck(dt)
		end,
		OnStateWillChange = function()
			self:StuckReset()
		end
	}
	
	self.StateMachine:AddState{
		Name = "Hovering",
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local here = self.Target:GetPosition()
			local there = self:GetPosition()
			local delta = (there - here) * Vector3.new(1, 0, 1)
			local position = here + (delta.Unit * self.HoverRange)
			
			self:MoveTo(position)
			self.FacingPoint = here
			
			self:Summon()
		end
	}
end

return EnemyTerrorknightSummoner