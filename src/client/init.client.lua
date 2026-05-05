-- Iron Fist client entry point.
--
-- Loads the minimal Lua HUD + the punch-burst effect handler. Both
-- of these are MVP placeholders — the HUD especially is meant to be
-- replaced with a hand-built ScreenGui in StarterGui once the visual
-- style is locked in.

print("=== Iron Fist client starting ===")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
player:WaitForChild("PlayerGui")

require(script.controllers.HUD).Init()
require(script.controllers.PunchEffects).Init()

print("=== Iron Fist client ready ===")
