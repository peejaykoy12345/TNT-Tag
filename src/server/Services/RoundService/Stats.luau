local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)
local RoundResultsPacket = Network.Misc.packets.RoundResults

local Stats = {}

local sessionStats: {[number]: {[string]: number }} = {}

function Stats:_InitPlayer(plr: Player)
    sessionStats[plr.UserId] = {
        Kills = 0,
        Coins = 0,
        Tags = 0,
        ["Round Survives"] = 0,
    }
end

function Stats:SendPacket(plr: Player)
	local stats = sessionStats[plr.UserId]
	if not stats then return end

	RoundResultsPacket.sendTo(stats, plr)
end

function Stats:RegisterPlayer(plr: Player)
	self:_InitPlayer(plr)
end

function Stats:UnregisterPlayer(plr: Player)
	sessionStats[plr.UserId] = nil
end

function Stats:Add(plr: Player, statName: string, value: number)
	local s = sessionStats[plr.UserId]
	if not s then return end
	s[statName] = (s[statName] or 0) + value
end

function Stats:GetStats(plr: Player): { [string]: number }?
	return sessionStats[plr.UserId]
end

function Stats:CompileOnDeath(plr: Player)
	self:SendPacket(plr)
	self:_InitPlayer(plr)
end

return Stats