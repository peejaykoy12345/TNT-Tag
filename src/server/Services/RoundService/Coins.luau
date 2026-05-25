local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local MapMarkers = workspace.MapMarkers
local GoldSpawns: {Part} = MapMarkers.GoldSpawn:GetChildren()

local CoinPart = ReplicatedStorage.Assets.General.Models.Coin

local Services = ServerScriptService.Services
local Profiles = require(Services.Profiles)

local CONFIG = {
    COIN_SPAWN_INTERVAL = 1,
    COIN_CHANCE_TO_SPAWN = .25,
}

local Coins = {}

local spawnLoop: thread? = nil
local spawnLoopStopped = false
local coinCounts: {[Part]: number} = {}

function Coins:_InitializeCoin(coin: Part, spawnPart: Part)
    coin.Touched:Connect(function(partWhoTouched)
        local char = partWhoTouched.Parent
        if not char:IsA("Model") then return end

        local plr = Players:GetPlayerFromCharacter(char)
        if not plr then return end

        coinCounts[spawnPart] = math.max(0, (coinCounts[spawnPart] or 0) - 1)
        coin:Destroy()
        Profiles:IncrementData(plr, "Coins", 1)
    end)
end

function Coins:_GetBestSpawn(): Part
    local emptySpawn = nil
    local leastCoinSpawn = nil
    local leastCount = math.huge

    for _, spawnPart in GoldSpawns do
        local count = coinCounts[spawnPart] or 0

        if count == 0 then
            emptySpawn = spawnPart
            break
        end

        if count < leastCount then
            leastCount = count
            leastCoinSpawn = spawnPart
        end
    end

    return emptySpawn or leastCoinSpawn
end

function Coins:_SpawnCoin()
    if math.random() > CONFIG.COIN_CHANCE_TO_SPAWN then return end

    local spawnPart = self:_GetBestSpawn()
    if not spawnPart then return end

    local count = coinCounts[spawnPart] or 0
    local coin = CoinPart:Clone()

    coin.Position = spawnPart.Position
    coin.Parent = workspace.Coins

    coinCounts[spawnPart] = count + 1
    self:_InitializeCoin(coin, spawnPart)
end

function Coins:Start()
    print("Coins:Start() called")

    spawnLoopStopped = false
    coinCounts = {}

    spawnLoop = task.spawn(function()
        while not spawnLoopStopped do
            task.wait(CONFIG.COIN_SPAWN_INTERVAL)
            if spawnLoopStopped then break end
            self:_SpawnCoin()
        end
    end)
end

function Coins:Stop()
    print("Coins:Stop() called")
    spawnLoopStopped = true

    if spawnLoop then
        task.cancel(spawnLoop)
        spawnLoop = nil
    end

    workspace.Coins:ClearAllChildren()
    coinCounts = {}
end

return Coins