local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Modules
local Utilities = Modules.Utilities
local MediaUtilities = Utilities.Media

local Animation = require(MediaUtilities.Animation)

local plr = Players.LocalPlayer

local ASSETS = {
    ANIMATIONS = {
        WALK = ReplicatedStorage.Assets.Animations.Misc.Walk
    }
}

local CONFIG = {
    IN_AIR_ANIMATION_SPEED = 0.2
}

local MovementController = {}

function MovementController:Init()
    local function onCharacterAdded(char)
        local animate = char:WaitForChild("Animate")
        if animate then
            animate:Destroy()
        end

        local humanoid = char:WaitForChild("Humanoid")
        local rootPart = char:WaitForChild("HumanoidRootPart")
        local walkTrack = Animation:Play(char, ASSETS.ANIMATIONS.WALK)
        walkTrack:Stop()

        local inAir = false

        humanoid.StateChanged:Connect(function(_, new)
            if new == Enum.HumanoidStateType.Freefall or new == Enum.HumanoidStateType.Jumping then
                inAir = true
                walkTrack:AdjustSpeed(CONFIG.IN_AIR_ANIMATION_SPEED)
            elseif new == Enum.HumanoidStateType.Running or new == Enum.HumanoidStateType.Landed then
                inAir = false
                local speed = rootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
                if speed.Magnitude > 0.2 then
                    walkTrack:AdjustSpeed(1)
                end
            end
        end)

        RunService.Heartbeat:Connect(function()
            if inAir then return end

            local speed = rootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
            if speed.Magnitude > 0.2 then
                if not walkTrack.IsPlaying then
                    walkTrack:Play()
                end
                walkTrack:AdjustSpeed(1)
            else
                if walkTrack.IsPlaying then
                    walkTrack:AdjustSpeed(0)
                    walkTrack.TimePosition = 0
                    walkTrack:Stop()
                end
            end
        end)
    end

    if plr.Character then
        onCharacterAdded(plr.Character)
    end

    plr.CharacterAdded:Connect(onCharacterAdded)
end

return MovementController