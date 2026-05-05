-- Minimal Strength counter + shop HUD. Built procedurally in Lua
-- for the MVP only — once the visual style is locked in, replace
-- this with a hand-built ScreenGui in StarterGui and have it call
-- the same RemoteObjects.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteObjects = require(Shared:WaitForChild("RemoteObjects"))
local Config = require(Shared:WaitForChild("Config"))

local HUD = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local strengthLabel
local upgradeButtons = {}    -- upgradeId → TextButton

local GOLD = Color3.fromRGB(255, 215, 100)
local DARK = Color3.fromRGB(15, 15, 18)
local PANEL = Color3.fromRGB(35, 30, 25)

local function makeStrengthLabel(parent)
	local label = Instance.new("TextLabel")
	label.Name = "StrengthLabel"
	label.AnchorPoint = Vector2.new(0, 0)
	label.Position = UDim2.new(0, 16, 0, 16)
	label.Size = UDim2.new(0, 280, 0, 60)
	label.BackgroundColor3 = DARK
	label.BackgroundTransparency = 0.2
	label.BorderSizePixel = 0
	label.Text = "STRENGTH: 0"
	label.TextColor3 = GOLD
	label.TextSize = 22
	label.Font = Enum.Font.GothamBlack
	label.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	local stroke = Instance.new("UIStroke")
	stroke.Color = GOLD
	stroke.Thickness = 2
	stroke.Parent = label

	return label
end

local function makeShopButton(parent, upgradeId, layoutOrder)
	local button = Instance.new("TextButton")
	button.Name = upgradeId .. "Button"
	button.Size = UDim2.new(0, 240, 0, 64)
	button.LayoutOrder = layoutOrder
	button.BackgroundColor3 = PANEL
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Text = ""
	button.TextColor3 = GOLD
	button.TextSize = 16
	button.Font = Enum.Font.GothamBold
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = GOLD
	stroke.Thickness = 2
	stroke.Parent = button

	button.MouseButton1Click:Connect(function()
		local result = RemoteObjects.BuyUpgradeFunction:InvokeServer(upgradeId)
		if not result.success then
			warn("Buy " .. upgradeId .. " failed: " .. tostring(result.message))
		end
	end)

	return button
end

local function buildShop(parent)
	local frame = Instance.new("Frame")
	frame.Name = "Shop"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -16)
	frame.Size = UDim2.new(0, 520, 0, 80)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 16)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = frame

	upgradeButtons.PunchPower = makeShopButton(frame, "PunchPower", 1)
	upgradeButtons.PunchSpeed = makeShopButton(frame, "PunchSpeed", 2)
end

local function refreshFromStats(stats)
	if not stats then return end
	if strengthLabel then
		strengthLabel.Text = "STRENGTH: " .. tostring(math.floor(stats.Strength + 0.5))
	end
	for upgradeId, button in pairs(upgradeButtons) do
		local cfg = Config.UPGRADES[upgradeId]
		local level = (stats.Upgrades and stats.Upgrades[upgradeId]) or 1
		local costText
		if level >= cfg.MaxLevel then
			costText = "MAX"
		else
			local cost = Config.GetUpgradeCost(upgradeId, level)
			costText = "Cost: " .. cost
		end
		button.Text = string.format("%s\nLvl %d  •  %s",
			cfg.DisplayName, level, costText)
	end
end

function HUD.Init()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "IronFistHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	strengthLabel = makeStrengthLabel(screenGui)
	buildShop(screenGui)

	-- The server fires StatsUpdated right after PlayerAdded, but we
	-- also pull once on startup so we don't show "0" if the client
	-- script ran before the server got around to firing.
	local stats = RemoteObjects.GetStatsFunction:InvokeServer()
	refreshFromStats(stats)

	RemoteObjects.StatsUpdated.OnClientEvent:Connect(refreshFromStats)
end

return HUD
