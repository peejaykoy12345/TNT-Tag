local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage.Modules
local Utilities = Modules.Utilities
local MediaUtilities = Utilities.Media

local Animation = require(MediaUtilities.Animation)

local plr = Players.LocalPlayer

local ASSETS = {
    ANIMATIONS = {
        WALK = {
            -- e.g LEFT, RIGHT
        }
    }
}

local MovementController = {}

function MovementController:Init()
    local function onCharacterAdded(character)
        local animate = character:WaitForChild("Animate")
        if animate then
            animate:Destroy()
        end
    end

    if plr.Character then
        onCharacterAdded(plr.Character)
    end

    plr.CharacterAdded:Connect(onCharacterAdded)
end

return MovementController