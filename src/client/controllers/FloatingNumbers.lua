-- Renders short-lived "+N" labels at the screen position of each
-- click. Purely cosmetic, computed locally from the player's current
-- stats — even if the server's cooldown rejects a click, the label
-- still pops, which feels right for a clicker (clicking faster than
-- the cooldown is harmless, the label tells the player they hit).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local RemoteObjects = require(Shared:WaitForChild("RemoteObjects"))

local THEME = Config.THEME

local FloatingNumbers = {}

local LIFETIME = 0.7
local FLOAT_DISTANCE = 80    -- pixels the label drifts upward

local player = Players.LocalPlayer
local cachedStats     -- last value seen on StatsUpdated

local function currentDamage()
	local power = (cachedStats and cachedStats.Upgrades and cachedStats.Upgrades.PunchPower) or 1
	return Config.ComputePunchDamage(power)
end

local function spawnLabel(parent, screenPos, damage)
	local label = Instance.new("TextLabel")
	label.Name = "FloatingNumber"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	-- Convert a screen-space pixel position to UDim2.
	label.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
	label.Size = UDim2.fromOffset(120, 48)
	label.BackgroundTransparency = 1
	label.Text = "+" .. tostring(math.floor(damage + 0.5))
	label.TextColor3 = THEME.TextOnPrimary
	label.TextStrokeColor3 = THEME.PrimaryDark
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.ZIndex = 10
	label.Parent = parent

	local endPos = UDim2.fromOffset(screenPos.X, screenPos.Y - FLOAT_DISTANCE)

	local tween = TweenService:Create(
		label,
		TweenInfo.new(LIFETIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = endPos,
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}
	)
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

function FloatingNumbers.Init(clickHandler)
	-- Dedicated ScreenGui so labels render above the regular HUD
	-- without inheriting any of its layout / clipping.
	local playerGui = player:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FloatingNumbersGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 5
	screenGui.Parent = playerGui

	-- Pull stats once so we have a baseline damage value before the
	-- first StatsUpdated arrives.
	local initial = RemoteObjects.GetStatsFunction:InvokeServer()
	cachedStats = initial

	RemoteObjects.StatsUpdated.OnClientEvent:Connect(function(stats)
		cachedStats = stats
	end)

	clickHandler.OnClick(function(screenPos)
		spawnLabel(screenGui, screenPos, currentDamage())
	end)

	print("FloatingNumbers initialized")
end

return FloatingNumbers
