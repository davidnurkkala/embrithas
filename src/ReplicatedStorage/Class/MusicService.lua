local Super = require(script.Parent)
local MusicService = Super:Extend()

function MusicService:OnCreated()
	local sound = Instance.new("Sound")
	sound.Volume = 0
	sound.Name = "Music"
	sound.Ended:Connect(function()
		self:NextSong()
	end)
	sound.Parent = workspace
	self.Sound = sound
end

function MusicService:NextSong()
	self.PlaylistIndex = self.PlaylistIndex + 1
	if self.PlaylistIndex > #self.Playlist then
		self.PlaylistIndex = 1
	end
	self:PlayCurrentSong()
end

function MusicService:PlayCurrentSong()
	local songName = self.Playlist[self.PlaylistIndex]
	local song = self.Storage.Music.Songs:FindFirstChild(songName)
	if not song then return end
	
	self:GetService("EffectsService"):RequestEffectAll("ChatMessage", {
		Text = string.format("🎶 Now playing - %s", songName),
		Color = Color3.new(0.5, 0.5, 0.5),
		TextSize = 12,
	})
	
	self.Sound:Stop()
	self.Sound.TimePosition = 0
	self.Sound.SoundId = song.SoundId
	self.Sound:Play()
end

function MusicService:PlayPlaylist(playlistIn)
	-- create and shuffle the playlist
	local playlist = {}
	for _, songName in pairs(playlistIn) do
		table.insert(playlist, songName)
	end
	math.randomseed(tick())
	for index = 1, #playlist do
		local swap = math.random(1, #playlist)
		local temp = playlist[swap]
		playlist[swap] = playlist[index]
		playlist[index] = temp
	end
	self.Playlist = playlist
	self.PlaylistIndex = 1
	self:PlayCurrentSong()
end

local Singleton = MusicService:Create()
return Singleton