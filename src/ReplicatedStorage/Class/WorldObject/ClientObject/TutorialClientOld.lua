local Super = require(script.Parent)
local TutorialClient = Super:Extend()

local Player = game:GetService("Players").LocalPlayer

function TutorialClient:OnCreated()
	self:ConnectRemote("TutorialUpdated", self.OnTutorialUpdated, false)
end

function TutorialClient:Dialogue(text, args)
	args = args or {}
	for key, val in pairs{
		Name = "Drillmaster Leon",
		Image = "rbxassetid://5617833593",
		Text = text,
	} do
		args[key] = val
	end
	
	local EffectsClient = self:GetService("EffectsClient")
	return EffectsClient:EffectDialogue(args)
end

function TutorialClient:HideArrow()
	if self.ArrowGui then
		self.ArrowGui:Destroy()
		self.ArrowGui = nil
	end
end

function TutorialClient:ShowArrow(position, rotation)
	self:HideArrow()
	
	local arrow = self.Storage.UI.ArrowFrame:Clone()
	local sg = Instance.new("ScreenGui")
	arrow.Position = UDim2.new(0, position.X, 0, position.Y)
	arrow.Rotation = rotation
	arrow.Parent = sg
	sg.Parent = Player.PlayerGui
	
	spawn(function()
		while sg.Parent do
			local a = Vector3.new(0.5, 0.5, 0.5)
			local b = Vector3.new(1, 1, 1)
			local t = (math.sin(tick() * 8) + 1) / 2
			local c = self:Lerp(a, b, t)
			arrow.Image.ImageColor3 = Color3.new(c.X, c.Y, c.Z)
			wait()
		end
	end)
	
	self.ArrowGui = sg
end

function TutorialClient:OnTutorialUpdated(step)
	local Gui = Player.PlayerGui:WaitForChild("Gui")
	
	if step == 1 then
		local inventoryClient = self:GetService("InventoryClient")
		
		self:Dialogue("Welcome to the Course, recruit! Here you'll learn the basics of fighting monsters. Maybe one day you'll be a bonafide Slayer like me, eh?")
		self.D = self:Dialogue("First let's start by figuring out how to work with your gear. Open your inventory by clicking or tapping this button.", {ManualTiming = true})
		self:ShowArrow(Gui.InventoryButton.AbsolutePosition)
		inventoryClient.Toggled:Wait()
		self.D:End()
		self.D = self:Dialogue("Great. This is your inventory. Notice the three tabs at the top: Weapons, Abilities, and Materials. Click on Abilities to see your abilities.", {ManualTiming = true})
		self:ShowArrow(Gui.InventoryFrame.TabsFrame.AbilitiesButton.AbsolutePosition)
		inventoryClient.TabSelected:WaitFor("Abilities")
		self.D:End()
		self.D = self:Dialogue("The most basic ability even recruits like you know is how to roll out of danger. Go ahead and select your Combat Roll ability.", {ManualTiming = true})
		self:ShowArrow(Gui.InventoryFrame.ContentFrame:FindFirstChildOfClass("ImageButton").AbsolutePosition)
		inventoryClient.ItemSelected:Wait()
		self.D:End()
		self.D = self:Dialogue("Now you can see the details of this ability as well as equip it. Equip it now by clicking or tapping this button.", {ManualTiming = true})
		self:ShowArrow(Gui.InventoryFrame.DetailsFrame.ButtonsFrame.EquipButton.AbsolutePosition)
		if #inventoryClient.Inventory.EquippedAbilityIndices == 0 then
			inventoryClient.ItemEquipped:Wait()
		end
		self.D:End()
		self:HideArrow()
		self.D = self:Dialogue("Great, now your Combat Roll ability is equipped. Use it, either by pressing the spacebar on PC or tapping the \"Ability\" button on a mobile device. Combat Roll will move you quickly in the direction you're moving, so you must be moving to use it.", {ManualTiming = true})
		self:FireRemote("TutorialUpdated", 1)
	
	elseif step == 1.1 then
		self.D:End()
		self.D = self:Dialogue("Once you've gotten the hang of using Combat Roll, go ahead and kick down the door leading to the next room. To do this, simply walk up to it. Don't worry -- we order them by the dozen.", {ManualTiming = true})
		self:FireRemote("TutorialUpdated", 1.1)
	
	elseif step == 2 then
		self.D:End()
		self.D = self:Dialogue("Next you need to learn how to attack. Here are a few training dummies. To attack them, simply walk up close to them. You'll start hitting them automatically.", {ManualTiming = true})
	
	elseif step == 3 then
		self.D:End()
		self.D = self:Dialogue("Great job dealing with those inanimate blocks of wood! Now you'll need to learn how to avoid danger.")
		self.D.Ended:Connect(function()
			self:FireRemote("TutorialUpdated", 3)
		end)
	elseif step == 3.1 then
		self:Dialogue("What you're seeing right now is a danger zone. If you're inside of a danger zone when it closes, you'll take damage and potentially die. Nobody wants that.")
		self.D = self:Dialogue("Now I'm going to send some more danger zones. Try to dodge them. Using your Combat Roll ability can help, but it isn't necessary. When you dodge three in a row, you can move on.")
		self.D.Ended:Connect(function()
			self:FireRemote("TutorialUpdated", 3.1)
		end)
	elseif step == 3.2 then
		self:Dialogue("Try again. When you dodge three in a row, you can move on.")
		
	elseif step == 4 then
		self:Dialogue("Next you need to know one of the most important responsibilities of a slayer: cleansing corruption. Near monsters, purple crystals called corruption crystals grow.")
		self:Dialogue("To cleanse a corruption crystal, simply step on it. It will shatter and help earn extra lives for you and your team. If you're using magic, it will also give you some mana.")
		self.D = self:Dialogue("We've carefully transplanted some corruption crystals for you to cleanse. Head through the door and get to work!")
		self.D.Ended:Connect(function()
			self:FireRemote("TutorialUpdated", 4.1)
		end)
		
	elseif step == 5 then
		self:Dialogue("All right, time to put everything you've learned together. You're going to fight a real monster. Don't worry, I know you can do it. Head on through to the next room.")
	
	elseif step == 6 then
		self:Dialogue("Congratulations, recruit -- or should I say rookie? Yes, you're now officially a rookie Slayer. Kick down that last door and let's get you on a mission.")
	end
end

local Singleton = TutorialClient:Create()
return Singleton