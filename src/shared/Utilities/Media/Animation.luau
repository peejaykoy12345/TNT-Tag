local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animation = {}

local MAX_TRACKS_PER_CHARACTER = 50

local cachedTracks: {[Model]: {[string]: AnimationTrack}} = {}
local accessOrder: {[Model]: {string}} = {}

function Animation:_GetAnimator(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("No humanoid found")
		return nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return animator
end

function Animation:_GetAnimationId(AnimationInstanceOrId: number | Animation): string
	if typeof(AnimationInstanceOrId) == "Instance" and AnimationInstanceOrId:IsA("Animation") then
		return AnimationInstanceOrId.AnimationId:gsub("rbxassetid://", "")
	end
	return tostring(AnimationInstanceOrId)
end

function Animation:_SetupCleanup(character: Model)
	if cachedTracks[character] then return end

	cachedTracks[character] = {}
	accessOrder[character] = {}

	character.Destroying:Connect(function()
		local tracks = cachedTracks[character]
		if tracks then
			for _, track in pairs(tracks) do
				track:Stop()
				track:Destroy()
			end
		end
		cachedTracks[character] = nil
		accessOrder[character] = nil
	end)
end

function Animation:_TouchAccessOrder(character: Model, key: string)
	local order = accessOrder[character]
	if not order then return end

	for i, k in ipairs(order) do
		if k == key then
			table.remove(order, i)
			break
		end
	end

	table.insert(order, key)
end

function Animation:_EvictIfNeeded(character: Model)
	local order = accessOrder[character]
	local cache = cachedTracks[character]
	if not order or not cache then return end

	while #order >= MAX_TRACKS_PER_CHARACTER do
		local oldest = table.remove(order, 1)
		local track = cache[oldest]
		if track then
			track:Stop()
			track:Destroy()
			cache[oldest] = nil
		end
	end
end

function Animation:_LoadTrack(character: Model, AnimationInstanceOrId: number | Animation, playOptionsParams: {Priority: number}?)
	local animator = self:_GetAnimator(character)
	if not animator then return nil end

	self:_SetupCleanup(character)

	local key = self:_GetAnimationId(AnimationInstanceOrId)
	local characterCache = cachedTracks[character]

	if characterCache[key] then
		return characterCache[key]
	end

	local animation
	if typeof(AnimationInstanceOrId) == "Instance" and AnimationInstanceOrId:IsA("Animation") then
		animation = AnimationInstanceOrId
	else
		animation = ReplicatedStorage.Assets.Animations:FindFirstChild(key)
		if not animation then
			animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://" .. key
			animation.Name = key
			animation.Parent = ReplicatedStorage.Assets.Animations
		end
	end

	self:_EvictIfNeeded(character)

	local track = animator:LoadAnimation(animation)

	if playOptionsParams and playOptionsParams.Priority then
		track.Priority = Enum.AnimationPriority["Action" .. tostring(playOptionsParams.Priority)]
	end

	characterCache[key] = track
	self:_TouchAccessOrder(character, key)

	return track
end

function Animation:Play(character: Model, AnimationInstanceOrId: number | Animation, playOptionsParams: {Priority: number}?)
	local track = self:_LoadTrack(character, AnimationInstanceOrId, playOptionsParams)
	if not track then return end

	local key = self:_GetAnimationId(AnimationInstanceOrId)
	self:_TouchAccessOrder(character, key)

	track:Play()
	return track
end

function Animation:Stop(character: Model, AnimationInstanceOrId: number | Animation)
	local characterCache = cachedTracks[character]
	if not characterCache then return end

	local key = self:_GetAnimationId(AnimationInstanceOrId)
	local track = characterCache[key]
	if not track then return end

	track:Stop()
end

function Animation:StopAnimation(track: AnimationTrack)
	track:Stop()
end

function Animation:IsPlaying(character: Model, AnimationInstanceOrId: number | Animation): boolean
	local characterCache = cachedTracks[character]
	if not characterCache then return false end

	local key = self:_GetAnimationId(AnimationInstanceOrId)
	local track = characterCache[key]
	if not track then return false end

	return track.IsPlaying
end

function Animation:ClearCache(character: Model)
	local tracks = cachedTracks[character]
	if not tracks then return end

	for _, track in pairs(tracks) do
		track:Stop()
		track:Destroy()
	end

	cachedTracks[character] = nil
	accessOrder[character] = nil
end

return Animation