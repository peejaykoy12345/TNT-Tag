local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local MapMarkers = workspace.MapMarkers

local Values = ReplicatedStorage.Values
local GameStarted: BoolValue = Values.GameStarted

local Network = require(ReplicatedStorage.Modules.Network)
local ReplicationPackets = Network.Replication.packets
local InitializePacket = ReplicationPackets.Initialize
local UpdatePacket = ReplicationPackets.Update

local CONFIG = {
    INTERMISSION_TIME = 15,
    ROUND_TIME = 10,
    DISTANCE_NEEDED_TO_TAG = 10,
    TAG_COOLDOWN = 3,
    TAGGER_WALKSPEED = 28,
    RUNNER_WALKSPEED = 26,
}

local RoundService = {}

function RoundService:_ApplyTaggerEffects(tagger: Model)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.Name = "TaggerHighlight"
    highlight.Parent = tagger
end

function RoundService:_RemoveTaggerEffects(tagger: Model)
    local highlight = tagger:FindFirstChild("TaggerHighlight")
    if highlight then
        highlight:Destroy()
    end
end

function RoundService:_ApplyTaggerStats(tagger: Model)
    local hum = tagger:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    hum.WalkSpeed = CONFIG.TAGGER_WALKSPEED
end

function RoundService:_RemoveTaggerStats(tagger: Model)
    local hum = tagger:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    hum.WalkSpeed = CONFIG.RUNNER_WALKSPEED
end

function RoundService:_SendRunnersLeft()
    UpdatePacket.sendToAll({Name = "RunnersLeft", Value = {uint8 = #workspace.Runners:GetChildren() - 1}})
end

function RoundService:_SendTagger(tagger: Model)
    UpdatePacket.sendToAll({Name = "Tagger", Value = {string = tagger.Name}})
end

function RoundService:_SetupInitializeHandlers()
    InitializePacket.listen(function(data, plr)
        local name = data.Name

        if name == "RunnersLeft" then
            UpdatePacket.sendTo({Name = "RunnersLeft", Value = {uint8 = #workspace.Runners:GetChildren() - 1}}, plr)
        elseif name == "Tagger" then
            for _, runner in ipairs(workspace.Runners:GetChildren()) do
                if not runner:GetAttribute("Tagger") then continue end
                UpdatePacket.sendTo({Name = "Tagger", Value = {string = runner.Name}}, plr)
                break
            end
        end
    end)
end

function RoundService:_CleanupRound()
    if self.currentConnection then
        self.currentConnection:Disconnect()
        self.currentConnection = nil
    end

    for _, char in ipairs(workspace.Runners:GetChildren()) do
        self:_RemoveTaggerEffects(char)
        char:SetAttribute("Tagger", nil)

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
        end

        char.Parent = workspace
        char:PivotTo(MapMarkers.Spawn.CFrame)
    end

    GameStarted.Value = false
end

function RoundService:_CheckRoundEnd()
    local runners = workspace.Runners:GetChildren()
    if #runners <= 1 then
        self:_CleanupRound()
        self:_StartIntermission()
        return true
    end

    return false
end

function RoundService:_SelectRandomTagger()
    local runners = workspace.Runners:GetChildren()
    if #runners == 0 then return nil end

    for _, runner in ipairs(runners) do
        runner:SetAttribute("Tagger", nil)
    end

    local tagger = runners[math.random(1, #runners)]
    tagger:SetAttribute("Tagger", true)
    return tagger
end

function RoundService:_InitializeTagging(tagger: Model)
    if self.currentConnection then
        self.currentConnection:Disconnect()
        self.currentConnection = nil
    end

    self:_ApplyTaggerEffects(tagger)
    self:_ApplyTaggerStats(tagger)
    self:_SendTagger(tagger)

    self.currentConnection = RunService.Heartbeat:Connect(function()
        local hrp = tagger:FindFirstChild("HumanoidRootPart") :: BasePart
        if not hrp then return end

        if (os.clock() - (self.lastTagTime or 0)) < CONFIG.TAG_COOLDOWN then return end

        for _, runner in ipairs(workspace.Runners:GetChildren()) do
            if runner == tagger then continue end

            local runnerHrp = runner:FindFirstChild("HumanoidRootPart") :: BasePart
            if not runnerHrp then continue end

            if (hrp.Position - runnerHrp.Position).Magnitude >= CONFIG.DISTANCE_NEEDED_TO_TAG then continue end

            self.lastTagTime = os.clock()

            self:_RemoveTaggerEffects(tagger)
            self:_RemoveTaggerStats(tagger)

            tagger:SetAttribute("Tagger", nil)
            runner:SetAttribute("Tagger", true)

            self:_InitializeTagging(runner)
            return
        end
    end)
end

function RoundService:_KillTagger()
    if self.currentConnection then
        self.currentConnection:Disconnect()
        self.currentConnection = nil
    end

    for _, runner in ipairs(workspace.Runners:GetChildren()) do
        if not runner:GetAttribute("Tagger") then continue end

        local humanoid = runner:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end

        self:_RemoveTaggerEffects(runner)
        runner:SetAttribute("Tagger", nil)
        break
    end
end

function RoundService:_OnRunnerDied(char: Model)
    if not GameStarted.Value then return end

    self:_RemoveTaggerEffects(char)
    char:SetAttribute("Tagger", nil)
    char.Parent = workspace

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = 16
    end

    self:_SendRunnersLeft()
    self:_CheckRoundEnd()
end

function RoundService:_StartRoundTimer()
    for i = CONFIG.ROUND_TIME, 0, -1 do
        if not GameStarted.Value then return end

        UpdatePacket.sendToAll({Name = "Timer", Value = {uint16 = i}})

        if i == 0 then
            self:_KillTagger()

            if self:_CheckRoundEnd() then return end

            local tagger = self:_SelectRandomTagger()
            if tagger then
                self:_InitializeTagging(tagger)
            end

            self:_StartRoundTimer()
            return
        end

        task.wait(1)
    end
end

function RoundService:_StartRound()
    for _, char in ipairs(workspace.Runners:GetChildren()) do
        char.Parent = workspace
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if not char then continue end

        char:PivotTo(CFrame.new(MapMarkers.RoundStart.Position))
        char.Parent = workspace.Runners

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = CONFIG.RUNNER_WALKSPEED
            humanoid.Died:Once(function()
                self:_OnRunnerDied(char)
            end)
        end
    end

    self:_SendRunnersLeft()

    local tagger = self:_SelectRandomTagger()
    if tagger then
        self:_InitializeTagging(tagger)
        self:_StartRoundTimer()
    end
end

function RoundService:_StartIntermission()
    for i = CONFIG.INTERMISSION_TIME, 0, -1 do
        if GameStarted.Value then return end

        UpdatePacket.sendToAll({Name = "Timer", Value = {uint16 = i}})

        if i == 0 then
            if #Players:GetPlayers() < 2 then
                self:_StartIntermission()
                return
            end

            GameStarted.Value = true
            self:_StartRound()
            return
        end

        task.wait(1)
    end
end

function RoundService:_SetupRunnersListener()
    workspace.Runners.ChildRemoved:Connect(function()
        if not GameStarted.Value then return end
        task.defer(function()
            self:_CheckRoundEnd()
        end)
    end)
end

function RoundService:Start()
    self:_SetupInitializeHandlers()
    self:_SetupRunnersListener()
    self:_StartIntermission()
end

return RoundService