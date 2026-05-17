local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Values = ReplicatedStorage.Values
local GameStarted: BoolValue = Values.GameStarted

local Network = require(ReplicatedStorage.Modules.Network)
local ReplicationPackets = Network.Replication.packets
local InitializePacket = ReplicationPackets.Initialize
local UpdatePacket = ReplicationPackets.Update

local plr = Players.LocalPlayer
local HudGui = plr:WaitForChild("PlayerGui"):WaitForChild("HudGui")
local TeamSplitFrame = HudGui:WaitForChild("TopContainer"):WaitForChild("TeamSplitFrame") :: Frame
local TeamSplitLabel = TeamSplitFrame:WaitForChild("TeamSplitLabel") :: TextLabel
local TeamSplitLabelShadow = TeamSplitLabel:WaitForChild("TeamSplitLabel") :: TextLabel

local TimerUIController = {}

function TimerUIController:Init()
    UpdatePacket.listen(function(data)
        local name = data.Name
        local value = data.Value

        if name == "RunnersLeft" then
            self.currentRunners = value.uint8
            self:_ChangeTeamSplitLabelText(self.currentRunners, self.currentTagger)
        elseif name == "Tagger" then
            self.currentTagger = value.string
            self:_ChangeTeamSplitLabelText(self.currentRunners, self.currentTagger)
        end
    end)

    self:_ToggleHUDVisibility()

    GameStarted.Changed:Connect(function()
        self:_ToggleHUDVisibility()
    end)

    InitializePacket.send({Name = "RunnersLeft"})
    InitializePacket.send({Name = "Tagger"})
end

function TimerUIController:_ToggleHUDVisibility()
    TeamSplitFrame.Visible = GameStarted.Value
end

function TimerUIController:_ChangeTeamSplitLabelText(runnersLeft: number?, taggerName: string?)
    local text = string.format("Runners: %s  •  Tagger: %s", tostring(runnersLeft or "-"), tostring(taggerName or "-"))
    TeamSplitLabel.Text = text
    TeamSplitLabelShadow.Text = text
end

return TimerUIController