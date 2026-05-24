local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)
local LeaderboardNamespace = Network.Leaderboard
local LeaderboardUpdate = LeaderboardNamespace.packets.LeaderboardUpdate
local GetLeaderboardData = LeaderboardNamespace.queries.GetLeaderboardData

local LeaderboardController = {}

function LeaderboardController:Init()
    LeaderboardUpdate.listen(function(data)
        print(`[LeaderboardController] Live update — Rank #{data.rank} | {data.username} ({data.userId}) | Value: {data.value}`)
    end)
end

function LeaderboardController:Start()
    task.spawn(function()
        local data = GetLeaderboardData.invoke({})

        print("[LeaderboardController] === Leaderboard ===")
        for _, entry in ipairs(data.entries) do
            print(`  #{entry.rank} {entry.username} ({entry.userId}) — {entry.value}`)
        end

        local p = data.playerEntry
        print(`[LeaderboardController] Your rank: #{p.rank} | {p.username} | Value: {p.value}`)
    end)
end

return LeaderboardController