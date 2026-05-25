local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Modules.Network)
local SurviveLeaderboardPacket = Network.Misc.packets.SurviveLeaderboard

local plr = Players.LocalPlayer
local MenuGui = plr:WaitForChild("PlayerGui"):WaitForChild("MenuGui"):WaitForChild("MiddleContainer")
local SurviveLeaderboardMenu = MenuGui:WaitForChild("SurviveLeaderboardMenu") :: Frame
local Content = SurviveLeaderboardMenu:WaitForChild("Content") :: Frame
local CloseButton = SurviveLeaderboardMenu:WaitForChild("HeaderFrame"):WaitForChild("CloseButton") :: ImageButton

local SurviveLeaderboardController = {}

function SurviveLeaderboardController:_FormatTime(seconds: number): string
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

function SurviveLeaderboardController:_Clear()
    for _, frame in ipairs(Content:GetChildren()) do
        if not frame:IsA("Frame") or frame.Name == "Template" then continue end

        frame:Destroy()
    end
end

function SurviveLeaderboardController:Init()
    CloseButton.Activated:Connect(function()
        SurviveLeaderboardMenu.Visible = false
        self:_Clear()
    end)

    SurviveLeaderboardPacket.listen(function(results)
        self:_Clear()
        SurviveLeaderboardMenu.Visible = true

        for rank, entry in ipairs(results) do
            local frame = Content.Template:Clone()
            frame.Label.Text = string.format("#%d %s: %s", rank, entry.name, self:_FormatTime(entry.time))
            frame.Label.Label.Text = frame.Label.Text
            frame.Name = tostring(rank)
            frame.Parent = Content
            frame.Visible = true
        end
    end)
end

return SurviveLeaderboardController