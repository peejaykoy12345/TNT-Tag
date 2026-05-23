local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Modules.Network)
local NotificationPacket = Network.General.packets.Notification

local plr = Players.LocalPlayer
local NotificationGui = plr:WaitForChild("PlayerGui"):WaitForChild("NotificationGui")
local Container = NotificationGui:WaitForChild("Container")
local Template = NotificationGui:WaitForChild("Template")

local NotificationController = {}

function NotificationController:Init()
    NotificationPacket.listen(function(data)
        local msg = data.Message

        local notifFrame = Template:Clone()
        notifFrame.Label.Text = msg
        notifFrame.Label.Label.Text = msg

        notifFrame.Visible = true
        notifFrame.Parent = Container
    end)
end

return NotificationController