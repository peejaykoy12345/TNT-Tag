local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Utilities = ReplicatedStorage.Modules.Utilities
local GeneralUtilities = Utilities.General
local Cooldown = require(GeneralUtilities.Cooldown)
local AbilityUtilities = require(GeneralUtilities.AbilityUtilities)

local CONFIG = {
    POWER = 50,
    COOLDOWN = 2,
}

local Leap = {}

function Leap:OnStartServer(char: Model)
    if not AbilityUtilities:CanPerformAction(char, script.Name) then return end

    local hrp = char:FindFirstChild("HumanoidRootPart") :: Part
    if not hrp then return end

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 1, 0) * CONFIG.POWER
    bv.MaxForce = Vector3.new(40000, 40000, 40000)
    bv.Parent = hrp

    Debris:AddItem(bv, .3)

    Cooldown:SetCooldown(char, script.Name, CONFIG.COOLDOWN)
end

return Leap