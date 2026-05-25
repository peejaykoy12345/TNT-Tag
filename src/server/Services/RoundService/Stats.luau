local Stats = {}

local sessionStats: { [number]: { [string]: number } } = {}

function Stats:_InitPlayer(plr: Player)
    sessionStats[plr.UserId] = {
        Kills = 0,
        Coins = 0,
        Tags = 0,
        RoundSurvives = 0,
    }
end

function Stats:PrintStats(plr: Player)
	local stats = sessionStats[plr.UserId]
	if not stats then return end

	local lines = { string.format("\n===== Round Stats: %s =====", plr.Name) }
	for stat, value in stats do
		table.insert(lines, string.format("  %s : %d", stat, value))
	end
	table.insert(lines, "================================")
	print(table.concat(lines, "\n"))
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
	self:PrintStats(plr)
	self:_InitPlayer(plr)
end

return Stats