local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Values = ReplicatedStorage.Values
local GameStarted: BoolValue = Values.GameStarted

local Modules = ReplicatedStorage.Modules

local Network = require(Modules.Network)
local AbilityPackets = Network.Ability.packets
local PerformPacket = AbilityPackets.Perform

local AbilityController = {}

function AbilityController:_FirePerformPacket()
    if not GameStarted.Value then return end
    
    PerformPacket.send({})
end

function AbilityController:Init()
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end

        if input.KeyCode == Enum.KeyCode.Q then
            self:_FirePerformPacket()
        end
    end)
end

return AbilityController
