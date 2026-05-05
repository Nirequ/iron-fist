-- Spawns a punching bag in the workspace as a visual focus point.
-- The new "click anywhere" mechanic means the bag itself no longer
-- handles click input; it's just a target / future AFK-zone anchor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local THEME = Config.THEME

local PunchingBagService = {}

-- Build a single bag at the given world position and parent it to
-- Workspace. Returns the bag part for further customization.
local function makeBag(position)
	local bag = Instance.new("Part")
	bag.Name = "PunchingBag"
	bag.Size = Vector3.new(4, 8, 4)
	bag.Position = position + Vector3.new(0, 4, 0)
	bag.Anchored = true
	bag.Material = Enum.Material.SmoothPlastic
	bag.Color = THEME.Card
	bag.TopSurface = Enum.SurfaceType.Smooth
	bag.BottomSurface = Enum.SurfaceType.Smooth

	local mesh = Instance.new("CylinderMesh")
	mesh.Parent = bag

	-- Bright primary stripe through the middle of the bag.
	local stripe = Instance.new("Part")
	stripe.Name = "Stripe"
	stripe.Size = Vector3.new(4.05, 1.2, 4.05)
	stripe.Position = bag.Position
	stripe.Anchored = true
	stripe.Material = Enum.Material.SmoothPlastic
	stripe.Color = THEME.Primary
	local stripeMesh = Instance.new("CylinderMesh")
	stripeMesh.Parent = stripe
	stripe.Parent = bag

	-- Neon highlight ring above the stripe — adds a bit of "anime
	-- glow" to the otherwise minimalist bag.
	local glow = Instance.new("Part")
	glow.Name = "Glow"
	glow.Size = Vector3.new(4.1, 0.2, 4.1)
	glow.Position = bag.Position + Vector3.new(0, 0.7, 0)
	glow.Anchored = true
	glow.Material = Enum.Material.Neon
	glow.Color = THEME.Accent
	local glowMesh = Instance.new("CylinderMesh")
	glowMesh.Parent = glow
	glow.Parent = bag

	-- A small chain hint above the bag (silver, low-key).
	local chain = Instance.new("Part")
	chain.Name = "Chain"
	chain.Size = Vector3.new(0.4, 2, 0.4)
	chain.Position = bag.Position + Vector3.new(0, 5, 0)
	chain.Anchored = true
	chain.Material = Enum.Material.Metal
	chain.Color = THEME.CardBorder
	chain.Parent = bag

	bag.Parent = Workspace
	return bag
end

function PunchingBagService.Init()
	-- Place the bag a few studs away from the SpawnLocation so the
	-- player can actually walk to it instead of spawning inside it.
	makeBag(Vector3.new(12, 0, 0))
	print("PunchingBagService initialized — placed PunchingBag at (12, 0, 0)")
end

return PunchingBagService
