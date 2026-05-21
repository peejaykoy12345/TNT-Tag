local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local ClientFXPacket = require(Modules.Network).VFX.packets.ClientFXPacket
local SFXPackets = require(Modules.Network).SFX.packets

local ClientFX = {}

export type fxDataType = {
    Name: string,
    Type: string,
}

export type argsType = {
    parent: Instance?,
    vfx: Attachment? | BasePart?,
    vfxCFrame: CFrame?,
    position: Vector3,
    rocks: boolean?,
    isBeam: boolean?,
    offset: CFrame?,
    weld: boolean?,
    deletionTime: number?,
}

function ClientFX:GenerateId(): string
    return tostring(os.clock()):gsub("%.", "") .. tostring(math.random(1000, 9999))
end

function ClientFX:Construct(fxData: fxDataType, args: argsType?): string
    local handleId = self:GenerateId()
    ClientFXPacket.sendToAll({
        action = "Construct",
        handleId = handleId,
        fxData = fxData,
        args = args or {},
    })
    return handleId
end

function ClientFX:Start(handleId: string, args: argsType?)
    ClientFXPacket.sendToAll({
        action = "Start",
        handleId = handleId,
        args  = args or {},
    })
end

function ClientFX:Hit(handleId: string, args: argsType?)
    ClientFXPacket.sendToAll({
        action = "Hit",
        handleId = handleId,
        args = args or {},
    })
end

function ClientFX:Destroy(handleId: string)
    ClientFXPacket.sendToAll({
        action = "Destroy",
        handleId = handleId,
        args = {},
    })
end

function ClientFX:RenderToClient(fxData: fxDataType, args: argsType)
    assert(args.position, "Position is needed")
    ClientFXPacket.sendToAll({
        action = "Render",
        fxData = fxData,
        args = args,
    })
end

function ClientFX:PlaySFX(parent: Instance, soundInstanceORId: number | Sound): string
    local handleId = self:GenerateId()
    SFXPackets.PlaySFX.sendToAll({
        handleId = handleId,
        Parent = parent,
        SoundId = typeof(soundInstanceORId) == "number" and soundInstanceORId or nil,
        SoundInstance = typeof(soundInstanceORId) == "Instance" and soundInstanceORId or nil,
    })
    return handleId
end

function ClientFX:StopSFX(handleId: string)
    SFXPackets.StopSFX.sendToAll({
        handleId = handleId,
    })
end

return ClientFX