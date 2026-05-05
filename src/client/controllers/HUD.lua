-- Strength counter, equipped-glove badge, upgrade shop, gloves
-- toggle. Built procedurally for the MVP — once the visual style is
-- locked in, replace this with a hand-built ScreenGui in StarterGui
-- that calls the same RemoteObjects.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteObjects = require(Shared:WaitForChild("RemoteObjects"))
local Config = require(Shared:WaitForChild("Config"))

local THEME = Config.THEME

local HUD = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local strengthLabel
local gloveBadgeLabel
local upgradeButtons = {}    -- upgradeId → TextButton

local function makeStrengthCard(parent)
	local card = Instance.new("Frame")
	card.Name = "StrengthCard"
	card.AnchorPoint = Vector2.new(0, 0)
	card.Position = UDim2.new(0, 16, 0, 16)
	card.Size = UDim2.new(0, 280, 0, 72)
	card.BackgroundColor3 = THEME.Card
	card.BorderSizePixel = 0
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.CardBorder
	stroke.Thickness = 2
	stroke.Parent = card

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -16, 0, 18)
	title.Position = UDim2.new(0, 8, 0, 6)
	title.BackgroundTransparency = 1
	title.Text = "STRENGTH"
	title.TextColor3 = THEME.TextSecondary
	title.TextSize = 13
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Size = UDim2.new(1, -16, 0, 36)
	value.Position = UDim2.new(0, 8, 0, 26)
	value.BackgroundTransparency = 1
	value.Text = "0"
	value.TextColor3 = THEME.Energy
	value.TextSize = 32
	value.Font = Enum.Font.GothamBlack
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Parent = card

	return value
end

local function makeShopButton(parent, upgradeId, layoutOrder)
	local button = Instance.new("TextButton")
	button.Name = upgradeId .. "Button"
	button.Size = UDim2.new(0, 240, 0, 72)
	button.LayoutOrder = layoutOrder
	button.BackgroundColor3 = THEME.Primary
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.TextColor3 = THEME.TextOnPrimary
	button.TextSize = 16
	button.Font = Enum.Font.GothamBlack
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.PrimaryDark
	stroke.Thickness = 2
	stroke.Parent = button

	-- Manual hover / press feedback so we can use palette colours
	-- instead of Roblox's auto-darkening (which goes to dirty grey).
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = THEME.PrimaryHover
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = THEME.Primary
	end)
	button.MouseButton1Down:Connect(function()
		button.BackgroundColor3 = THEME.PrimaryPressed
	end)
	button.MouseButton1Up:Connect(function()
		button.BackgroundColor3 = THEME.PrimaryHover
	end)

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

-- Rounded badge in the top-right that shows the equipped glove and
-- doubles as the GLOVES-panel toggle button.
local function makeGloveBadge(parent, onClick)
	local badge = Instance.new("TextButton")
	badge.Name = "GloveBadge"
	badge.AnchorPoint = Vector2.new(1, 0)
	badge.Position = UDim2.new(1, -16, 0, 16)
	badge.Size = UDim2.new(0, 260, 0, 72)
	badge.BackgroundColor3 = THEME.Card
	badge.BorderSizePixel = 0
	badge.AutoButtonColor = false
	badge.Text = ""
	badge.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = badge

	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.CardBorder
	stroke.Thickness = 2
	stroke.Parent = badge

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0, 18)
	title.Position = UDim2.new(0, 8, 0, 6)
	title.BackgroundTransparency = 1
	title.Text = "GLOVES"
	title.TextColor3 = THEME.TextSecondary
	title.TextSize = 13
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = badge

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Size = UDim2.new(1, -16, 0, 36)
	value.Position = UDim2.new(0, 8, 0, 26)
	value.BackgroundTransparency = 1
	value.Text = "Wooden  ×1"
	value.TextColor3 = THEME.PrimaryDark
	value.TextSize = 22
	value.Font = Enum.Font.GothamBlack
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Parent = badge

	badge.MouseEnter:Connect(function()
		stroke.Color = THEME.Primary
	end)
	badge.MouseLeave:Connect(function()
		stroke.Color = THEME.CardBorder
	end)
	badge.MouseButton1Click:Connect(onClick)

	return value
end

local function refreshFromStats(stats)
	if not stats then return end
	if strengthLabel then
		strengthLabel.Text = tostring(math.floor(stats.Strength + 0.5))
	end
	if gloveBadgeLabel then
		local equipped = (stats.Gloves and stats.Gloves.Equipped) or "Wooden"
		local glove = Config.GetGlove(equipped)
		if glove then
			gloveBadgeLabel.Text = string.format("%s  ×%d", glove.DisplayName, glove.Multiplier)
			gloveBadgeLabel.TextColor3 = Config.GetRarityColor(glove.Rarity)
		end
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

function HUD.Init(opts)
	opts = opts or {}
	local onGlovesClick = opts.onGlovesClick or function() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "IronFistHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	strengthLabel = makeStrengthCard(screenGui)
	gloveBadgeLabel = makeGloveBadge(screenGui, onGlovesClick)
	buildShop(screenGui)

	-- Pull once on startup; the server also fires StatsUpdated right
	-- after PlayerAdded so we should never get stuck on the placeholder.
	local stats = RemoteObjects.GetStatsFunction:InvokeServer()
	refreshFromStats(stats)

	RemoteObjects.StatsUpdated.OnClientEvent:Connect(refreshFromStats)
end

return HUD
