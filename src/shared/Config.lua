-- Iron Fist — game configuration
-- Single source of truth for upgrade prices, formulas, and tuning
-- knobs. Server reads it for validation; client reads it for the
-- shop labels.

local Config = {}

-- Single source of truth for in-game colors. Both client (HUD,
-- effects) and server (workspace props built in code) reference
-- this table so the visual style stays consistent.
--
-- Style: bright anime minimalism — light cream background, pure
-- white cards, vibrant green primary, neon-lime click flashes.
Config.THEME = {
	-- Backgrounds
	BackgroundLight   = Color3.fromHex("F4FFF4"),
	BackgroundMain    = Color3.fromHex("E8FCE8"),

	-- Cards / panels
	Card              = Color3.fromHex("FFFFFF"),
	CardBorder        = Color3.fromHex("D7EED7"),

	-- Primary green (buttons, sliders, the bag's stripes)
	Primary           = Color3.fromHex("7ED957"),
	PrimaryLight      = Color3.fromHex("B6F58C"),
	PrimaryDark       = Color3.fromHex("5DBE3E"),
	PrimaryHover      = Color3.fromHex("6BCB4E"),
	PrimaryPressed    = Color3.fromHex("4FA837"),

	-- Neon accent (click flashes, special FX)
	Accent            = Color3.fromHex("C7FF3A"),
	AccentSoft        = Color3.fromHex("E6FF9A"),

	-- Strength / energy meter
	Energy            = Color3.fromHex("00E5A0"),
	EnergyBright      = Color3.fromHex("00FFC6"),

	-- Economy
	Coin              = Color3.fromHex("FFD54F"),
	Sale              = Color3.fromHex("FFB300"),

	-- Rarities (gradient stops on legendaries / mythics; see
	-- Theme notes in README → "Rarity gradients").
	RarityCommon      = Color3.fromHex("BDBDBD"),
	RarityUncommon    = Color3.fromHex("7ED957"),
	RarityRare        = Color3.fromHex("4FC3F7"),
	RarityEpic        = Color3.fromHex("9B5CFF"),
	RarityLegendary   = Color3.fromHex("FFB300"),
	RarityMythic      = Color3.fromHex("FF4FD8"),

	-- Text
	TextPrimary       = Color3.fromHex("2E3A2E"),
	TextSecondary     = Color3.fromHex("5C7A5C"),
	TextOnPrimary     = Color3.fromHex("FFFFFF"),
}

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
