local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local plr = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CONFIG = {
	OffsetOn = Vector3.new(1.75, 0, 0),
	OffsetOff = Vector3.zero,
	TweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	RenderName = "ShiftLockAlign",
	RotResponsiveness = 18,
	CrosshairImage = "rbxasset://textures/MouseLockedCursor.png",
	CrosshairSize = UDim2.fromOffset(32, 32),
}

local ShiftLockController = {}

local enabled = false
local currentTween = nil
local humanoid = nil
local root = nil
local crosshairGui = nil

local function createCrosshairGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShiftLockCrosshair"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10

	local crosshair = Instance.new("ImageLabel")
	crosshair.Name = "Crosshair"
	crosshair.Image = CONFIG.CrosshairImage
	crosshair.Size = CONFIG.CrosshairSize
	crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
	crosshair.Position = UDim2.fromScale(0.5, 0.5)
	crosshair.BackgroundTransparency = 1
	crosshair.Parent = screenGui

	screenGui.Parent = plr.PlayerGui
	return screenGui
end

function ShiftLockController:IsEnabled()
	return enabled
end

function ShiftLockController:_IsServerLocked()
	return humanoid and humanoid:GetAttribute("ServerHumanoidAutoRotateLock") == true
end

function ShiftLockController:_StopTween()
	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end
end

function ShiftLockController:_TweenOffset(target)
	self:_StopTween()
	if not humanoid then return end
	currentTween = TweenService:Create(humanoid, CONFIG.TweenInfo, { CameraOffset = target })
	currentTween:Play()
end

function ShiftLockController:_StopRender()
	RunService:UnbindFromRenderStep(CONFIG.RenderName)
end

function ShiftLockController:_StartRender()
	RunService:BindToRenderStep(CONFIG.RenderName, Enum.RenderPriority.Character.Value, function()
		if not root or not root.Parent or not humanoid or humanoid.Health <= 0 then return end
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.atan2(-camera.CFrame.LookVector.X, -camera.CFrame.LookVector.Z), 0)
	end)
end

function ShiftLockController:_SetCrosshairVisible(visible)
	if visible then
		if not crosshairGui or not crosshairGui.Parent then
			crosshairGui = createCrosshairGui()
		end
		crosshairGui.Enabled = true
	else
		if crosshairGui then
			crosshairGui.Enabled = false
		end
	end
end

function ShiftLockController:_BindCharacter(character)
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
	if enabled then
		self:_TweenOffset(CONFIG.OffsetOn)
		self:_StartRender()
		self:_SetCrosshairVisible(true)
	end
end

function ShiftLockController:_UnbindCharacter()
	self:_StopRender()
	self:_StopTween()
	humanoid = nil
	root = nil
end

function ShiftLockController:Toggle()
	enabled = not enabled
	if enabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		self:_TweenOffset(CONFIG.OffsetOn)
		self:_StartRender()
		self:_SetCrosshairVisible(true)
		if not self:_IsServerLocked() then
			humanoid.AutoRotate = false
		end
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		self:_TweenOffset(CONFIG.OffsetOff)
		self:_StopRender()
		self:_SetCrosshairVisible(false)
		if not self:_IsServerLocked() then
			humanoid.AutoRotate = true
		end
	end
end

function ShiftLockController:Init()
	if plr.Character then
		self:_BindCharacter(plr.Character)
	end
	plr.CharacterAdded:Connect(function(character)
		self:_BindCharacter(character)
	end)
	plr.CharacterRemoving:Connect(function()
		self:_UnbindCharacter()
	end)
end

return ShiftLockController