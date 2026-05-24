local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local MapMarkers = workspace.MapMarkers

local Assets = ReplicatedStorage.Assets
local Bombs = Assets.Bombs
local Auras = Assets.Auras

local Values = ReplicatedStorage.Values
local GameStarted: BoolValue = Values.GameStarted

local InventoryService = require(ServerScriptService.Services.InventoryService)

local Modules = ReplicatedStorage.Modules
local Utilities = Modules.Utilities
local GeneralUtilities = Utilities.General
local AbilityUtilities = require(GeneralUtilities.AbilityUtilities)
local VelocityUtilities = require(GeneralUtilities.VelocityUtils)

local ClientFX = require(Utilities.Media.ClientFX)

local Network = require(Modules.Network)
local GeneralPackets = Network.General.packets
local ReplicationPackets = Network.Replication.packets
local NotificationPacket = GeneralPackets.Notification
local InitializePacket = ReplicationPackets.Initialize
local UnreliableUpdatePacket = ReplicationPackets.UnreliableUpdate
local UpdatePacket = ReplicationPackets.Update

local CONFIG = {
    INTERMISSION_TIME = 15,
    ROUND_TIME = 15,
    DISTANCE_NEEDED_TO_TAG = 10,
    TAG_COOLDOWN = 1,
    TAGGER_WALKSPEED = 32,
    RUNNER_WALKSPEED = 26,
    HITBOX = {
        SIZE = Vector3.new(15, 15, 15)
    },
    KNOCKBACK = {
        POWER = 80,
        DURATION = .5
    },
    RAGDOLL_DURATION = 3,
}

local RoundService = {}
RoundService.timerVersion = 0
RoundService.tagger = nil
RoundService.lastBombHolder = nil
RoundService.currentConnection = nil
RoundService.currentTaggerVFXHandleId = nil
RoundService.lastTagTime = 0

function RoundService:_ApplyTaggerEffects(tagger: Model)
    local RightArm = tagger:FindFirstChild("Right Arm") :: BasePart
    local hrp = tagger:FindFirstChild("HumanoidRootPart") :: BasePart
    if not RightArm then return end

    local RightGripAttachment = RightArm:FindFirstChild("RightGripAttachment") :: Attachment
    if not RightGripAttachment then return end

    local plr = Players:GetPlayerFromCharacter(tagger)
    if not plr then
        warn(`[Fatal Error] No player is found for: {tagger.Name}`)
        return
    end

    local equippedAura = InventoryService:GetEquippedItem(plr, "Auras")
    local equippedBomb = InventoryService:GetEquippedItem(plr, "Bombs")
    if not equippedAura then
        equippedAura = "Default"
    end
    if not equippedBomb then
        equippedBomb = "Default"
    end

    self.currentTaggerVFXHandleId = ClientFX:Construct(
        {
            Name = "ToggleParticles",
            Type = "General",
        },
        {
            vfx = Auras[equippedAura],
            parent = hrp,
            position = hrp.Position,
            deletionTime = 999,
        }
    )
    ClientFX:Start(self.currentTaggerVFXHandleId, {
        vfxCFrame = hrp.CFrame,
        position = hrp.Position,
        weld = true,
    })

    local bombModel = Bombs[equippedBomb]:Clone() :: Model
    bombModel:PivotTo(RightGripAttachment.WorldCFrame * bombModel:GetAttribute("CFrameOffset"))
    bombModel.Name = "Bomb"
    bombModel.Parent = RightArm

    local weld = Instance.new("Weld", bombModel.PrimaryPart)
    weld.Part0 = RightArm
    weld.Part1 = bombModel.PrimaryPart
    weld.C1 = bombModel:GetAttribute("CFrameOffset")
end

function RoundService:_RemoveTaggerEffects(tagger: Model)
    if self.currentTaggerVFXHandleId then
        ClientFX:Destroy(self.currentTaggerVFXHandleId)
        self.currentTaggerVFXHandleId = nil
    end

    local RightArm = tagger:FindFirstChild("Right Arm") :: BasePart
    if RightArm then
        local bomb = RightArm:FindFirstChild("Bomb")
        if bomb then
            bomb:Destroy()
        end
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
            if self.tagger then
                UpdatePacket.sendTo({Name = "Tagger", Value = {string = self.tagger.Name}}, plr)
            end
        end
    end)
end

