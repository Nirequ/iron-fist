-- Modal panel listing every glove tier. Each row shows name,
-- rarity, multiplier, and an action button:
--   * BUY (with cost) — if not owned and you have enough Strength
--   * BUY (greyed)    — if not owned and you can't afford it
--   * EQUIP           — if owned but a different glove is equipped
--   * EQUIPPED        — if owned and currently equipped
--
-- The panel is hidden by default; HUD's GLOVES button toggles it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local RemoteObjects = require(Shared:WaitForChild("RemoteObjects"))

local THEME = Config.THEME

local GlovesPanel = {}

local player = Players.LocalPlayer
local screenGui
local cachedStats
local rowsByGloveId = {}

local function makeButton(parent)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 160, 0, 56)
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 16
	button.TextColor3 = THEME.TextOnPrimary
	button.Text = ""
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = button

	return button, stroke
end

-- Set the action button to one of four visual states. Encapsulating
-- this here keeps refresh() readable.
local function styleButton(button, stroke, mode)
	if mode == "EQUIPPED" then
		button.BackgroundColor3 = THEME.Energy
		button.TextColor3 = THEME.TextOnPrimary
		button.Text = "EQUIPPED"
		stroke.Color = THEME.EnergyBright
		button.Active = false
		button.AutoButtonColor = false
	elseif mode == "EQUIP" then
		button.BackgroundColor3 = THEME.Card
		button.TextColor3 = THEME.PrimaryDark
		button.Text = "EQUIP"
		stroke.Color = THEME.PrimaryDark
		button.Active = true
		button.AutoButtonColor = false
	elseif mode == "BUY_AFFORD" then
		button.BackgroundColor3 = THEME.Primary
		button.TextColor3 = THEME.TextOnPrimary
		stroke.Color = THEME.PrimaryDark
		button.Active = true
		button.AutoButtonColor = false
	elseif mode == "BUY_LOCKED" then
		button.BackgroundColor3 = THEME.CardBorder
		button.TextColor3 = THEME.TextSecondary
		stroke.Color = THEME.CardBorder
		button.Active = false
		button.AutoButtonColor = false
	end
end

local function buildRow(parent, glove, layoutOrder)
	local rarityColor = Config.GetRarityColor(glove.Rarity)

	local row = Instance.new("Frame")
	row.Name = glove.Id
	row.Size = UDim2.new(1, -16, 0, 88)
	row.BackgroundColor3 = THEME.Card
	row.BorderSizePixel = 0
	row.LayoutOrder = layoutOrder
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = row

	local stroke = Instance.new("UIStroke")
	stroke.Color = rarityColor
	stroke.Thickness = 3
	stroke.Parent = row

	-- Vertical rarity-coloured ribbon on the left edge.
	local ribbon = Instance.new("Frame")
	ribbon.Name = "Ribbon"
	ribbon.Size = UDim2.new(0, 8, 1, 0)
	ribbon.BackgroundColor3 = rarityColor
	ribbon.BorderSizePixel = 0
	ribbon.Parent = row

	local ribbonCorner = Instance.new("UICorner")
	ribbonCorner.CornerRadius = UDim.new(0, 4)
	ribbonCorner.Parent = ribbon

	-- Glove name (top-left).
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Position = UDim2.new(0, 24, 0, 10)
	name.Size = UDim2.new(0.55, 0, 0, 24)
	name.BackgroundTransparency = 1
	name.Text = glove.DisplayName
	name.Font = Enum.Font.GothamBlack
	name.TextSize = 18
	name.TextColor3 = THEME.TextPrimary
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = row

	-- Rarity + multiplier line.
	local meta = Instance.new("TextLabel")
	meta.Name = "Meta"
	meta.Position = UDim2.new(0, 24, 0, 36)
	meta.Size = UDim2.new(0.55, 0, 0, 18)
	meta.BackgroundTransparency = 1
	meta.Text = string.format("%s  •  ×%d", glove.Rarity, glove.Multiplier)
	meta.Font = Enum.Font.GothamBold
	meta.TextSize = 14
	meta.TextColor3 = rarityColor
	meta.TextXAlignment = Enum.TextXAlignment.Left
	meta.Parent = row

	-- Description.
	local desc = Instance.new("TextLabel")
	desc.Name = "Description"
	desc.Position = UDim2.new(0, 24, 0, 56)
	desc.Size = UDim2.new(0.55, 0, 0, 22)
	desc.BackgroundTransparency = 1
	desc.Text = glove.Description
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 12
	desc.TextColor3 = THEME.TextSecondary
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.TextWrapped = true
	desc.Parent = row

	-- Action button on the right.
	local btnHolder = Instance.new("Frame")
	btnHolder.AnchorPoint = Vector2.new(1, 0.5)
	btnHolder.Position = UDim2.new(1, -16, 0.5, 0)
	btnHolder.Size = UDim2.new(0, 160, 0, 56)
	btnHolder.BackgroundTransparency = 1
	btnHolder.Parent = row

	local button, btnStroke = makeButton(btnHolder)
	button.Size = UDim2.new(1, 0, 1, 0)

	rowsByGloveId[glove.Id] = {
		row = row,
		button = button,
		stroke = btnStroke,
	}

	button.MouseButton1Click:Connect(function()
		if not cachedStats then return end
		local owned = cachedStats.Gloves.Owned[glove.Id] == true
		local equipped = cachedStats.Gloves.Equipped == glove.Id

		if equipped then
			-- no-op
			return
		elseif owned then
			local ok = RemoteObjects.EquipGloveFunction:InvokeServer(glove.Id)
			if ok and not ok.success then
				warn("Equip " .. glove.Id .. " failed: " .. tostring(ok.message))
			end
		else
			local result = RemoteObjects.BuyGloveFunction:InvokeServer(glove.Id)
			if result and not result.success then
				warn("Buy " .. glove.Id .. " failed: " .. tostring(result.message))
			end
		end
	end)
