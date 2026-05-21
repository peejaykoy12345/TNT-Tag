local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeVFX = require(ReplicatedStorage.Modules.Packages.ForgeVFX)

local module = {}

function module:Construct(args)
	self.parent = args.parent
	self.vfx = args.vfx:Clone()
	self.offset = args.offset
	self.deletionTime = args.deletionTime or 5

	self.vfx.Parent = self.parent

	if self.vfx:IsA("BasePart") and self.offset then
		self.vfx.CFrame = self.parent.CFrame * self.offset
	end
end

function module:Start(args)
	local vfxCFrame = args and args.vfxCFrame
	local shouldWeld = args and args.weld

	if self.vfx:IsA("BasePart") and vfxCFrame then
		self.vfx.CFrame = vfxCFrame
	end

	if shouldWeld and self.vfx:IsA("BasePart") then
		local weld = Instance.new("Weld")
		weld.Part0 = self.parent
		weld.Part1 = self.vfx

		weld.Parent = self.vfx
		if self.offset then
			weld.C1 = self.offset
		end
	end

	if self.vfx:IsA("Model") and vfxCFrame then
		if self.vfx.PrimaryPart then
			self.vfx:SetPrimaryPartCFrame(vfxCFrame)
			local weld = Instance.new("Weld")
			weld.Part0 = self.parent
			weld.Part1 = self.vfx.PrimaryPart
			weld.Parent = self.vfx
		else
			self.vfx:PivotTo(vfxCFrame)
		end
	end

	ForgeVFX.enable(self.vfx)
	Debris:AddItem(self.vfx, self.deletionTime)
end

function module:OnDestroy()
	if self.vfx and self.vfx.Parent then
		ForgeVFX.disable(self.vfx)
		self.vfx:Destroy()
	end
end

return module