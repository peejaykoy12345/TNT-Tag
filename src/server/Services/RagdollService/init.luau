local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local module = require(script.ModuleScript)
local ragParts = script.RagdollParts:GetChildren()
local r6Client = script.R6RagdollClient

local setReg = {}

PhysicsService:RegisterCollisionGroup("Ragdoll")

local RagdollService = {}

function RagdollService:_Setup(char)
    if setReg[char] then return end
	setReg[char] = true
	
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end
	if char:FindFirstChild("Head") then
		char.Head.Size = Vector3.new(1, 1, 1)
	end
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false

	local clones = {}
	for _, v in ipairs(ragParts) do
		clones[v.Name] = v:Clone()
	end

	local folder1 = Instance.new("Folder")
	folder1.Name = "RagdollConstraints"
	for _, v in pairs(clones) do
		if v:IsA("Attachment") then
			v.Parent = char[v:GetAttribute("Parent")]
		elseif v:IsA("BallSocketConstraint") then
			v.Attachment0 = clones[v:GetAttribute("0")]
			v.Attachment1 = clones[v:GetAttribute("1")]
			v.Parent = folder1
		end
	end
	folder1.Parent = char

	local folder2 = Instance.new("Folder")
	folder2.Name = "Motors"
	local value
	for _, v in ipairs(char.Torso:GetChildren()) do
		if v:IsA("Motor6D") then
			value = Instance.new("ObjectValue")
			value.Value = v
			value.Parent = folder2
		end
	end
	folder2.Parent = folder1

	local trigger = Instance.new("BoolValue")
	trigger.Name = "RagdollTrigger"
	trigger.Parent = char

	trigger.Changed:Connect(function(bool)
		if bool then
			module:Ragdoll(char)
		else
			module:Unragdoll(char)
		end
	end)

	r6Client:Clone().Parent = char
end

function RagdollService:Init()
    Players.PlayerRemoving:Connect(function(player)
        local char = player.Character
        if char then
            setReg[char] = nil
        end
    end)

    for _, v in pairs(workspace.LivingBeings:GetChildren()) do
        RagdollService:_Setup(v)
    end
end

return RagdollService

