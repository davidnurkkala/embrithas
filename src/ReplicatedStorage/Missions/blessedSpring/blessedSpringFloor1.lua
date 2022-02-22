return {
	Server = function(self)
		self:GetService("MusicService"):PlayPlaylist(require(self.Storage.Music.Playlists.GenericDungeon))
		
		-- get spawns
		local spawns = self.Model.SpawnAreas:GetChildren()
		self.Model.SpawnAreas.Parent = nil
		
		local function spawnEnemy()
			local part = spawns[math.random(1, #spawns)]
			local dx = -part.Size.X / 2 + part.Size.X * math.random()
			local dy = 6
			local start = part.CFrame:PointToWorldSpace(Vector3.new(dx, dy, part.Size.Z / 2))
			local finish = part.CFrame:PointToWorldSpace(Vector3.new(dx, dy, -part.Size.Z / 2))
			
			local enemyService = self:GetService("EnemyService")
			local enemy = enemyService:CreateEnemy(self.Run:RequestEnemy(), self.Level, false){
				StartCFrame = CFrame.new(start, finish),
			}
			enemy.DetectionRange = 512
			enemyService:ApplyDifficultyToEnemy(enemy)
			enemy:AddStatus("StatusStunned", {Time = 1})
			self:GetWorld():AddObject(enemy)
			
			self:Tween(enemy.Root, {CFrame = CFrame.new(finish, start) * CFrame.Angles(0, math.pi, 0)}, 1, Enum.EasingStyle.Linear).Completed:Connect(function()
				enemy.StartCFrame = enemy.Root.CFrame
			end)
		end
		
		local effectsService = self:GetService("EffectsService")
		
		local blessCount = 0
		local blessRequirement = 8
		local blessTime = 30
		local blessingTimeline
		
		local waterCharging = false
		local chargingFlask
		
		local function setState(state)
			self.Model.State.Value = self:EncodeJson(state)
		end
		
		setState{
			IsBlessing = false,
			BlessingRatio = 0,
			BlessCount = blessCount,
			BlessRequirement = blessRequirement,
		}
		
		local function setWaterCharging(bool)
			if waterCharging == bool then return end
			
			waterCharging = bool
			
			if bool then
				blessingTimeline = self:CreateNew"Timeline"{
					Time = blessTime,
					OnTicked = function(t)
						setState{
							IsBlessing = true,
							BlessingRatio = t:GetProgress(),
							BlessCount = blessCount,
							BlessRequirement = blessRequirement,
						}
					end,
					OnEnded = function()
						blessCount += 1
						setState{
							IsBlessing = false,
							BlessingRatio = 0,
							BlessCount = blessCount,
							BlessRequirement = blessRequirement,
						}
						blessingTimeline = nil
						
						setWaterCharging(false)
					end,
				}
				blessingTimeline:Start()
				
				chargingFlask = self.Storage.Models.BlessedWaterFlask.PrimaryPart:Clone()
				chargingFlask.CFrame = CFrame.new(self.Model.ChargeUpSpot.PrimaryPart.Position)
				chargingFlask.Parent = self.Model
			else
				if chargingFlask then
					chargingFlask:Destroy()
					chargingFlask = nil
				end
			end
		end
		
		local function doesLegendHaveWater()
			for _, legend in pairs(self:GetClass("Legend").Instances) do
				if legend.BlessedSpringWaterData then
					return true
				end
			end
			return false
		end
		
		local function alert(player, text)
			effectsService:RequestEffect(player, "TextFeedback", {
				Duration = 1,
				TextArgs = {
					Text = text,
				}
			})
		end
		
		local function onChargeUp(player)
			local legend = self:GetClass("Legend").GetLegendFromPlayer(player)
			if not legend then return end
			
			if waterCharging then
				alert(player, "Water is already being blessed.")
				return
			end
			
			local data = legend.BlessedSpringWaterData
			if not data then
				if doesLegendHaveWater() then
					alert(player, "Someone else is carrying the water.")
				else
					alert(player, "Go collect water to begin blessing it.")
				end
				return
			end
			
			data.Flask:Destroy()
			legend.BlessedSpringWaterData = nil
			
			setWaterCharging(true)
		end
		
		local function onFillUp(player)
			local legend = self:GetClass("Legend").GetLegendFromPlayer(player)
			if not legend then return end
			
			if doesLegendHaveWater() then
				if legend.BlessedSpringWaterData then
					alert(player, "Take the water to the shrine to begin blessing it.")
				else
					alert(player, "Someone is already carrying water.")
				end
				return
			end
			
			if waterCharging then
				alert(player, "Water is already being blessed.")
				return
			end
			
			local flask = self.Storage.Models.BlessedWaterFlask.PrimaryPart:Clone()
			flask.Anchored = false
			flask.CanCollide = false
			flask.Massless = true
			
			local w = Instance.new("Weld")
			w.Part0 = legend.Model.UpperTorso
			w.Part1 = flask
			w.C0 = CFrame.new(0, 0, 1) * CFrame.Angles(0, 0, math.pi / 3)
			w.Parent = flask
			
			flask.Parent = legend.Model
			
			legend.BlessedSpringWaterData = {
				Flask = flask,
			}
		end
		
		-- create the shrine
		local shrine = self:CreateNew"Ally"{
			Model = self.Model.Shrine,
			Name = "Shrine to the Distant Goddess",
			Level = self.Level,
			OnDied = function(ally)
				ally:GetService("EffectsService"):RequestEffectAll("FadeModel", {
					Model = ally.Model,
					Duration = 1,
				})
				game:GetService("Debris"):AddItem(ally.Model, 1)
				
				ally.StatusGui:Destroy()
				ally:Deactivate()
				ally.Died:Fire()
			end,
		}
		shrine.Model.Parent = workspace
		shrine.MaxHealth.Base = 5000
		shrine.Health = shrine.MaxHealth:Get()
		self:GetWorld():AddObject(shrine)
		
		-- create interactables
		local interactableService = self:GetService("InteractableService")
		interactableService:CreateInteractable{
			Model = self.Model.ChargeUpSpot,
			Radius = 12,
			Callback = function(player)
				onChargeUp(player)
			end,
		}
		interactableService:CreateInteractable{
			Model = self.Model.FillUpSpot,
			Radius = 12,
			Callback = function(player)
				onFillUp(player)
			end,
		}
		
		-- start the dungeon up
		delay(5, function()
			repeat wait() until doesLegendHaveWater()
			
			self:GetService("EffectsService"):RequestEffectAll("Dialogue", {
				Name = "Drillmaster Leon",
				Image = "rbxassetid://5617833593",
				Text = "Gather your wits, slayers! Monsters are here. Protect the shrine and let's finish this!",
			})
			
			self:Start()
			
			while (shrine.Active) and (blessCount < blessRequirement) do
				for _ = 1, #game.Players:GetPlayers() do
					spawnEnemy()
				end
				
				wait(3)
			end
			
			if not shrine.Active then
				if blessingTimeline then
					blessingTimeline.OnEnded = nil
					blessingTimeline:Stop()
					blessingTimeline = nil
				end

				self:GetRun():Defeat()
				
			elseif blessCount >= blessRequirement then
				shrine:Deactivate()
				
				self.Completed:Fire()
			end
		end)
	end,
	
	Client = function(self, model)
		local player = game:GetService("Players").LocalPlayer
		
		local inset = game:GetService("GuiService"):GetGuiInset()
		
		local gui = script.BlessedSpringFrame:Clone()
		gui.Position -= UDim2.new(0, 0, 0, inset.Y - 4)
		gui.Parent = player:WaitForChild("PlayerGui"):WaitForChild("Gui")
		
		local stateValue = model:WaitForChild("State")
		
		local function update(state)
			gui.BarFrame.Visible = state.IsBlessing or false
			gui.BarFrame.Bar.Size = UDim2.new(state.BlessingRatio or 0, 0, 1, 0)
			
			gui.Text.Text = string.format("Flasks Blessed: %d / %d", state.BlessCount or 0, state.BlessRequirement or 0)
		end
		
		local function onChanged()
			if stateValue.Value == "" then
				update{}
			else
				update(self:DecodeJson(stateValue.Value))
			end
		end
		
		stateValue.Changed:connect(onChanged)
		onChanged()
		
		model.AncestryChanged:Connect(function()
			if not model:IsDescendantOf(workspace) then
				gui:Destroy()
			end
		end)
	end,
}