local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utilities = ReplicatedStorage.Modules.Utilities
local GeneralUtilities = Utilities.General
local Cooldown = require(GeneralUtilities.Cooldown)

local AbilityUtilities = {}

function AbilityUtilities:CanPerformAction(char: Model, actionName: string): boolean
    if Cooldown:IsOnCooldown(char, actionName) then
		return false
	end

    return true
end

return AbilityUtilities