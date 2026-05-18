local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Values = ReplicatedStorage.Values
local GameStarted: BoolValue = Values.GameStarted

local Network = require(ReplicatedStorage.Modules.Network)
local ReplicationPackets = Network.Replication.packets
local InitializePacket = ReplicationPackets.Initialize
local UpdatePacket = ReplicationPackets.Update

local plr = Players.LocalPlayer
local MenuGui = plr:WaitForChild("PlayerGui"):WaitForChild("MenuGui"):WaitForChild("MiddleContainer")

local InventoryController = {}

function InventoryController:Init()
    
end

return InventoryController