game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DebugMessaged").OnClientEvent:Connect(function(message)
	print(message)
end)