local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerPackages = ServerScriptService.ServerPackages
local ProfileStore = require(ServerPackages.ProfileStore)

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

local PlayerStore = ProfileStore.New("PlayerData_V6", PROFILE_TEMPLATE)
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
end

return module