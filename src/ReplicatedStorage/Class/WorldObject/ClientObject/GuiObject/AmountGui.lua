local Super = require(script.Parent)
local AmountGui = Super:Extend()

AmountGui.DefaultValue = 1
AmountGui.SmallStep = 1
AmountGui.LargeStep = 10

function AmountGui:OnCreated()
	self.AmountBox = self.Gui:WaitForChild("AmountBox")
	
	self.AmountBox.Text = self.DefaultValue
	self.AmountBox.FocusLost:Connect(function(...)
		self:OnAmountBoxFocusLost(...)
	end)
	
	self:ConnectDeltaButton("PlusOneButton", self.SmallStep)
	self:ConnectDeltaButton("PlusTenButton", self.LargeStep)
	self:ConnectDeltaButton("MinusOneButton", -self.SmallStep)
	self:ConnectDeltaButton("MinusTenButton", -self.LargeStep)
	
	self.Updated = self:CreateNew"Event"()
end

function AmountGui:ConnectDeltaButton(buttonName, delta)
	self.Gui:WaitForChild(buttonName).Activated:Connect(function()
		self.AmountBox.Text = self:GetValue() + delta
		self:Sanitize()
	end)
end

function AmountGui:Sanitize()
	local value = self:GetValue()
	if value == nil then
		self.AmountBox.Text = self.DefaultValue
	else
		if self.MinValue and (value < self.MinValue) then
			self.AmountBox.Text = self.MinValue
		elseif self.MaxValue and (value > self.MaxValue) then
			self.AmountBox.Text = self.MaxValue
		end
	end
	self.Updated:Fire()
end

function AmountGui:OnAmountBoxFocusLost(enterPressed, input)
	self:Sanitize()
end

function AmountGui:GetValue()
	return tonumber(self.AmountBox.Text)
end

return AmountGui