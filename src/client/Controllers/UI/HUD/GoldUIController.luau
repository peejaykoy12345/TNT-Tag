local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Modules.Network)
local ReplicationPackets = Network.Replication.packets
local InitializePacket = ReplicationPackets.Initialize
local UpdatePacket = ReplicationPackets.Update

local plr = Players.LocalPlayer
local HudGui = plr:WaitForChild("PlayerGui"):WaitForChild("HudGui")
local GoldFrame = HudGui:WaitForChild("LeftContainer"):WaitForChild("HudButtonsFrame"):WaitForChild("GoldFrame") :: Frame
local GoldLabel = GoldFrame:WaitForChild("GoldLabel") :: TextLabel
local GoldLabelShadow = GoldLabel:WaitForChild("GoldLabel") :: TextLabel

local GoldUIController = {}

function GoldUIController:Init()
    UpdatePacket.listen(function(data)
        local name = data.Name
        local gold = data.Value.uint32

        if name ~= "Gold" then return end

        GoldLabel.Text = tostring(gold)
        GoldLabelShadow.Text = GoldLabel.Text
    end)
    InitializePacket.send({Name = "Gold"})
end

return GoldUIController