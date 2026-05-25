local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ServerPackages = ServerScriptService.ServerPackages
local ProfileStore = require(ServerPackages.ProfileStore)

local Network = require(ReplicatedStorage.Modules.Network)
local UpdatePacket = Network.Replication.packets.Update

export type ProfileData = {
	Coins: number,
	Tags: number,
	RoundSurvives: number,
	Flags: {
		ClaimedFreeGroupReward: boolean,
	},
	Inventory: {
        Equipped: {
            Abilities: string,
            Bombs: string,
            Auras: string,
        },
        Owned: {
            Abilities: {string},
            Bombs: {string},
            Auras: {string},
        },
    },
}

local PROFILE_TEMPLATE: ProfileData = {
	Coins = 100,
	Tags = 0,
	RoundSurvives = 0,
	Flags = {
		ClaimedFreeGroupReward = false,
	},
	Inventory = {
        Equipped = {
            Abilities = "Default",
            Bombs = "Default",
            Auras = "Default",
        },
        Owned = {
            Abilities = {"Default"},
            Bombs = {"Default"},
            Auras = {"Default", "Green Fire"}
        }
    },
}

local CONFIG = {
	DATA_TO_REPLICATE = {
		Coins = {
			DATA_TYPE = "uint32"
		}
	}
}

local PlayerStore = ProfileStore.New("PlayerData_V7", PROFILE_TEMPLATE)
local Profiles: {[Player]: typeof(PlayerStore:StartSessionAsync())} = {}
local module = {}

local function setupPlayer(player, profile)
	
end

local function PlayerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			player:Kick("Profile session end - Please rejoin")
		end)
		if player.Parent == Players then
			Profiles[player] = profile
			setupPlayer(player, profile)
		else
			profile:EndSession()
		end
	else
		player:Kick("Profile load fail - Please rejoin")
	end
end

local function PlayerRemoving(player: Player)
	local profile = Profiles[player]
	if not profile then return end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats:Destroy()
	end
	profile:EndSession()
end

for _, player in Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end

function module:Init()
	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(PlayerRemoving)
end

function module:GetProfile(plr: Player)
	local profile = Profiles[plr]
	if profile then return profile end
	local elapsed = 0
	while not Profiles[plr] and elapsed < 1.5 do
		task.wait(0.1)
		elapsed += 0.1
	end
	return Profiles[plr]
end

function module:GetData(plr: Player, dataName: string): any
	local profile = module:GetProfile(plr)
	if not profile then return nil end

	return profile.Data[dataName]
end

function module:SetData(plr: Player, dataName: string, value: any)
	local profile = module:GetProfile(plr)
	if not profile then return end

	profile.Data[dataName] = value
end

function module:IncrementData(plr: Player, dataName: string, value: number)
	local profile = module:GetProfile(plr)
	if not profile then return end

	profile.Data[dataName] += value

	if CONFIG.DATA_TO_REPLICATE[dataName] then
		local Value = {}
		
		Value[CONFIG.DATA_TO_REPLICATE[dataName].DATA_TYPE] = profile.Data[dataName]
		UpdatePacket.sendTo({Name = dataName, Value = Value}, plr)
	end
end

return module