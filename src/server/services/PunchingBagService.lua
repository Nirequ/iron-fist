-- Spawns a punching bag in the workspace and routes its
-- ClickDetector / Touched events into PlayerStatsService.RegisterPunch.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PlayerStatsService = require(script.Parent.PlayerStatsService)

local PunchingBagService = {}

-- Build a single bag at the given world position and parent it to
-- Workspace. Returns the bag part for further customization.
local function makeBag(position)
	local bag = Instance.new("Part")
	bag.Name = "PunchingBag"
	bag.Size = Vector3.new(4, 8, 4)
	bag.Position = position + Vector3.new(0, 4, 0)
	bag.Anchored = true
	bag.Material = Enum.Material.Leather
	bag.Color = Color3.fromRGB(120, 35, 35)
	bag.TopSurface = Enum.SurfaceType.Smooth
	bag.BottomSurface = Enum.SurfaceType.Smooth

	local mesh = Instance.new("CylinderMesh")
	mesh.Parent = bag

	-- A bright neon stripe so the bag pops in the dark scene.
	local stripe = Instance.new("Part")
	stripe.Name = "Stripe"
	stripe.Size = Vector3.new(4.05, 0.4, 4.05)
	stripe.Position = bag.Position + Vector3.new(0, 1.5, 0)
	stripe.Anchored = true
	stripe.Material = Enum.Material.Neon
	stripe.Color = Color3.fromRGB(255, 200, 60)
	local stripeMesh = Instance.new("CylinderMesh")
	stripeMesh.Parent = stripe
	stripe.Parent = bag

	-- A small chain hint above the bag.
	local chain = Instance.new("Part")
	chain.Name = "Chain"
	chain.Size = Vector3.new(0.4, 2, 0.4)
	chain.Position = bag.Position + Vector3.new(0, 5, 0)
	chain.Anchored = true
	chain.Material = Enum.Material.Metal
	chain.Color = Color3.fromRGB(120, 120, 130)
	chain.Parent = bag

	-- Click to punch (PC + mobile).
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 16
	click.Parent = bag

	click.MouseClick:Connect(function(player)
		PlayerStatsService.RegisterPunch(player)
	end)

	-- Touch to punch — running into the bag also counts.
	bag.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		PlayerStatsService.RegisterPunch(player)
	end)

	bag.Parent = Workspace
	return bag
end

function PunchingBagService.Init()
	makeBag(Vector3.new(0, 0, 0))
	print("PunchingBagService initialized — placed PunchingBag at origin")
end

return PunchingBagService
