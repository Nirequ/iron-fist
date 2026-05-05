-- Iron Fist — game configuration
-- Single source of truth for upgrade prices, formulas, and tuning
-- knobs. Server reads it for validation; client reads it for the
-- shop labels.

local Config = {}

-- Currency name shown in the HUD.
Config.CURRENCY_NAME = "Strength"

-- How often a player can land a punch at level 1 of PunchSpeed,
-- expressed in seconds.
Config.BASE_PUNCH_COOLDOWN = 0.6

-- Strength gained per punch before any upgrade multipliers, at
-- level 1 of PunchPower.
Config.BASE_PUNCH_DAMAGE = 1

-- Upgrade definitions. Keys are stored verbatim in the DataStore, so
-- don't rename them once shipped.
Config.UPGRADES = {
	PunchPower = {
		DisplayName = "Stronger Punches",
		Description = "+1 base damage per punch.",
		BaseCost = 25,
		CostMultiplier = 1.6,    -- cost grows ~60 % per level
		EffectPerLevel = 1,      -- +1 damage per level
		MaxLevel = 50,
	},
	PunchSpeed = {
		DisplayName = "Faster Hands",
		Description = "Punch a little faster.",
		BaseCost = 50,
		CostMultiplier = 2.0,
		EffectPerLevel = 0.05,   -- −0.05 s cooldown per level
		MaxLevel = 8,            -- floor at 0.6 - 0.05*8 = 0.20 s
	},
}

-- Cost to upgrade from `currentLevel` to `currentLevel + 1`. Returns
-- math.huge if the upgrade is already at its cap.
function Config.GetUpgradeCost(upgradeId, currentLevel)
	local cfg = Config.UPGRADES[upgradeId]
	if not cfg then return math.huge end
	if currentLevel >= cfg.MaxLevel then return math.huge end
	return math.floor(cfg.BaseCost * (cfg.CostMultiplier ^ (currentLevel - 1)) + 0.5)
end

-- Strength gained per punch for a player at the given PunchPower
-- level. Level 1 = base damage, no upgrades applied.
function Config.ComputePunchDamage(level)
	return Config.BASE_PUNCH_DAMAGE
		+ Config.UPGRADES.PunchPower.EffectPerLevel * (level - 1)
end

-- Cooldown (in seconds) between consecutive punches for a player at
-- the given PunchSpeed level. Floors at 0.1 s so we can't hit zero.
function Config.ComputePunchCooldown(level)
	local raw = Config.BASE_PUNCH_COOLDOWN
		- Config.UPGRADES.PunchSpeed.EffectPerLevel * (level - 1)
	return math.max(0.1, raw)
end

return Config
