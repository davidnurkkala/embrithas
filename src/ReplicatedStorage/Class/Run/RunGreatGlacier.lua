local Super = require(script.Parent)
local Run = Super:Extend()

Run.Enemies = {"Skeleton", "Skeleton Warrior", "Bone Archer"}

function Run:SetCurrentHeatSource(source)
	self.HeatSource = source
end

function Run:OnCreated()
	Super.OnCreated(self)
	
	self.Character = self:CreateNew"Character"{
		Model = workspace,
		Name = "the bone-chilling cold of the Great Glacier",
		Telegraphs = {},
	}
	
	spawn(function()
		while self.Active do
			self:OnUpdated(wait(0.1))
		end
	end)
end

function Run:NewDungeon()
	if self.Floor == 1 then
		Super.NewDungeon(self)
		
	elseif self.Floor == 2 then
		math.randomseed(tick())
		
		local size = Vector2.new(3, 5)
		
		self.Dungeon = self:CreateNew"DungeonGranular"{
			Run = self,
			Level = self.RunData.Level + self.Floor,
			Theme = "Glacier",
			SizeInChunks = size,
			ChestsEnabled = true,
			
			CustomGenerateRooms = function(dungeon)
				local chunkPosition = Vector2.new(1, 1)
				
				dungeon:ResetChunk(chunkPosition)
				
				local chunkSize = dungeon.ChunkSize - dungeon.ChunkPadding
				local roomSize = self:MapVector2(chunkSize / 2, math.floor)
				local roomPosition = self:MapVector2(chunkSize / 2 - roomSize / 2, math.floor)
				
				local pattern, size, position = dungeon.ThemeMachine:CreateCircularRoom(roomSize.X, chunkPosition * dungeon.ChunkSize + roomPosition)
				
				-- mining camp in the center
				local center = self:MapVector2(roomSize / 2, math.floor)
				pattern[center.X][center.Y].FloorItems = {
					{
						Type = "Decoration",
						Model = self.Storage.Models.EvrigTorchShrine:Clone(),
						Offset = CFrame.Angles(0, 0, -math.pi / 2),
					},
					"EvrigTorch",
				}
				
				-- no other features in this room
				for x, row in pairs(pattern) do
					for y, cell in pairs(row) do
						cell.NoFeatures = true
						
						local delta = Vector2.new(x, y) - center
						local d = math.max(math.abs(delta.X), math.abs(delta.Y))
						if d < 2 or d > 4 then
							cell.Occupied = true
						end
					end
				end
				
				dungeon:ApplyPattern(pattern, size, position)
				dungeon.StartRoomChunkPosition = chunkPosition
			end
		}
		
		self:StartDungeon()
	end
end

function Run:CheckHeatSource(dt)
	if not self.HeatSource then return end
	if self.Floor ~= 2 then return end
	
	local position = Vector3.new()
	if self.HeatSource:IsA(self:GetClass("Legend")) then
		position = self.HeatSource:GetPosition()
	elseif self.HeatSource:IsA(self:GetClass("EvrigTorch")) then
		position = self.HeatSource.Model:GetPrimaryPartCFrame().Position
	end
	
	local radius = self:GetClass("WeaponTorch").Radius
	
	for _, legend in pairs(self:GetClass("Legend").Instances) do
		local delta = legend:GetPosition() - position
		local distance = math.sqrt(delta.X ^ 2 + delta.Z ^ 2)
		if distance >= radius then
			legend.RunGreatGlacierChill = (legend.RunGreatGlacierChill or 0) + dt
			
			if legend.RunGreatGlacierChill > 1 then
				self:GetService("DamageService"):Damage{
					Source = self.Character,
					Target = legend,
					Amount = legend.MaxHealth:Get() * 0.25 * dt,
					Unblockable = true,
					Type = "Cold",
				}
			end
		else
			legend.RunGreatGlacierChill = nil
		end
	end
end

function Run:OnUpdated(dt)
	self:CheckHeatSource(dt)
end

function Run:CheckForVictory()
	return self.Floor > 2
end

function Run:RequestEnemy()
	return self.Enemies[math.random(1, #self.Enemies)]
end

return Run