end

local function refresh()
	if not cachedStats then return end
	for _, glove in ipairs(Config.GLOVES_LIST) do
		local handles = rowsByGloveId[glove.Id]
		if handles then
			local owned = cachedStats.Gloves.Owned[glove.Id] == true
			local equipped = cachedStats.Gloves.Equipped == glove.Id

			if equipped then
				styleButton(handles.button, handles.stroke, "EQUIPPED")
			elseif owned then
				styleButton(handles.button, handles.stroke, "EQUIP")
			else
				local canAfford = cachedStats.Strength >= glove.Cost
				handles.button.Text = string.format("BUY  •  %d", glove.Cost)
				styleButton(
					handles.button,
					handles.stroke,
					canAfford and "BUY_AFFORD" or "BUY_LOCKED"
				)
			end
		end
	end
end

function GlovesPanel.Open()
	if screenGui then screenGui.Enabled = true end
end

function GlovesPanel.Close()
	if screenGui then screenGui.Enabled = false end
end

function GlovesPanel.Toggle()
	if screenGui then screenGui.Enabled = not screenGui.Enabled end
end

function GlovesPanel.Init()
	local playerGui = player:WaitForChild("PlayerGui")
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GlovesPanelGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 8
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Dimmed backdrop covers the whole screen and acts as a click-
	-- to-close target.
	local backdrop = Instance.new("TextButton")
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.55
	backdrop.AutoButtonColor = false
	backdrop.Text = ""
	backdrop.Parent = screenGui
	backdrop.MouseButton1Click:Connect(function()
		GlovesPanel.Close()
	end)

	-- Modal card.
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.Size = UDim2.new(0, 600, 0, 580)
	card.BackgroundColor3 = THEME.BackgroundLight
	card.BorderSizePixel = 0
	card.Parent = screenGui

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 16)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = THEME.CardBorder
	cardStroke.Thickness = 2
	cardStroke.Parent = card

	-- Title.
	local title = Instance.new("TextLabel")
	title.Position = UDim2.new(0, 24, 0, 16)
	title.Size = UDim2.new(1, -100, 0, 36)
	title.BackgroundTransparency = 1
	title.Text = "GLOVES"
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 28
	title.TextColor3 = THEME.TextPrimary
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	-- Close X (top-right).
	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -16, 0, 16)
	close.Size = UDim2.new(0, 36, 0, 36)
	close.BackgroundColor3 = THEME.Card
	close.AutoButtonColor = false
	close.Text = "✕"
	close.Font = Enum.Font.GothamBlack
	close.TextSize = 20
	close.TextColor3 = THEME.TextSecondary
	close.Parent = card

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 10)
	closeCorner.Parent = close

	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = THEME.CardBorder
	closeStroke.Thickness = 2
	closeStroke.Parent = close

	close.MouseButton1Click:Connect(function()
		GlovesPanel.Close()
	end)

	-- Scrolling list area.
	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.new(0, 16, 0, 64)
	list.Size = UDim2.new(1, -32, 1, -80)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.ScrollBarImageColor3 = THEME.PrimaryDark
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = card

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.Padding = UDim.new(0, 12)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list

	for index, glove in ipairs(Config.GLOVES_LIST) do
		buildRow(list, glove, index)
	end

	local stats = RemoteObjects.GetStatsFunction:InvokeServer()
	cachedStats = stats
	refresh()

	RemoteObjects.StatsUpdated.OnClientEvent:Connect(function(s)
		cachedStats = s
		refresh()
	end)

	print("GlovesPanel initialized")
end

return GlovesPanel
