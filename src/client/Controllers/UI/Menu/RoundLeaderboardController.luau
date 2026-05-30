local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Modules.Network)
local SurviveLeaderboardPacket = Network.Misc.packets.SurviveLeaderboard

local plr = Players.LocalPlayer
local MenuGui = plr:WaitForChild("PlayerGui"):WaitForChild("MenuGui"):WaitForChild("MiddleContainer")
local SurviveLeaderboardMenu = MenuGui:WaitForChild("RoundLeaderboardMenu") :: Frame
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

function SurviveLeaderboardController:_SetProfilePicture(frame, playerName: string)
    task.spawn(function()
        local userId

        local player = Players:FindFirstChild(playerName)
        if player then
            userId = player.UserId
        else
            local ok, id = pcall(Players.GetUserIdFromNameAsync, Players, playerName)
            if not ok or not id then return end
            userId = id
        end

        local ok, imageUrl = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        if not ok or not imageUrl then return end

        local profilePicture = frame:FindFirstChild("ProfilePicture")
        if not profilePicture then return end

        profilePicture.Image = imageUrl
    end)
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

            self:_SetProfilePicture(frame, entry.name)
        end
    end)
end

return SurviveLeaderboardController