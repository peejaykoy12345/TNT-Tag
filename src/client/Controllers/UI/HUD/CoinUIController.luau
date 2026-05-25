local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Modules.Network)
local ReplicationPackets = Network.Replication.packets
local InitializePacket = ReplicationPackets.Initialize
local UpdatePacket = ReplicationPackets.Update

local plr = Players.LocalPlayer
local HudGui = plr:WaitForChild("PlayerGui"):WaitForChild("HudGui")
local CoinFrame = HudGui:WaitForChild("LeftContainer"):WaitForChild("HudButtonsFrame"):WaitForChild("CoinFrame") :: Frame
local CoinLabel = CoinFrame:WaitForChild("CoinLabel") :: TextLabel
local CoinLabelShadow = CoinLabel:WaitForChild("CoinLabel") :: TextLabel

local CoinUIController = {}

function CoinUIController:Init()
    UpdatePacket.listen(function(data)
        local name = data.Name
        local coin = data.Value.uint32

        if name ~= "Coins" then return end

        CoinLabel.Text = tostring(coin)
        CoinLabelShadow.Text = CoinLabel.Text
    end)
    InitializePacket.send({Name = "Coins"})
end

return CoinUIController