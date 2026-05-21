local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Profiles = require(ServerScriptService.Services.Profiles)

local Network = require(ReplicatedStorage.Modules.Network)
local ReplicationPackets = Network.Replication.packets
local InitializePacket = ReplicationPackets.Initialize
local UpdatePacket = ReplicationPackets.Update

local GoldService = {}

function GoldService:Init()
    InitializePacket.listen(function(data, plr)
        if data.Name ~= "Gold" then return end

        local gold = Profiles:GetData(plr, "Gold")
        if not gold then return end

        UpdatePacket.sendTo({
            Name = "Gold",
            Value = {
                uint32 = gold
            },
        }, plr)
    end)
end

function GoldService:GiveGold(plr: Player, amountToBeGiven: number)
    local profile = Profiles:GetProfile(plr)
    if not profile then return end

    profile.Data.Gold += amountToBeGiven
    UpdatePacket.sendTo({
        Name = "Gold",
        Value = {
            uint32 = profile.Data.Gold,
        },
    }, plr)
end

function GoldService:CanAfford(plr: Player, price: number): boolean
    local gold = Profiles:GetData(plr, "Gold")
    if not gold then return false end

    return gold >= price
end

return GoldService