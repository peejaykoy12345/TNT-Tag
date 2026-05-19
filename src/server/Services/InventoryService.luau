local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Values = ReplicatedStorage.Values
local GameStarted: BoolValue = Values.GameStarted

local Profiles = require(ServerScriptService.Services.Profiles)

local Network = require(ReplicatedStorage.Modules.Network)
local ReplicationNamespace = Network.Replication
local ReplicationPackets = ReplicationNamespace.packets
local UpdatePacket = ReplicationPackets.Update

local InventoryNamespace = Network.Inventory
local InventoryPackets =InventoryNamespace.packets
local InventoryQueries = InventoryNamespace.queries
local EquipItem = InventoryPackets.EquipItem
local GetInventoryData = InventoryQueries.GetInventoryData

local InventoryService = {}

function InventoryService:Init()
    GetInventoryData.listen(function(data, plr)
        local response = Profiles:GetData(plr, "Inventory")
        if not response then return end

        return response
    end)

    EquipItem.listen(function(data, plr)
        print("Player: ", plr.Name, " requested for equip data:", data)
    end)
end

return InventoryService