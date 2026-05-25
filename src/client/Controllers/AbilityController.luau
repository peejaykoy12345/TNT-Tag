local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Values = ReplicatedStorage.Values
local GameStarted: BoolValue = Values.GameStarted

local Modules = ReplicatedStorage.Modules

local Network = require(Modules.Network)
local AbilityPackets = Network.Ability.packets
local PerformPacket = AbilityPackets.Perform

local AbilityController = {}

function AbilityController:FirePerformPacket()
    if not GameStarted.Value then return end
    
    PerformPacket.send({})
end

return AbilityController
