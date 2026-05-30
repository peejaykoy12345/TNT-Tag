local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeVFX = require(ReplicatedStorage.Modules.Packages.ForgeVFX)

local module = {}

function module:Start(args)
    local parent = args.parent
    local vfx = args.vfx:Clone()
    local offset = args.offset
    local vfxCFrame = args.vfxCFrame
    local deletionTime = args.deletionTime or 2
    local shouldWeld = args.shouldWeld

    vfx.Parent = parent
    if vfx:IsA("BasePart") then
        if shouldWeld then
            vfx.CFrame = vfxCFrame or (offset and parent.CFrame * offset) or parent.CFrame

            local weld = Instance.new("Weld", parent)
            weld.Part0 = parent
            weld.Part1 = vfx

            if args.weldC1 then
                weld.C1 = args.weldC1
            end
        else
            if vfxCFrame then
                vfx.CFrame = vfxCFrame
            elseif offset then
                vfx.CFrame = parent.CFrame * offset
            end
        end
    elseif vfx:IsA("Model") then
        if shouldWeld then
            local primaryPart = vfx.PrimaryPart
            if not primaryPart then
                warn(`VFX {vfx.Name} shouldWeld is true but no primary part is set!`)
                return
            end

            local targetCFrame = vfxCFrame or (offset and parent.CFrame * offset) or parent.CFrame
            vfx:PivotTo(targetCFrame)

            local weld = Instance.new("Weld", vfx)
            weld.Part0 = parent
            weld.Part1 = primaryPart

            if args.weldC1 then
                weld.C1 = args.weldC1
            end
        else
            local targetCFrame
            if vfxCFrame then
                targetCFrame = vfxCFrame
            elseif offset then
                targetCFrame = parent.CFrame * offset
            end

            vfx:PivotTo(targetCFrame)
        end
    end

    ForgeVFX.emit(vfx)

    Debris:AddItem(vfx, deletionTime)
end

return module