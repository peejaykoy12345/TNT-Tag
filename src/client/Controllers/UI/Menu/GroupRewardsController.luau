local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarEditorService = game:GetService("AvatarEditorService")
local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage.Modules

local Network = require(Modules.Network)

local plr = Players.LocalPlayer
local MenuGui = plr:WaitForChild("PlayerGui"):WaitForChild("MenuGui"):WaitForChild("MiddleContainer")
local GroupRewardsMenu = MenuGui:WaitForChild("GroupRewardsMenu") :: Frame
local CloseButton = GroupRewardsMenu:WaitForChild("Header"):WaitForChild("CloseButton") :: ImageButton
local ClaimButton = GroupRewardsMenu:WaitForChild("ClaimButton") :: ImageButton

local CONFIG = {
    GROUP_ID = 769410750,
}

local GroupRewardsController = {}

function GroupRewardsController:Init()
    local permitted = false

    local ClaimHitbox = workspace:WaitForChild("RewardsArea"):WaitForChild("ClaimHitbox") :: Part
    ClaimHitbox.Touched:Connect(function(part)
        if part.Parent ~= plr.Character then return end
        GroupRewardsMenu.Visible = true
    end)

    CloseButton.Activated:Connect(function()
        GroupRewardsMenu.Visible = false
    end)

    ClaimButton.Activated:Connect(function()
        local groupSuccess, inGroup = pcall(function()
            return plr:IsInGroupAsync(CONFIG.GROUP_ID)
        end)

        if not groupSuccess or not inGroup then
            GroupService:PromptJoinAsync(plr, CONFIG.GROUP_ID)
            return
        end

        if not permitted then
            pcall(function()
                AvatarEditorService:PromptAllowInventoryReadAccess()
            end)
            permitted = AvatarEditorService.PromptAllowInventoryReadAccessCompleted:Wait()
        end

        if not permitted then
            pcall(function()
                AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
            end)
            return
        end

        local favoriteSuccess, isFavorited = pcall(function()
            return AvatarEditorService:GetFavoriteAsync(game.PlaceId, Enum.AvatarItemType.Asset)
        end)
        if not favoriteSuccess or not isFavorited then
            pcall(function()
                AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
            end)
            return
        end

        Network.Misc.packets.ClaimFreeGroupReward.send({})
    end)
end

return GroupRewardsController