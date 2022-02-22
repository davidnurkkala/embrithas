local Super = require(script.Parent)
local DamageIndicatorClient = Super:Extend()

DamageIndicatorClient.IndicatorDuration = 2
DamageIndicatorClient.IndicatorHeight = 4
DamageIndicatorClient.IndicatorSpeed = 8

DamageIndicatorClient.IconsByDamageType = {
	Slashing = "rbxassetid://6516246705",
	Piercing = "rbxassetid://6516246891",
	Bludgeoning = "rbxassetid://6516247221",
	Heat = "rbxassetid://6529053587",
	Cold = "rbxassetid://6516247149",
	Internal = "rbxassetid://6516246950",
	Disintegration = "rbxassetid://6516247075",
	Psychic = "rbxassetid://6516246808",
	Electrical = "rbxassetid://7039086490",
}

function DamageIndicatorClient:OnCreated()
	self.Player = game:GetService("Players").LocalPlayer
	
	self.IndicatorTablesByTarget = {}
	
	self:GetWorld():AddObject(self)
	
	self:ConnectRemote("DamageIndicatorRequested", self.OnDamageIndicatorRequested, false)
end

function DamageIndicatorClient:IsSourceMe(source)
	return source.Parent == self.Player.Character
end

function DamageIndicatorClient:IsSourcePlayer(source)
	return game:GetService("Players"):GetPlayerFromCharacter(source.Parent) ~= nil
end

function DamageIndicatorClient:FindIndicator(indicatorTable, source, damageType)
	for index, indicator in pairs(indicatorTable) do
		if indicator.Active and indicator.Source == source and indicator.DamageType == damageType then
			return indicator
		end
	end
	return nil
end

function DamageIndicatorClient:OnDamageIndicatorRequested(indicatorData)
	if not indicatorData.Source then return end
	if not indicatorData.Target then return end
	if not indicatorData.Amount then return end
	if not indicatorData.Type then return end
	if not indicatorData.ResistanceStatus then return end
	
	if not self.IndicatorTablesByTarget[indicatorData.Target] then
		self.IndicatorTablesByTarget[indicatorData.Target] = {}
	end
	
	local indicatorTable = self.IndicatorTablesByTarget[indicatorData.Target]
	local indicator = self:FindIndicator(indicatorTable, indicatorData.Source, indicatorData.Type)
	
	if not indicator then
		local count = 0
		for _, indicator in pairs(indicatorTable) do
			count = count + 1
		end
		
		local billboard = self.Storage:WaitForChild("UI"):WaitForChild("DamageIndicatorGui"):Clone()
		billboard.Adornee = indicatorData.Target
		billboard.Parent = self.Player.PlayerGui.Gui
		
		local source = indicatorData.Source
		local damageType = indicatorData.Type
		
		indicator = {
			Active = true,
			Position = count,
			Height = 0,
			Duration = self.IndicatorDuration,
			Amount = 0,
			Billboard = billboard,
			Transparency = 0,
			Source = source,
			DamageType = damageType
		}
		
		if self:IsSourcePlayer(source) then
			if self:IsSourceMe(source) then
				if indicatorData.ResistanceStatus == "Weak" then
					billboard.AmountLabel.TextColor3 = Color3.new(1, 1, 0.3)

				elseif indicatorData.ResistanceStatus == "Resistant" then
					billboard.AmountLabel.TextColor3 = Color3.new(0.3, 0.3, 0.3)
				end
			else
				billboard.AmountLabel.TextColor3 = Color3.new(0.6, 0.6, 0.6)
			end
		else
			billboard.AmountLabel.TextColor3 = Color3.new(0.8, 0.4, 0.4)
		end
		
		billboard.Icon.Image = self.IconsByDamageType[damageType]
		billboard.Icon.ImageColor3 = billboard.AmountLabel.TextColor3
		
		table.insert(indicatorTable, indicator)
	end
	
	indicator.Duration = self.IndicatorDuration
	indicator.Amount = indicator.Amount + indicatorData.Amount
	indicator.Billboard.AmountLabel.Text = math.floor(indicator.Amount)
end

function DamageIndicatorClient:CheckTargetIndicatorTable(target)
	local indicatorTable = self.IndicatorTablesByTarget[target]
	if not indicatorTable then return end
	if #indicatorTable > 0 then return end
	
	self.IndicatorTablesByTarget[target] = nil
end

function DamageIndicatorClient:OnUpdated(dt)
	for target, indicatorTable in pairs(self.IndicatorTablesByTarget) do
		for index = #indicatorTable, 1, -1 do
			local indicator = indicatorTable[index]
			indicator.Duration = indicator.Duration - dt
			
			if indicator.Duration <= 0 then
				if indicator.Active then
					indicator.Active = false
				else
					indicator.Transparency = indicator.Transparency + 10 * dt
					
					local label = indicator.Billboard.AmountLabel
					label.TextTransparency = indicator.Transparency
					label.TextStrokeTransparency = indicator.Transparency
					
					if indicator.Transparency >= 1 then
						indicator.Billboard:Destroy()
						table.remove(indicatorTable, index)
						self:CheckTargetIndicatorTable(target)
					end
				end
			end
			
			-- height relative to other indicators
			local desiredPosition = index
			local delta = desiredPosition - indicator.Position
			local direction = math.sign(delta)
			local traversed = self.IndicatorSpeed * dt
			if traversed >= math.abs(delta) then
				indicator.Position = desiredPosition
			else
				indicator.Position = indicator.Position + (direction * traversed)
			end
			
			-- height relative to source
			indicator.Height = math.min(indicator.Height + dt * self.IndicatorSpeed, self.IndicatorHeight)
			indicator.Billboard.StudsOffsetWorldSpace = Vector3.new(0, indicator.Height, 0)
			indicator.Billboard.StudsOffset = Vector3.new(0, indicator.Position, 0)
		end
	end
end

local Singleton = DamageIndicatorClient:Create()
return Singleton