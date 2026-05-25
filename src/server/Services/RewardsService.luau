local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Profiles = require(ServerScriptService.Services.Profiles)

local Modules = ReplicatedStorage.Modules
local Network = require(Modules.Network)
local NotificationPacket = Network.General.packets.Notification

local CONFIG = {
    GROUP_ID = 769410750,
    COIN_TO_BE_GIVEN_FOR_GROUP_REWARD = 100,
}

local RewardsService = {}

function RewardsService:Init()
    Network.Misc.packets.ClaimFreeGroupReward.listen(function(data, plr)
        local profile = Profiles:GetProfile(plr)
        if not profile then return end

        local success, inGroup = pcall(function()
            return plr:IsInGroupAsync(CONFIG.GROUP_ID)
        end)

        if not success or not inGroup then return end
        if profile.Data.Flags.ClaimedFreeGroupReward then 
            NotificationPacket.sendTo({Message = "You already claimed this reward!"}, plr)
            return 
        end

        profile.Data.Coins += CONFIG.COIN_TO_BE_GIVEN_FOR_GROUP_REWARD
        profile.Data.Flags.ClaimedFreeGroupReward = true

        NotificationPacket.sendTo({Message = "Successfully claimed reward"}, plr)
        
        Network.Replication.packets.Update.sendTo({Name = "Coins", Value = {uint32 = profile.Data.Coins}}, plr)
    end)
end

return RewardsService