function RoundService:_CleanupRound()
    if self.currentConnection then
        self.currentConnection:Disconnect()
        self.currentConnection = nil
    end

    local runners = workspace.Runners:GetChildren()

    for _, char in ipairs(runners) do
        self:_RemoveTaggerEffects(char)
        char:SetAttribute("Tagger", nil)

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = CONFIG.RUNNER_WALKSPEED
        end

        char.Parent = workspace
        char:PivotTo(MapMarkers.Spawn.CFrame)
    end

    self.tagger = nil
    self.lastBombHolder = nil
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
    if #runners == 0 then
        self.tagger = nil
        return nil
    end

    if self.tagger then
        self.tagger:SetAttribute("Tagger", nil)
    end

    local tagger = runners[math.random(1, #runners)]
    tagger:SetAttribute("Tagger", true)
    self.tagger = tagger
    return tagger
end

function RoundService:_TrySelectAndStartTagger()
    local tagger = self:_SelectRandomTagger()
    if tagger then
        self:_SendRunnersLeft()
        self:_InitializeTagging(tagger)
        self:_StartRoundTimer()
        return true
    end

    self:_CleanupRound()
    self:_StartIntermission()
    return false
end

function RoundService:_InitializeTagging(tagger: Model)
    if self.currentConnection then
        self.currentConnection:Disconnect()
        self.currentConnection = nil
    end

    self.tagger = tagger
    self:_ApplyTaggerEffects(tagger)
    self:_ApplyTaggerStats(tagger)
    self:_SendTagger(tagger)

    self.currentConnection = RunService.Heartbeat:Connect(function()
        local hrp = tagger:FindFirstChild("HumanoidRootPart") :: BasePart
        if not hrp then return end

        if (os.clock() - self.lastTagTime) < CONFIG.TAG_COOLDOWN then return end

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

            self.lastBombHolder = tagger

            self:_InitializeTagging(runner)
            return
        end
    end)
end

function RoundService:_ExplodeBomb()
    if self.currentConnection then
        self.currentConnection:Disconnect()
        self.currentConnection = nil
    end

    local runner = self.tagger
    if not runner then return end

    local plr = Players:GetPlayerFromCharacter(runner)
    if not plr then
        warn(`Player not found for {runner.Name}`)
        return
    end

    local hrp = runner:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local origin = hrp.CFrame

    local hb = AbilityUtilities:CreateHitbox({
        SizeOrPart = CONFIG.HITBOX.SIZE,
        CFrame = origin
    })
    hb:Start()

    local hitSomething = false
    local stopped = false

    hb.HitSomeone:Connect(function(hitChars)
        for _, hitChar in ipairs(hitChars) do
            if stopped then return end
            if not AbilityUtilities:ValidateHit(runner, hitChar) then continue end

            if not hitSomething then
                AbilityUtilities:RagdollCharacter(runner, CONFIG.RAGDOLL_DURATION, true)
                VelocityUtilities.ApplyKnockback(origin, runner, CONFIG.KNOCKBACK.POWER, CONFIG.KNOCKBACK.DURATION)
                task.delay(CONFIG.RAGDOLL_DURATION, function()
                    runner:PivotTo(MapMarkers.Spawn.CFrame)
                end)
            end

            hitSomething = true

            hitChar.Parent = workspace

            AbilityUtilities:RagdollCharacter(hitChar, CONFIG.RAGDOLL_DURATION, true)
            VelocityUtilities.ApplyKnockback(origin, hitChar, CONFIG.KNOCKBACK.POWER, CONFIG.KNOCKBACK.DURATION)

            task.delay(CONFIG.RAGDOLL_DURATION, function()
                hitChar:PivotTo(MapMarkers.Spawn.CFrame)
            end)

            NotificationPacket.sendTo({Message = "You killed " .. hitChar.Name}, plr)
        end
    end)

    task.delay(0.2, function()
        stopped = true
        hb:Destroy()

        if not GameStarted.Value then return end

        if not hitSomething then
            AbilityUtilities:RagdollCharacter(runner, CONFIG.RAGDOLL_DURATION, true)
            VelocityUtilities.ApplyKnockback(origin, runner, CONFIG.KNOCKBACK.POWER, CONFIG.KNOCKBACK.DURATION)

            task.delay(CONFIG.RAGDOLL_DURATION, function()
                runner:PivotTo(MapMarkers.Spawn.CFrame)
            end)

            if self.lastBombHolder then
                local lastBombHolderPlr = Players:GetPlayerFromCharacter(self.lastBombHolder)
                if lastBombHolderPlr then
                    NotificationPacket.sendTo({Message = "You killed " .. runner.Name}, lastBombHolderPlr)
                end
            end
        end

        if not self:_CheckRoundEnd() then
            self:_TrySelectAndStartTagger()
        end
    end)

    self:_RemoveTaggerEffects(runner)
    runner:SetAttribute("Tagger", nil)
    runner.Parent = workspace
    self.tagger = nil
end

function RoundService:_OnRunnerDied(char: Model)
    if not GameStarted.Value then return end
    if char:GetAttribute("Exploding") then return end

    self:_RemoveTaggerEffects(char)
    char:SetAttribute("Tagger", nil)
    char.Parent = workspace

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = CONFIG.RUNNER_WALKSPEED
    end

    self:_SendRunnersLeft()
    self:_CheckRoundEnd()
end

function RoundService:_StartRoundTimer()
    self.timerVersion += 1
    local myVersion = self.timerVersion

    for i = CONFIG.ROUND_TIME, 0, -1 do
        if not GameStarted.Value then return end
        if self.timerVersion ~= myVersion then return end

        UnreliableUpdatePacket.sendToAll({Name = "Timer", Value = {uint16 = i}})

        if i == 0 then
            self:_ExplodeBomb()
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

    self:_TrySelectAndStartTagger()
end

function RoundService:_StartIntermission()
    for i = CONFIG.INTERMISSION_TIME, 0, -1 do
        if GameStarted.Value then return end

        UnreliableUpdatePacket.sendToAll({Name = "Timer", Value = {uint16 = i}})

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

function RoundService:_OnPlayerRemoving(plr: Player)
    local char = plr.Character
    if not char then return end

    if not GameStarted.Value then return end

    if char.Parent == workspace.Runners then
        if self.tagger == char then
            self:_RemoveTaggerEffects(char)
            char:SetAttribute("Tagger", nil)
            self.tagger = nil

            if self.currentConnection then
                self.currentConnection:Disconnect()
                self.currentConnection = nil
            end

            char.Parent = workspace

            if not self:_CheckRoundEnd() then
                self:_TrySelectAndStartTagger()
            end
        else
            char.Parent = workspace
            self:_SendRunnersLeft()
            self:_CheckRoundEnd()
        end
    end
end

function RoundService:Start()
    self:_SetupInitializeHandlers()
    self:_StartIntermission()

    local function onPlayerAdded(plr)
        plr.CharacterAdded:Connect(function(char)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            hum.WalkSpeed = CONFIG.RUNNER_WALKSPEED
        end)
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        onPlayerAdded(plr)
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(function(plr)
        self:_OnPlayerRemoving(plr)
    end)
end

return RoundService