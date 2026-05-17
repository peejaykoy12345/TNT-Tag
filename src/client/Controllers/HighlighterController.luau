local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Values = ReplicatedStorage.Values
local GameStarted: BoolValue = Values.GameStarted

local plr = Players.LocalPlayer

local HighlighterController = {}

function HighlighterController:_ApplyHighlights()
    local char = plr.Character
    if not char then return end

    for _, runner in ipairs(workspace.Runners:GetChildren()) do
        if runner == char then continue end

        local existing = runner:FindFirstChild("RunnerHighlight")
        if existing then continue end

        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(0, 120, 255)
        highlight.OutlineColor = Color3.fromRGB(0, 120, 255)
        highlight.FillTransparency = 1
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Name = "RunnerHighlight"
        highlight.Parent = runner
    end
end

function HighlighterController:_RemoveHighlights()
    for _, runner in ipairs(workspace.Runners:GetChildren()) do
        local highlight = runner:FindFirstChild("RunnerHighlight")
        if highlight then
            highlight:Destroy()
        end
    end
end

function HighlighterController:_Check()
    local char = plr.Character
    if not char then return end

    local isTagger = char:GetAttribute("Tagger") == true

    if GameStarted.Value and isTagger then
        self:_ApplyHighlights()
    else
        self:_RemoveHighlights()
    end
end

function HighlighterController:Init()
    local char = plr.Character or plr.CharacterAdded:Wait()

    char.AttributeChanged:Connect(function(attr)
        if attr ~= "Tagger" then return end
        self:_Check()
    end)

    plr.CharacterAdded:Connect(function(newChar)
        newChar.AttributeChanged:Connect(function(attr)
            if attr ~= "Tagger" then return end
            self:_Check()
        end)

        self:_Check()
    end)

    GameStarted.Changed:Connect(function()
        self:_Check()
    end)

    self:_Check()
end

return HighlighterController