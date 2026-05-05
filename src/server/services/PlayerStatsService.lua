-- In-memory player-stats cache + remote handlers. Loads from
-- DataStore on join, autosaves every 60 s while in game, saves once
-- on leave. All authoritative gameplay state lives here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local RemoteObjects = require(Shared:WaitForChild("RemoteObjects"))
local DataStore = require(script.Parent.DataStoreService)

local PlayerStatsService = {}

local statsByUserId = {}    -- userId → stats table
local lastPunchAt = {}      -- userId → os.clock() of last punch
local lastSaveAt = {}       -- userId → os.clock() of last save

local AUTOSAVE_INTERVAL = 60   -- seconds

-- A public Roblox punch animation. If you want a different feel,
-- swap the asset id; the play / load logic stays the same.
local PUNCH_ANIMATION_ID = "rbxassetid://92159718"

-- One Animation instance is fine for every player — Animator:LoadAnimation
-- returns a fresh AnimationTrack per call.
local punchAnimation = Instance.new("Animation")
punchAnimation.AnimationId = PUNCH_ANIMATION_ID

local function playPunchAnimation(player)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end

	local ok, track = pcall(function()
		return animator:LoadAnimation(punchAnimation)
	end)
	if not ok or not track then return end

	track.Priority = Enum.AnimationPriority.Action
	-- fade-in, weight, speed; speed > 1 makes it feel snappier
	track:Play(0.1, 1, 1.5)
end

local function pushStatsToClient(player)
	local stats = statsByUserId[player.UserId]
	if not stats then return end
	RemoteObjects.StatsUpdated:FireClient(player, stats)
end

-- Called by PunchingBagService whenever the player connects with
-- the bag (click or touch). Validates per-player cooldown, then
-- credits Strength.
function PlayerStatsService.RegisterPunch(player)
	local stats = statsByUserId[player.UserId]
	if not stats then return end

	local cooldown = Config.ComputePunchCooldown(stats.Upgrades.PunchSpeed)
	local now = os.clock()
	local last = lastPunchAt[player.UserId] or 0
	if now - last < cooldown then return end
	lastPunchAt[player.UserId] = now

	local damage = Config.ComputePunchDamage(stats.Upgrades.PunchPower)
	stats.Strength = stats.Strength + damage

	pushStatsToClient(player)
	-- Tell every client to play a burst at the bag, so witnesses can
	-- see when other players hit hard.
	RemoteObjects.PunchEffect:FireAllClients(player, damage)
	-- Play the punch animation on the player's rig — Animator state
	-- replicates automatically, so every client sees the swing.
	playPunchAnimation(player)
end

function PlayerStatsService.GetStats(player)
	return statsByUserId[player.UserId]
end

function PlayerStatsService.BuyUpgrade(player, upgradeId)
	local stats = statsByUserId[player.UserId]
	if not stats then
		return { success = false, message = "Stats not loaded" }
	end

	local cfg = Config.UPGRADES[upgradeId]
	if not cfg then
		return { success = false, message = "Unknown upgrade" }
	end

	local level = stats.Upgrades[upgradeId] or 1
	if level >= cfg.MaxLevel then
		return { success = false, message = "Already at max level" }
	end

	local cost = Config.GetUpgradeCost(upgradeId, level)
	if stats.Strength < cost then
		return { success = false, message = "Not enough Strength" }
	end

	stats.Strength = stats.Strength - cost
	stats.Upgrades[upgradeId] = level + 1

	pushStatsToClient(player)
	return {
		success = true,
		upgradeId = upgradeId,
		newLevel = stats.Upgrades[upgradeId],
		remainingStrength = stats.Strength,
	}
end

local function onPlayerAdded(player)
	local stats = DataStore.LoadPlayer(player)
	statsByUserId[player.UserId] = stats
	lastSaveAt[player.UserId] = os.clock()
	-- Wait one tick so the client's RemoteObjects requires have a
	-- chance to resolve before we fire StatsUpdated at them.
	task.defer(pushStatsToClient, player)
end

local function onPlayerRemoving(player)
	local stats = statsByUserId[player.UserId]
	if stats then
		DataStore.SavePlayer(player, stats)
	end
	statsByUserId[player.UserId] = nil
	lastPunchAt[player.UserId] = nil
	lastSaveAt[player.UserId] = nil
end

local function autosaveLoop()
	while true do
		task.wait(15)
		local now = os.clock()
		for userId, stats in pairs(statsByUserId) do
			local last = lastSaveAt[userId] or 0
			if now - last >= AUTOSAVE_INTERVAL then
				local player = Players:GetPlayerByUserId(userId)
				if player then
					DataStore.SavePlayer(player, stats)
					lastSaveAt[userId] = now
				end
			end
		end
	end
end

function PlayerStatsService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	RemoteObjects.GetStatsFunction.OnServerInvoke = function(player)
		return statsByUserId[player.UserId]
	end

	RemoteObjects.BuyUpgradeFunction.OnServerInvoke = function(player, upgradeId)
		return PlayerStatsService.BuyUpgrade(player, upgradeId)
	end

	-- The client fires this whenever the player clicks/taps anywhere
	-- in the world (not over a UI element). The server is still the
	-- authority on how much Strength is gained — cooldown lives in
	-- RegisterPunch.
	RemoteObjects.ClickFired.OnServerEvent:Connect(function(player)
		PlayerStatsService.RegisterPunch(player)
	end)

	task.spawn(autosaveLoop)
	print("PlayerStatsService initialized")
end

return PlayerStatsService
