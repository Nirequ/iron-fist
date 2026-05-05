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
		Gloves = {
			Owned = { Wooden = true },
			Equipped = "Wooden",
		},
	}
end

-- Backfills any keys that didn't exist when an old save was written
-- so older players don't break on the new schema.
local function ensureSchema(data)
	data.Strength = data.Strength or 0
	data.Upgrades = data.Upgrades or {}
	data.Upgrades.PunchPower = data.Upgrades.PunchPower or 1
	data.Upgrades.PunchSpeed = data.Upgrades.PunchSpeed or 1
	data.Gloves = data.Gloves or {}
	data.Gloves.Owned = data.Gloves.Owned or {}
	data.Gloves.Owned.Wooden = true            -- always own starter
	data.Gloves.Equipped = data.Gloves.Equipped or "Wooden"
	return data
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
	return ensureSchema(data)
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
