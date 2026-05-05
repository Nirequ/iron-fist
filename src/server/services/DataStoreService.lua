-- Persists per-player stats (Strength + Upgrades) in a single
-- DataStore key. Bump the store name when the saved schema changes
-- in a backwards-incompatible way.

local DataStoreService = game:GetService("DataStoreService")

local PlayerStore = DataStoreService:GetDataStore("PunchData_v1")

local DataStore = {}

-- Default starting stats for a brand-new player.
local function makeDefault()
	return {
		Strength = 0,
		Upgrades = {
			PunchPower = 1,
			PunchSpeed = 1,
		},
	}
end

function DataStore.LoadPlayer(player)
	local key = "Player_" .. player.UserId
	local ok, data = pcall(function()
		return PlayerStore:GetAsync(key)
	end)
	if not ok then
		warn("Failed to load stats for", player.Name)
		return makeDefault()
	end
	if not data then return makeDefault() end

	-- Forward-compat: backfill any upgrade keys that didn't exist
	-- when this save was written.
	data.Upgrades = data.Upgrades or {}
	data.Upgrades.PunchPower = data.Upgrades.PunchPower or 1
	data.Upgrades.PunchSpeed = data.Upgrades.PunchSpeed or 1
	data.Strength = data.Strength or 0
	return data
end

function DataStore.SavePlayer(player, stats)
	local key = "Player_" .. player.UserId
	local ok, err = pcall(function()
		PlayerStore:SetAsync(key, stats)
	end)
	if not ok then
		warn("Failed to save stats for", player.Name, ":", err)
		return false
	end
	return true
end

function DataStore.Init()
	print("DataStoreService initialized")
end

return DataStore
