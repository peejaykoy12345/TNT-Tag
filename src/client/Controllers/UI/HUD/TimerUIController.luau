local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)
local ReplicationPackets = Network.Replication.packets
local UpdatePacket = ReplicationPackets.Update

local plr = Players.LocalPlayer
local HudGui = plr:WaitForChild("PlayerGui"):WaitForChild("HudGui")
local TimerFrame = HudGui:WaitForChild("TopContainer"):WaitForChild("TimerFrame")
local TimerLabel = TimerFrame:WaitForChild("TimerLabel") :: TextLabel
local TimerLabelShadow = TimerLabel:WaitForChild("TimerLabel") :: TextLabel

local TimerUIController = {}

function TimerUIController:Init()
    UpdatePacket.listen(function(data)
        local name = data.Name
        local value = data.Value

        if name ~= "Timer" then return end

        local seconds = value.uint16
        self:_ChangeTimerText(seconds)
    end)
end

function TimerUIController:_ChangeTimerText(seconds: number)
    local text = tostring(seconds)
    TimerLabel.Text = text
    TimerLabelShadow.Text = text
end

return TimerUIController