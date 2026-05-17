local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Values = ReplicatedStorage.Values
local GameStarted: BoolValue = Values.GameStarted

local Modules = ReplicatedStorage.Modules

local Network = require(Modules.Network)
local AbilityPackets = Network.Ability.packets
local PerformPacket = AbilityPackets.Perform

local AbilitiesFolder = Modules.Abilities

local AbilityService = {}

function AbilityService:Init()
    PerformPacket.listen(function(data, plr)
        if not GameStarted.Value then return end

        local char = plr.Character
        if not char then return end

        local module = AbilitiesFolder:FindFirstChild("Leap")
        if not module then return end

        local required_module = require(module)

        if required_module.OnStartServer then
            required_module:OnStartServer(char)
        end
    end)
end

return AbilityService