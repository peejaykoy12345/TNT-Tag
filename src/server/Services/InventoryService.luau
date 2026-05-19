local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
        local inventory = Profiles:GetData(plr, "Inventory")
        if not inventory then return end

        local isItemOwned = self:DoesPlayerOwnItem(plr, data.Type, data.ItemName)
        if not isItemOwned then return end

        inventory.Equipped[data.Type] = data.ItemName

        UpdatePacket.sendTo({
            Name = "OwnedItem",
            Args = {
                Type = data.Type,
            },
            Value = {
                string = data.ItemName
            },
        }, plr)
    end)
end

function InventoryService:DoesPlayerOwnItem(plr: Player, type: string, itemName: string): boolean
    local inventory = Profiles:GetData(plr, "Inventory")
    if not inventory then return false end

    if not inventory.Owned[type] then return false end

    return table.find(inventory.Owned[type], itemName) ~= nil
end

function InventoryService:GivePlayerItem(plr: Player, type: string, itemName: string)
    local profile = Profiles:GetProfile(plr)
    if not profile then return end

    if not profile.Data.Inventory.Owned[type] then return end

    table.insert(profile.Data.Inventory.Owned[type], itemName)
end

function InventoryService:IsItemEquipped(plr: Player, type: string, itemName: string): boolean
    local inventory = Profiles:GetData(plr, "Inventory")
    if not inventory then return false end

    if not inventory.Equipped[type] then return false end

    return inventory.Equipped[type] == itemName
end

return InventoryService