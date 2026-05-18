local UserInputService = game:GetService("UserInputService")
local _ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local plr = Players.LocalPlayer
local HudGui = plr:WaitForChild("PlayerGui"):WaitForChild("HudGui")
local AbilityButton = HudGui:WaitForChild("BottomContainer"):WaitForChild("AbilityButton") :: ImageButton
local ShiftLockButton = HudGui:WaitForChild("BottomContainer"):WaitForChild("ShiftLockButton") :: ImageButton

local ExtendedTouchGUI = plr:WaitForChild("PlayerGui"):WaitForChild("ExtendedTouchGui")
local Controls = ExtendedTouchGUI:WaitForChild("Controls") :: Frame
local AbilityButtonMobile = Controls:WaitForChild("AbilityButton") :: ImageButton
local ShiftLockButtonMobile = Controls:WaitForChild("ShiftLockButton") :: ImageButton

local Controllers = script.Parent.Parent.Parent
local AbilityController = require(Controllers.AbilityController)
local ShiftlockController = require(Controllers.ShiftlockController)

local DeviceController = {}

function DeviceController:_ChangeControlForButton(btn: ImageButton, control: string)
    local bindingLabel = btn:FindFirstChild("BindingLabel") :: TextLabel

    bindingLabel.Text = `[{control}]`
end

function DeviceController:Init()
	if UserInputService.TouchEnabled then
		Controls.Visible = true
        AbilityButton.Visible = false
        ShiftLockButton.Visible = false

        AbilityButtonMobile.Activated:Connect(function()
            AbilityController:FirePerformPacket()
        end)

        ShiftLockButtonMobile.Activated:Connect(function()
            ShiftlockController:Toggle()
        end)
	elseif UserInputService.GamepadEnabled then
		self:_ChangeControlForButton(AbilityButton, "L1")
        self:_ChangeControlForButton(ShiftLockButton, "L3")

        UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
            if gameProcessedEvent then return end

            if input.KeyCode == Enum.KeyCode.ButtonL1 then
                AbilityController:FirePerformPacket()
            end

            if input.KeyCode == Enum.KeyCode.ButtonL3 then
                ShiftlockController:Toggle()
            end
        end)
	else
		self:_ChangeControlForButton(AbilityButton, "Q")
        self:_ChangeControlForButton(ShiftLockButton, "Shift")

        UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
            if gameProcessedEvent then return end

            if input.KeyCode == Enum.KeyCode.LeftShift then
                ShiftlockController:Toggle()
            end

            if input.KeyCode == Enum.KeyCode.Q then
                AbilityController:FirePerformPacket()
            end
        end)
	end
end

return DeviceController