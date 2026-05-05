-- Captures mouse-clicks / touches anywhere on screen (excluding UI)
-- and forwards them to the server. The server still gates how much
-- Strength is awarded — this just emits the intent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteObjects = require(Shared:WaitForChild("RemoteObjects"))

local ClickHandler = {}

-- Subscribers receive Vector2(screenX, screenY) for every accepted
-- click. FloatingNumbers uses this to spawn the "+N" labels at the
-- exact click position.
local subscribers = {}

function ClickHandler.OnClick(callback)
	table.insert(subscribers, callback)
	return function()
		for i, cb in ipairs(subscribers) do
			if cb == callback then
				table.remove(subscribers, i)
				return
			end
		end
	end
end

local function isClickInput(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function dispatch(position)
	for _, callback in ipairs(subscribers) do
		task.spawn(callback, position)
	end
end

function ClickHandler.Init()
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		-- Don't count clicks that landed on a UI element (shop,
		-- buttons, chat, etc.).
		if gameProcessedEvent then return end
		if not isClickInput(input) then return end

		-- input.Position is a Vector3 in screen space — Z component
		-- is the depth from the camera, irrelevant for our 2D label.
		local screenPos = Vector2.new(input.Position.X, input.Position.Y)
		dispatch(screenPos)

		RemoteObjects.ClickFired:FireServer()
	end)

	print("ClickHandler initialized — every screen click fires +1")
end

return ClickHandler
