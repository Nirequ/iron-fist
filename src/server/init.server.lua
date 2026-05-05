-- Iron Fist server entry point.

print("=== Iron Fist server starting ===")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
require(Shared:WaitForChild("RemoteObjects"))    -- creates Remotes folder

local DataStoreService = require(script.services.DataStoreService)
local PlayerStatsService = require(script.services.PlayerStatsService)
local PunchingBagService = require(script.services.PunchingBagService)

DataStoreService.Init()
PlayerStatsService.Init()
PunchingBagService.Init()

print("=== Iron Fist server ready ===")
