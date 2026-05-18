local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utilities = ReplicatedStorage.Modules.Utilities
local GeneralUtilities = Utilities.General

local Cooldown = require(GeneralUtilities.Cooldown)
local HitboxClass = require(GeneralUtilities.HitboxClass)

local AbilityUtilities = {}

function AbilityUtilities:CanPerformAction(char: Model, actionName: string): boolean
    if Cooldown:IsOnCooldown(char, actionName) then
		return false
	end

    return true
end

function AbilityUtilities:ValidateHit(attacker: Model, target: Model): boolean
	if attacker == target then return false end

    local targetHum = target:FindFirstChildOfClass("Humanoid")
    if not targetHum then return false end

    if targetHum.Health <= 0 then
        return false
    end

    return true
end

export type CreateHitboxConfig = {
	SizeOrPart: Vector3 | BasePart?,
	CFrame: CFrame?,
	Debug: boolean?,
	UseClient: Player?,
	WeldedPart: Part?,
	WeldOffsetCFrame: CFrame?, 
	DebounceTime: number?,
	VelocityPredictionFactor: number?,
	VelocityPrediction: boolean?,
}

function AbilityUtilities:CreateHitbox(custom_config: CreateHitboxConfig)
	local config = {
		SizeOrPart = custom_config.SizeOrPart or Vector3.new(4, 4, 4),
		UseClient = custom_config.UseClient,
		DebounceTime = custom_config.DebounceTime,
		Debug = custom_config.Debug ~= false,
		VelocityPredictionFactor = custom_config.VelocityPredictionFactor,
		VelocityPrediction = custom_config.VelocityPrediction,
	}

	local hitbox = HitboxClass.new(config)
	if custom_config.CFrame then 
		print(hitbox.Position, " initial")
		print("CFRAME: ",custom_config.CFrame )
		hitbox:SetPosition(custom_config.CFrame)
		print(hitbox.Position, " after")
	end

	if custom_config.WeldedPart then
		hitbox:WeldTo(custom_config.WeldedPart, custom_config.WeldOffsetCFrame or CFrame.new(0, 0, 0))
	end

	return hitbox
end

return AbilityUtilities