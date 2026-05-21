local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientFXPacket = require(ReplicatedStorage.Modules.Network).VFX.packets.ClientFXPacket
local ClientFX = ReplicatedStorage.Modules.ClientFX

local handles: {[string]: { effect: any, fxData: any }} = {}

local ClientFXController = {}

local function resolveModule(fxData)
	local typeFolder = ClientFX:FindFirstChild(fxData.Type)
	if not typeFolder then
		warn("ClientFXController: unknown type folder: " .. tostring(fxData.Type))
		return nil
	end
	local moduleScript = typeFolder:FindFirstChild(fxData.Name)
	if not moduleScript then
		warn("ClientFXController: module not found: " .. tostring(fxData.Name))
		return nil
	end
	return require(moduleScript)
end

local actions = {}

function actions.Construct(data)
	local fxModule = resolveModule(data.fxData)
	if not fxModule then return end

	local instance = setmetatable({}, { __index = fxModule })
	if instance.Construct then
		instance:Construct(data.args)
	end

	handles[data.handleId] = { effect = instance, fxData = data.fxData }
end
function actions.Start(data)
	local handle = handles[data.handleId]
	if not handle then
		warn("ClientFXController: Start called on unknown handle: " .. data.handleId)
		return
	end
	if handle.effect.Start then
		handle.effect:Start(data.args)
	end
end

function actions.Hit(data)
	local handle = handles[data.handleId]
	if not handle then
		warn("ClientFXController: Hit called on unknown handle: " .. data.handleId)
		return
	end
	if handle.effect.Hit then
		handle.effect:Hit(data.args)
	end
end

function actions.Destroy(data)
	local handle = handles[data.handleId]
	if not handle then return end
	if handle.effect.OnDestroy then
		handle.effect:OnDestroy()
	end
	handles[data.handleId] = nil
end

function actions.Render(data)
	local fxModule = resolveModule(data.fxData)
	if not fxModule then return end
	local instance = setmetatable({}, { __index = fxModule })
	if instance.Start then
		instance:Start(data.args)
	end
end

function ClientFXController:Init()
	require(ReplicatedStorage.Modules.Utilities.Media.ForgeVFX).init()
end

function ClientFXController:Start()
	ClientFXPacket.listen(function(data)
		local handler = actions[data.action]
		if handler then
			handler(data)
		else
			warn("ClientFXController: unknown action: " .. tostring(data.action))
		end
	end)
end

return ClientFXController