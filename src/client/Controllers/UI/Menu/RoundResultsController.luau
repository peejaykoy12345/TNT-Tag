local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Modules.Network)
local RoundResultsPacket = Network.Misc.packets.RoundResults

local plr = Players.LocalPlayer
local MenuGui = plr:WaitForChild("PlayerGui"):WaitForChild("MenuGui"):WaitForChild("MiddleContainer")
local RoundResultsMenu = MenuGui:WaitForChild("RoundResultsMenu") :: Frame
local Content = RoundResultsMenu:WaitForChild("Content") :: Frame
local CloseButton = RoundResultsMenu:WaitForChild("HeaderFrame"):WaitForChild("CloseButton") :: ImageButton

local RoundResultsController = {}

function RoundResultsController:_DeleteStats()
    for _, frame in ipairs(Content:GetChildren()) do
        if not frame:IsA("Frame") or frame.Name == "Template" then continue end

        frame:Destroy()
    end
end

function RoundResultsController:Init()
    CloseButton.Activated:Connect(function()
        RoundResultsMenu.Visible = false

        self:_DeleteStats()
    end)

    RoundResultsPacket.listen(function(result)
        self:_DeleteStats()

        RoundResultsMenu.Visible = true

        for StatName, Value in pairs(result) do
            local frame = Content.Template:Clone()
            frame.Label.Text = StatName .. ": " .. tostring(Value)
            frame.Label.Label.Text = frame.Label.Text

            frame.Name = StatName
            frame.Parent = Content
            frame.Visible = true
        end
    end)
end

return RoundResultsController