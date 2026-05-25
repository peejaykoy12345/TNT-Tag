local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Modules.Network)
local SurviveLeaderboardPacket = Network.Misc.packets.SurviveLeaderboard

local SurviveLeaderboard = {}

local roundStartTime: number? = nil
local roundEnded = false
local survivalTimes: {[string]: number} = {}

function SurviveLeaderboard:_FormatTime(seconds: number): string
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

function SurviveLeaderboard:_Broadcast()
    local results: {{name: string, time: number}} = {}
    for name, time in pairs(survivalTimes) do
        table.insert(results, {name = name, time = math.floor(time)})
    end
    table.sort(results, function(a, b) return a.time > b.time end)

    SurviveLeaderboardPacket.sendToAll(results)
end

function SurviveLeaderboard:StartRound()
    roundStartTime = os.clock()
    roundEnded = false
    survivalTimes = {}
end

function SurviveLeaderboard:RecordDeath(char: Model)
    if not roundStartTime then return end
    local plr = Players:GetPlayerFromCharacter(char)
    if not plr then return end
    if survivalTimes[plr.Name] then return end

    if roundEnded then
        if char.Parent ~= workspace.Runners then return end
        survivalTimes[plr.Name] = os.clock() - roundStartTime
        return
    end

    survivalTimes[plr.Name] = os.clock() - roundStartTime
end

function SurviveLeaderboard:EndRound()
    if not roundStartTime then return end
    roundEnded = true

    local endElapsed = os.clock() - roundStartTime

    for _, char in ipairs(workspace.Runners:GetChildren()) do
        local plr = Players:GetPlayerFromCharacter(char)
        if not plr then continue end
        if survivalTimes[plr.Name] then continue end
        survivalTimes[plr.Name] = endElapsed
    end

    self:_Broadcast()
end

return SurviveLeaderboard