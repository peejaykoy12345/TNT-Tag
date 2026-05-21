local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local plr = Players.LocalPlayer

local CONFIG = {
	TILT_ANGLE = 7,
	LERP_SPEED = 0.2,
}

local TiltController = {}

function TiltController:Init()
	local lateralDot = 0

	RunService.RenderStepped:Connect(function()
		local char = plr.Character
		if not char then return end

		local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
		local torso = char:FindFirstChild("Torso")
		if not humanoidRootPart or not torso then return end

		local rootJoint = humanoidRootPart:FindFirstChild("RootJoint")
		local leftShoulder = torso:FindFirstChild("Left Shoulder")
		local rightShoulder = torso:FindFirstChild("Right Shoulder")
		if not rootJoint or not leftShoulder or not rightShoulder then return end

		local force = humanoidRootPart.Velocity * Vector3.new(1, 0, 1)

		if force.Magnitude > 2 and not char:GetAttribute("Cutscene") then
			lateralDot = humanoidRootPart.CFrame.RightVector:Dot(force.Unit)
		else
			lateralDot = 0
		end

		local rootC0 = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
		local leftC0 = CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
		local rightC0 = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)

		rootJoint.C0 = rootJoint.C0:Lerp(rootC0 * CFrame.Angles(0, math.rad(-lateralDot * CONFIG.TILT_ANGLE), 0), CONFIG.LERP_SPEED)
		leftShoulder.C0 = leftShoulder.C0:Lerp(leftC0 * CFrame.Angles(0, 0, math.rad(-lateralDot * CONFIG.TILT_ANGLE)), CONFIG.LERP_SPEED)
		rightShoulder.C0 = rightShoulder.C0:Lerp(rightC0 * CFrame.Angles(0, 0, math.rad(lateralDot * CONFIG.TILT_ANGLE)), CONFIG.LERP_SPEED)
	end)
end

return TiltController