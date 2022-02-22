local Players = game:GetService("Players")

local Super = require(script.Parent)
local Party = Super:Extend()

function Party:OnCreated()
	self.Members = {}
	self.Invited = {}
	self.Difficulty = "Rookie"
	self.IsPublic = false
	
	if self.Mission.Cost then
		self:AddCost(self.Mission.Cost)
	end
end

function Party:GetPlayers()
	local lobbyService = self:GetService("LobbyService")
	
	local players = {}
	for _, player in pairs(Players:GetPlayers()) do
		local inMembers = table.find(self.Members, player) ~= nil
		local inInvited = table.find(self.Invited, player) ~= nil
		if not (inMembers or inInvited) then
			table.insert(players, {
				Player = player,
				Qualified = (#lobbyService:GetUnmetRequirements(player, self.Mission) == 0),
				CanInvite = (lobbyService:CanPlayerInvite(self:GetLeader(), player)),
			})
		end
	end
	table.sort(players, function(a, b)
		if a.Qualified == b.Qualified then
			return a.Player.Name < b.Player.Name
		else
			return a.Qualified
		end
	end)
	return players
end

function Party:AddMember(player)
	if table.find(self.Members, player) ~= nil then
		return false
	end
	
	table.insert(self.Members, player)
	return true
end

function Party:RemoveMember(player)
	local index = table.find(self.Members, player)
	if index then
		local member = table.remove(self.Members, index)
		self:RemoveMemberContribution(member)
		return true
	else
		return false
	end
end

function Party:HasMember(player)
	return table.find(self.Members, player) ~= nil
end

function Party:IsInvited(player)
	return table.find(self.Invited, player) ~= nil
end

function Party:Uninvite(player)
	local index = table.find(self.Invited, player)
	if index then
		table.remove(self.Invited, index)
		return true
	else
		return false
	end
end

function Party:Invite(player)
	if self:IsInvited(player) then
		return false
	end
	
	table.insert(self.Invited, player)
	
	return true
end

function Party:IsEmpty()
	return #self.Members == 0
end

function Party:GetLeader()
	return self.Members[1]
end

function Party:AddCost(cost)
	self.Cost = cost
	self.ContributionsByMember = {}
end

function Party:RemoveMemberContribution(member)
	if not self.ContributionsByMember then return end
	self.ContributionsByMember[member] = nil
end

function Party:AddMemberContribution(member, newContribution)
	if not self.ContributionsByMember then return end
	
	local contribution = self.ContributionsByMember[member] 
	if not contribution then
		contribution = {}
		self.ContributionsByMember[member] = contribution
	end
	
	for key, val in pairs(newContribution) do
		if key == "Gold" then
			contribution.Gold = (contribution.Gold or 0) + val
		end
	end
end

function Party:GetInfo()
	local members = {}
	for _, member in pairs(self.Members) do
		table.insert(members, member)
	end
	
	local invited = {}
	for _, player in pairs(self.Invited) do
		table.insert(invited, player)
	end
	
	local data = {
		Members = members,
		Invited = invited,
		Players = self:GetPlayers(),
		MissionModule = self.MissionModule,
		Difficulty = self.Difficulty,
		IsPublic = self.IsPublic,
	}
	
	if self.Cost then
		data.Cost = self.Cost
		
		-- can't pass instance references as keys in tables
		local cbm = {}
		for member, contribution in pairs(self.ContributionsByMember) do
			cbm[member.UserId] = contribution
		end
		data.ContributionsByMember = cbm
	end
	
	return data
end

function Party:Replicate()
	if self.Embarking then return end
	
	local info = self:GetInfo()
	for _, member in pairs(self.Members) do
		self:FireRemote("PartyUpdated", member, "Changed", info)
	end
	
	self:GetService("LobbyService"):OnPartyReplicated()
end

return Party