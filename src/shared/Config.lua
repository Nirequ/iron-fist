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
-- expressed in seconds. Set very low because the new mechanic is
-- "click anywhere on screen" — the cooldown only exists to stop
-- macro spam, not to gate the player's natural click rate.
Config.BASE_PUNCH_COOLDOWN = 0.05

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
		EffectPerLevel = 0.005,  -- −0.005 s cooldown per level
		MaxLevel = 8,
	},
}

-- Glove definitions. The Wooden glove is the default starter — every
-- player owns it, you can't unequip into "nothing". Order matters
-- only for UI sort; ids are stored verbatim in DataStore so don't
-- rename them once shipped.
Config.GLOVES_LIST = {
	{
		Id            = "Wooden",
		DisplayName   = "Wooden Gloves",
		Description   = "Bare-bones starter gloves.",
		Multiplier    = 1,
		Cost          = 0,
		Rarity        = "Common",
	},
	{
		Id            = "Iron",
		DisplayName   = "Iron Gloves",
		Description   = "Heavy iron knuckles. 2× clicks.",
		Multiplier    = 2,
		Cost          = 50,
		Rarity        = "Uncommon",
	},
	{
		Id            = "Steel",
		DisplayName   = "Steel Gloves",
		Description   = "Polished steel. 4× clicks.",
		Multiplier    = 4,
		Cost          = 500,
		Rarity        = "Rare",
	},
	{
		Id            = "Mythril",
		DisplayName   = "Mythril Gloves",
		Description   = "Light, sharp, magical. 9× clicks.",
		Multiplier    = 9,
		Cost          = 5000,
		Rarity        = "Epic",
	},
	{
		Id            = "Diamond",
		DisplayName   = "Diamond Gloves",
		Description   = "Crystalline edge. 19× clicks.",
		Multiplier    = 19,
		Cost          = 50000,
		Rarity        = "Legendary",
	},
	{
		Id            = "Dragon",
		DisplayName   = "Dragon Gloves",
		Description   = "Forged in dragonfire. 69× clicks.",
		Multiplier    = 69,
		Cost          = 500000,
		Rarity        = "Mythic",
	},
}

-- Built once at module load so we don't linear-scan on every lookup.
Config.GLOVES_BY_ID = {}
for _, glove in ipairs(Config.GLOVES_LIST) do
	Config.GLOVES_BY_ID[glove.Id] = glove
end

-- Maps a rarity label (Common / Uncommon / …) to the rarity colour
-- already declared in THEME. Falls back to Common grey on unknown
-- input.
function Config.GetRarityColor(rarity)
	local key = "Rarity" .. tostring(rarity)
	return Config.THEME[key] or Config.THEME.RarityCommon
end

function Config.GetGlove(id)
	return Config.GLOVES_BY_ID[id]
end

function Config.GetGloveMultiplier(id)
	local g = Config.GLOVES_BY_ID[id]
	if not g then return 1 end
	return g.Multiplier
end

-- Cost to upgrade from `currentLevel` to `currentLevel + 1`. Returns
-- math.huge if the upgrade is already at its cap.
function Config.GetUpgradeCost(upgradeId, currentLevel)
	local cfg = Config.UPGRADES[upgradeId]
	if not cfg then return math.huge end
	if currentLevel >= cfg.MaxLevel then return math.huge end
	return math.floor(cfg.BaseCost * (cfg.CostMultiplier ^ (currentLevel - 1)) + 0.5)
end

-- Strength gained per punch for a player at the given PunchPower
-- level, multiplied by the equipped glove's multiplier.
function Config.ComputePunchDamage(power, gloveMultiplier)
	gloveMultiplier = gloveMultiplier or 1
	local base = Config.BASE_PUNCH_DAMAGE
		+ Config.UPGRADES.PunchPower.EffectPerLevel * (power - 1)
	return base * gloveMultiplier
end

-- Cooldown (in seconds) between consecutive punches for a player at
-- the given PunchSpeed level. Floors at 0.015 s so we can't hit zero.
function Config.ComputePunchCooldown(level)
	local raw = Config.BASE_PUNCH_COOLDOWN
		- Config.UPGRADES.PunchSpeed.EffectPerLevel * (level - 1)
	return math.max(0.015, raw)
end

return Config
