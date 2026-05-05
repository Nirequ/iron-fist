-- Creates RemoteEvents / RemoteFunctions used by Iron Fist for
-- client ↔ server communication. The server creates them all on
-- startup; clients wait for them to replicate.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteObjects = {}
local isServer = RunService:IsServer()

-- Add a name here when introducing a new remote.
local FUNCTIONS = {
	"GetStatsFunction",       -- player → server: current stats
	"BuyUpgradeFunction",     -- player → server: { upgradeId } → result
}

local EVENTS = {
	"StatsUpdated",           -- server → player: full stats refresh
	"PunchEffect",            -- server → all: { player, damage } burst
}

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")

if isServer then
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	for _, name in ipairs(FUNCTIONS) do
		local fn = Instance.new("RemoteFunction")
		fn.Name = name
		fn.Parent = remotesFolder
		RemoteObjects[name] = fn
	end

	for _, name in ipairs(EVENTS) do
		local ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = remotesFolder
		RemoteObjects[name] = ev
	end
else
	if not remotesFolder then
		remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
	end

	if remotesFolder then
		for _, name in ipairs(FUNCTIONS) do
			RemoteObjects[name] = remotesFolder:WaitForChild(name, 10)
		end
		for _, name in ipairs(EVENTS) do
			RemoteObjects[name] = remotesFolder:WaitForChild(name, 10)
		end
	else
		warn("Iron Fist client: Remotes folder did not replicate in time")
	end
end

return RemoteObjects
