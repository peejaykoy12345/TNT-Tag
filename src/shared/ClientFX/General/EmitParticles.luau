local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeVFX = require(ReplicatedStorage.Modules.Packages.ForgeVFX)

local module = {}

function module:Start(args)
	local parent = args.parent
	local vfx = args.vfx:Clone()
	local offset = args.offset
	local vfxCFrame = args.vfxCFrame
	local shake = args.shake
	local pos = args.position
	local rocks = args.rocks
	local deletionTime = args.deletionTime or 5

	vfx.Parent = parent
  
	if vfx:IsA("BasePart") and offset then
		vfx.CFrame = parent.CFrame * offset
	end

	if vfx:IsA("BasePart") and vfxCFrame then
		vfx.CFrame = vfxCFrame
	end
	
	if vfx:IsA("Model") and vfxCFrame then
		
		if vfx.PrimaryPart then
			vfx:SetPrimaryPartCFrame(vfxCFrame)
			local weld = Instance.new("Weld")
			weld.Part0 = parent
			weld.Part1 = vfx.PrimaryPart
			weld.Parent = vfx
		else
			vfx:PivotTo(vfxCFrame)
		end
	end

	ForgeVFX.emit(vfx)
	Debris:AddItem(vfx, deletionTime)
end

return module