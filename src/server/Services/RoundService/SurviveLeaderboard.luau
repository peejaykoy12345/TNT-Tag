local Players = game:GetService("Players")

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
        table.insert(results, {name = name, time = time})
    end
    table.sort(results, function(a, b) return a.time > b.time end)

    local lines = {"===== Survival Leaderboard ====="}
    for rank, entry in ipairs(results) do
        table.insert(lines, string.format("#%d  %-20s  %s", rank, entry.name, self:_FormatTime(entry.time)))
    end
    table.insert(lines, "================================")

    local message = table.concat(lines, "\n")
    print(message)
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