local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Values = ReplicatedStorage.Values
local GameStarted: BoolValue = Values.GameStarted

local plr = Players.LocalPlayer

local CONFIG = {
    DEFAULT_FOV = 70,
    SPRINT_FOV = 85,
    TWEEN_IN_TIME = 0.3,
    TWEEN_OUT_TIME = 0.5,
}

local FOVController = {}

function FOVController:Init()
    local isFOVActive = false

    RunService.Heartbeat:Connect(function()
        if not GameStarted.Value then return end

        local char = plr.Character
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart
        local humanoid = char:FindFirstChildOfClass("Humanoid") :: Humanoid
        if not hrp or not humanoid then return end

        local isMoving = humanoid.MoveDirection.Magnitude > 0

        if isMoving and not isFOVActive then
            isFOVActive = true
            TweenService:Create(workspace.CurrentCamera, TweenInfo.new(CONFIG.TWEEN_IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = CONFIG.SPRINT_FOV}):Play()
        elseif not isMoving and isFOVActive then
            isFOVActive = false
            TweenService:Create(workspace.CurrentCamera, TweenInfo.new(CONFIG.TWEEN_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = CONFIG.DEFAULT_FOV}):Play()
        end
    end)
end

return FOVController