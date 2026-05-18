local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local plr = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ShiftLockController = {}

local enabled = false

function ShiftLockController:Toggle()
	enabled = not enabled
	UserInputService.MouseBehavior = enabled and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
end

function ShiftLockController:Init()
	RunService.RenderStepped:Connect(function()
		if not enabled then return end

		local char = plr.Character
		if not char then return end

		local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then return end

		humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position) * CFrame.Angles(0, math.atan2(-camera.CFrame.LookVector.X, -camera.CFrame.LookVector.Z), 0)
	end)
end

return ShiftLockController