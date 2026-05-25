local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")

local Profiles = require(ServerScriptService.Services.Profiles)

local Network = require(ReplicatedStorage.Modules.Network)
local LeaderboardNamespace = Network.Leaderboard
local LeaderboardUpdate = LeaderboardNamespace.packets.LeaderboardUpdate
local GetLeaderboardData = LeaderboardNamespace.queries.GetLeaderboardData

local CONFIG = {
	PAGE_SIZE = 100,
	UPDATE_INTERVAL = 60,
	MS_TOPIC = "LeaderboardUpdate",
	LEADERBOARDS = {
		Tags = {
			OrderedDataStoreName = "Leaderboard_Tags_V1",
			DisplayName = "Tags",
		},
	},
}

local LeaderboardService = {}
LeaderboardService._stores = {}

function LeaderboardService:_GetStore(statName: string)
	if self._stores[statName] then
		return self._stores[statName]
	end

	local config = CONFIG.LEADERBOARDS[statName]
	if not config then
		warn(`[LeaderboardService] Unknown stat: "{statName}"`)
		return nil
	end

	local store = DataStoreService:GetOrderedDataStore(config.OrderedDataStoreName)
	self._stores[statName] = store
	return store
end

function LeaderboardService:_SubmitScore(plr: Player, statName: string, value: number)
	if value <= 0 then return end

	local store = self:_GetStore(statName)
	if not store then
		warn(`[LeaderboardService] _SubmitScore: no store for "{statName}"`)
		return
	end

	local success, err = pcall(function()
		store:SetAsync(tostring(plr.UserId), value)
	end)

	if not success then
		warn(`[LeaderboardService] Failed to submit {statName} for {plr.Name}: {err}`)
	end
end

function LeaderboardService:_SubmitAllStats(plr: Player)
	for statName in pairs(CONFIG.LEADERBOARDS) do
		local value = Profiles:GetData(plr, statName)
		if type(value) == "number" then
			self:_SubmitScore(plr, statName, value)
		end
	end
end

function LeaderboardService:_BroadcastUpdate(plr: Player)
	local payload = { userId = plr.UserId, stats = {} }

	for statName in pairs(CONFIG.LEADERBOARDS) do
		local value = Profiles:GetData(plr, statName)
		if type(value) == "number" then
			payload.stats[statName] = value
		end
	end

	local success, err = pcall(function()
		MessagingService:PublishAsync(CONFIG.MS_TOPIC, payload)
	end)

	if not success then
		warn(`[LeaderboardService] Failed to broadcast update for {plr.Name}: {err}`)
	end
end

function LeaderboardService:_HandleRemoteUpdate(payload: { userId: number, stats: { [string]: number } })
	for statName, value in pairs(payload.stats) do
		local store = self:_GetStore(statName)
		if not store then
			warn(`[LeaderboardService] _HandleRemoteUpdate: no store for "{statName}"`)
			continue
		end

		local success, err = pcall(function()
			store:SetAsync(tostring(payload.userId), value)
		end)

		if not success then
			warn(`[LeaderboardService] Failed to apply remote update for userId {payload.userId} stat {statName}: {err}`)
			continue
		end

		local username = "[Unknown]"
		local nameSuccess, name = pcall(function()
			return Players:GetNameFromUserIdAsync(payload.userId)
		end)
		if nameSuccess then
			username = name
		end

		local entries = self:FetchLeaderboard(statName)
		local rank = 0
		for _, entry in ipairs(entries) do
			if entry.userId == payload.userId then
				rank = entry.rank
				break
			end
		end

		LeaderboardUpdate.sendToAll({
			rank = rank,
			userId = payload.userId,
			value = value,
			username = username,
			statName = statName,
		})
	end
end

function LeaderboardService:_StartPeriodicSync()
	task.spawn(function()
		while true do
			task.wait(CONFIG.UPDATE_INTERVAL)
			for _, plr in ipairs(Players:GetPlayers()) do
				self:_SubmitAllStats(plr)
			end
		end
	end)
end

function LeaderboardService:FetchLeaderboard(statName: string)
	local topN = CONFIG.PAGE_SIZE

	local store = self:_GetStore(statName)
	if not store then
		warn(`[LeaderboardService] FetchLeaderboard: no store for "{statName}"`)
		return {}
	end

	local pages
	local success, err = pcall(function()
		pages = store:GetSortedAsync(false, topN)
	end)

	if not success then
		warn(`[LeaderboardService] Failed to fetch leaderboard for {statName}: {err}`)
		return {}
	end

	local results = {}
	for rank, entry in ipairs(pages:GetCurrentPage()) do
		table.insert(results, {
			rank = rank,
			userId = tonumber(entry.key),
			value = entry.value,
		})
	end

	return results
end

function LeaderboardService:FetchPlayerRank(plr: Player, statName: string)
	local store = self:_GetStore(statName)
	if not store then
		warn(`[LeaderboardService] FetchPlayerRank: no store for "{statName}"`)
		return nil
	end

	local pages
	local success, err = pcall(function()
		pages = store:GetSortedAsync(false, CONFIG.PAGE_SIZE)
	end)

	if not success then
		warn(`[LeaderboardService] FetchPlayerRank failed for {statName}: {err}`)
		return nil
	end

	local userIdStr = tostring(plr.UserId)
	for rank, entry in ipairs(pages:GetCurrentPage()) do
		if entry.key == userIdStr then
			return { rank = rank, value = entry.value }
		end
	end

	return nil
end

function LeaderboardService:NotifyUpdate(plr: Player)
	if not plr then
		warn("[LeaderboardService] NotifyUpdate: no player provided")
		return
	end

	self:_SubmitAllStats(plr)
	self:_BroadcastUpdate(plr)
end

function LeaderboardService:Init()
	for statName in pairs(CONFIG.LEADERBOARDS) do
		self:_GetStore(statName)
	end
end

function LeaderboardService:Start()
	local success, err = pcall(function()
		MessagingService:SubscribeAsync(CONFIG.MS_TOPIC, function(message)
			self:_HandleRemoteUpdate(message.Data)
		end)
	end)

	if not success then
		warn(`[LeaderboardService] Failed to subscribe to MessagingService: {err}`)
	end

	Players.PlayerRemoving:Connect(function(plr)
		self:_SubmitAllStats(plr)
		self:_BroadcastUpdate(plr)
	end)

	Players.PlayerAdded:Connect(function(plr)
		task.delay(2, function()
			if plr.Parent ~= Players then return end
			self:_SubmitAllStats(plr)
		end)
	end)

	GetLeaderboardData.listen(function(request, plr)
        local statName = request.statName
        local entries = self:FetchLeaderboard(statName)

        local resolvedEntries = {}
        for _, entry in ipairs(entries) do
            local username = "[Unknown]"
            local nameSuccess, name = pcall(function()
                return Players:GetNameFromUserIdAsync(entry.userId)
            end)
            if nameSuccess then
                username = name
            end

            table.insert(resolvedEntries, {
                rank = entry.rank,
                userId = entry.userId,
                value = entry.value,
                username = username,
                statName = statName,
            })
        end

        local playerRankData = self:FetchPlayerRank(plr, statName)
        local playerEntry = {
            rank = playerRankData and playerRankData.rank or 0,
            userId = plr.UserId,
            value = playerRankData and playerRankData.value or 0,
            username = plr.Name,
            statName = statName,
        }

        return {
            entries = resolvedEntries,
            playerEntry = playerEntry,
        }
    end)

	self:_StartPeriodicSync()
end

return LeaderboardService