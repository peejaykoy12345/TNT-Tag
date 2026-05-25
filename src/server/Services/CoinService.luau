local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Profiles = require(ServerScriptService.Services.Profiles)

local Network = require(ReplicatedStorage.Modules.Network)
local ReplicationPackets = Network.Replication.packets
local InitializePacket = ReplicationPackets.Initialize
local UpdatePacket = ReplicationPackets.Update

local CoinService = {}

function CoinService:Init()
    InitializePacket.listen(function(data, plr)
        if data.Name ~= "Coins" then return end

        local coin = Profiles:GetData(plr, "Coins")
        if not coin then return end

        UpdatePacket.sendTo({
            Name = "Coins",
            Value = {
                uint32 = coin
            },
        }, plr)
    end)
end

function CoinService:GiveCoin(plr: Player, amountToBeGiven: number)
    local profile = Profiles:GetProfile(plr)
    if not profile then return end

    profile.Data.Coins += amountToBeGiven
    UpdatePacket.sendTo({
        Name = "Coins",
        Value = {
            uint32 = profile.Data.Coins,
        },
    }, plr)
end

function CoinService:CanAfford(plr: Player, price: number): boolean
    local coin = Profiles:GetData(plr, "Coins")
    if not coin then return false end

    return coin >= price
end

return CoinService