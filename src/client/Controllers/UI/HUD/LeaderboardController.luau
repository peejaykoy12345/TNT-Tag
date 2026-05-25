local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Leaderboards = workspace.Leaderboards

local Network = require(ReplicatedStorage.Modules.Network)
local LeaderboardNamespace = Network.Leaderboard
local LeaderboardUpdate = LeaderboardNamespace.packets.LeaderboardUpdate
local GetLeaderboardData = LeaderboardNamespace.queries.GetLeaderboardData

local plr = Players.LocalPlayer

local CONFIG = {
	STATS = {
		"Tags",
        "RoundSurvives",
	},
}

local LeaderboardController = {}

function LeaderboardController:_UpdateText(TextLabel: TextLabel, text: string)
	TextLabel.Text = text

	local textLabelShadow = TextLabel:FindFirstChild(TextLabel.Name) :: TextLabel?
	if textLabelShadow then
		textLabelShadow.Text = text
	end
end

function LeaderboardController:_ClearLeaderboard(scrollFrame: ScrollingFrame)
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "BottomSpacer" and child.Name ~= "LeaderboardTemplate" then
			child:Destroy()
		end
	end
end

function LeaderboardController:_GetOrCreateEntry(scrollFrame: ScrollingFrame, rank: number): Frame?
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "LeaderboardTemplate" and child:GetAttribute("Rank") == rank then
			return child
		end
	end

	local template = scrollFrame:FindFirstChild("LeaderboardTemplate") :: Frame
	if not template then
		warn(`[LeaderboardController] LeaderboardTemplate not found in {scrollFrame:GetFullName()}`)
		return
	end

	local newEntry = template:Clone()
	newEntry.Name = "Entry_" .. tostring(rank)
	newEntry:SetAttribute("Rank", rank)
	newEntry.LayoutOrder = rank
	newEntry.Visible = true
	newEntry.Parent = scrollFrame

	return newEntry
end

function LeaderboardController:_UpdateLeaderboard(statName: string, entry)
	local leaderboard = Leaderboards:FindFirstChild(statName)
	if not leaderboard then
		warn(`[LeaderboardController] {tostring(statName)} not found in Leaderboards workspace folder`)
		return
	end

	local guiPart = leaderboard:FindFirstChild("LeaderboardGuiPart")
	if not guiPart then
		warn(`[LeaderboardController] LeaderboardGuiPart not found in {leaderboard:GetFullName()}`)
		return
	end

	local gui = guiPart:FindFirstChild("LeaderboardGui")
	if not gui then
		warn(`[LeaderboardController] LeaderboardGui not found in {guiPart:GetFullName()}`)
		return
	end

	local contentFrame = gui:FindFirstChild("ContentFrame")
	if not contentFrame then
		warn(`[LeaderboardController] ContentFrame not found in {gui:GetFullName()}`)
		return
	end

	local content = contentFrame:FindFirstChild("Content")
	if not content then
		warn(`[LeaderboardController] Content not found in {contentFrame:GetFullName()}`)
		return
	end

	local scrollFrame = content:FindFirstChild("ScrollingFrame")
	if not scrollFrame then
		warn(`[LeaderboardController] ScrollingFrame not found in {content:GetFullName()}`)
		return
	end

	local isCurrentPlayer = plr.UserId == entry.userId

	if isCurrentPlayer then
		local playerRankLabel = contentFrame:FindFirstChild("PlayerRank")
		if playerRankLabel then
			if entry.rank > 100 then
				playerRankLabel.Text = "Your rank: 100+"
			else
				playerRankLabel.Text = "Your rank: " .. tostring(entry.rank)
			end
		else
			warn(`[LeaderboardController] PlayerRank not found in {contentFrame:GetFullName()}`)
		end
	end

	if entry.rank > 100 then
		return
	end

	local frame = self:_GetOrCreateEntry(scrollFrame, entry.rank)
	if not frame then
		return
	end

	local infoFrame = frame:FindFirstChild("Info")
	if not infoFrame then
		warn(`[LeaderboardController] Info not found in entry frame for rank {entry.rank}`)
		return
	end

	self:_UpdateText(infoFrame.NameLabel, entry.username)
	self:_UpdateText(infoFrame.RankLabel, "#" .. tostring(entry.rank))
	self:_UpdateText(infoFrame.ValueLabel, entry.value)

	local playerImage = infoFrame:FindFirstChild("PlayerImage") :: ImageLabel
	if playerImage then
		local imageUrl = Players:GetUserThumbnailAsync(
			entry.userId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size420x420
		)
		playerImage.Image = imageUrl
	else
		warn(`[LeaderboardController] PlayerImage not found in Info for rank {entry.rank}`)
	end

	if isCurrentPlayer then
		frame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	end
end

function LeaderboardController:Init()
	LeaderboardUpdate.listen(function(data)
		self:_UpdateLeaderboard(data.statName, data)
	end)
end

function LeaderboardController:Start()
	task.spawn(function()
		for _, leaderboard in ipairs(Leaderboards:GetChildren()) do
			local guiPart = leaderboard:FindFirstChild("LeaderboardGuiPart")
			if not guiPart then
				warn(`[LeaderboardController] LeaderboardGuiPart not found in {leaderboard.Name}`)
				continue
			end
			local gui = guiPart:FindFirstChild("LeaderboardGui")
			if not gui then
				warn(`[LeaderboardController] LeaderboardGui not found in {guiPart:GetFullName()}`)
				continue
			end
			local contentFrame = gui:FindFirstChild("ContentFrame")
			if not contentFrame then
				warn(`[LeaderboardController] ContentFrame not found in {gui:GetFullName()}`)
				continue
			end
			local content = contentFrame:FindFirstChild("Content")
			if not content then
				warn(`[LeaderboardController] Content not found in {contentFrame:GetFullName()}`)
				continue
			end
			local scrollFrame = content:FindFirstChild("ScrollingFrame")
			if not scrollFrame then
				warn(`[LeaderboardController] ScrollingFrame not found in {content:GetFullName()}`)
				continue
			end
			self:_ClearLeaderboard(scrollFrame)
		end

		for _, statName in ipairs(CONFIG.STATS) do
			local data = GetLeaderboardData.invoke({ statName = statName })

			for _, entry in ipairs(data.entries) do
				self:_UpdateLeaderboard(entry.statName, entry)
			end

			local p = data.playerEntry
			if p.rank == 0 then
				local leaderboard = Leaderboards:FindFirstChild(p.statName)
				if leaderboard then
					local guiPart = leaderboard:FindFirstChild("LeaderboardGuiPart")
					local gui = guiPart and guiPart:FindFirstChild("LeaderboardGui")
					local contentFrame = gui and gui:FindFirstChild("ContentFrame")
					local playerRankLabel = contentFrame and contentFrame:FindFirstChild("PlayerRank")
					if playerRankLabel then
						playerRankLabel.Text = "Your rank: 100+"
					end
				end
			else
				self:_UpdateLeaderboard(p.statName, p)
			end
		end
	end)
end

return LeaderboardController