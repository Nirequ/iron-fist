-- Spawns a small visual burst (yellow ball + floating "+N" text) at
-- the punching bag whenever the server reports a punch. Cheap MVP —
-- can later be replaced with ParticleEmitter assets and a SFX
-- library to get the OPM / DBZ feel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteObjects = require(Shared:WaitForChild("RemoteObjects"))

local PunchEffects = {}

local BURST_COLOR = Color3.fromRGB(255, 220, 80)
local BURST_LIFETIME = 0.6

local function flashAt(position, damage)
	local burst = Instance.new("Part")
	burst.Name = "PunchBurst"
	burst.Anchored = true
	burst.CanCollide = false
	burst.CanTouch = false
	burst.CanQuery = false
	burst.Material = Enum.Material.Neon
	burst.Color = BURST_COLOR
	burst.Shape = Enum.PartType.Ball
	burst.Size = Vector3.new(0.4, 0.4, 0.4)
	burst.Position = position
	burst.Parent = Workspace

	local label = Instance.new("BillboardGui")
	label.Size = UDim2.new(0, 80, 0, 32)
	label.AlwaysOnTop = true
	label.Adornee = burst
	label.Parent = burst

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = "+" .. tostring(math.floor(damage + 0.5))
	text.TextColor3 = BURST_COLOR
	text.TextStrokeColor3 = Color3.fromRGB(40, 20, 0)
	text.TextStrokeTransparency = 0
	text.TextScaled = true
	text.Font = Enum.Font.GothamBlack
	text.Parent = label

	TweenService:Create(
		burst,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(2.5, 2.5, 2.5), Transparency = 1 }
	):Play()

	task.delay(BURST_LIFETIME, function()
		burst:Destroy()
	end)
end

function PunchEffects.Init()
	RemoteObjects.PunchEffect.OnClientEvent:Connect(function(_player, damage)
		local bag = Workspace:FindFirstChild("PunchingBag")
		if not bag then return end
		flashAt(bag.Position, damage)
	end)
end

return PunchEffects
