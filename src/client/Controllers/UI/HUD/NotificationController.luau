local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Modules.Network)
local NotificationPacket = Network.General.packets.Notification

local plr = Players.LocalPlayer
local NotificationGui = plr:WaitForChild("PlayerGui"):WaitForChild("NotificationGui")
local Container = NotificationGui:WaitForChild("Container")
local Template = Container:WaitForChild("Template") :: Frame

local CONFIG = {
    NOTIFICATION_DURATION = 2
}

local NotificationController = {}

function NotificationController:Init()
    NotificationPacket.listen(function(data)
        local msg = data.Message

        local notifFrame = Template:Clone()
        notifFrame.Label.Text = msg
        notifFrame.Label.Label.Text = msg

        notifFrame.Visible = true
        notifFrame.Parent = Container

        task.delay(CONFIG.NOTIFICATION_DURATION, function()
            local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

            local tweens = {
                TweenService:Create(notifFrame, tweenInfo, { BackgroundTransparency = 1 }),
                TweenService:Create(notifFrame.Label, tweenInfo, { TextTransparency = 1 }),
                TweenService:Create(notifFrame.Label.Label, tweenInfo, { TextTransparency = 1 }),
            }

            for _, tween in tweens do
                tween:Play()
            end

            tweens[1].Completed:Wait()
            notifFrame:Destroy()
        end)
    end)
end

return NotificationController