-- Iron Fist client entry point.

print("=== Iron Fist client starting ===")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
player:WaitForChild("PlayerGui")

local ClickHandler = require(script.controllers.ClickHandler)
local FloatingNumbers = require(script.controllers.FloatingNumbers)
local GlovesPanel = require(script.controllers.GlovesPanel)
local HUD = require(script.controllers.HUD)
local PunchEffects = require(script.controllers.PunchEffects)

ClickHandler.Init()
FloatingNumbers.Init(ClickHandler)
GlovesPanel.Init()
HUD.Init({
	onGlovesClick = function()
		GlovesPanel.Toggle()
	end,
})
PunchEffects.Init()

print("=== Iron Fist client ready ===")
