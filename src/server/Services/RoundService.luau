local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local MapMarkers = workspace.MapMarkers

local Values = ReplicatedStorage.Values
local GameStarted: BoolValue = Values.GameStarted

local Network = require(ReplicatedStorage.Modules.Network)
local ReplicationPackets = Network.Replication.packets
local UpdatePacket = ReplicationPackets.Update

local CONFIG = {
    INTERMISSION_TIME = 7,
}

local RoundService = {}

function RoundService:_StartRound()
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if not char then continue end
        
        char:PivotTo(CFrame.new(MapMarkers.RoundStart.Position))
    end
end

function RoundService:_StartIntermission()
    for i = CONFIG.INTERMISSION_TIME, 0, -1 do
        UpdatePacket.sendToAll({Name = "Timer", Value = {uint16 = i}})

        if i == 0 then
            GameStarted.Value = true
            self:_StartRound()
            break
        end

        task.wait(1)
    end
end

function RoundService:Start()
    self:_StartIntermission()
end

return RoundService