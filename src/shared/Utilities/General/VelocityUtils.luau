local Debris = game:GetService("Debris")

local Velocity = {}

export type BodyVelocityParams = {
	Velocity: Vector3,
	MaxForce: Vector3?,
	Lifetime: number?,
}

function Velocity.CreateBodyVelocity(parent: Instance, params: BodyVelocityParams): BodyVelocity
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = params.MaxForce or Vector3.new(9999999, 9999999, 99999999)
	bv.Velocity = params.Velocity or Vector3.new(0, 0, 0)
	bv.Parent = parent

	local lifetime = params.Lifetime or .2
	Debris:AddItem(bv, lifetime)

	return bv
end

function Velocity.ApplyKnockback(origin: Vector3 | CFrame, target: Model, knockback: number, duration: number)
	local ehrp = target:FindFirstChild("HumanoidRootPart") :: BasePart
	local hum = target:FindFirstChild("Humanoid") :: Humanoid

	if not ehrp or not hum then
		warn("ApplyKnockback: Missing HumanoidRootPart or Humanoid | target HRP:", ehrp ~= nil, "| target Humanoid:", hum ~= nil)
		return
	end

	local originPosition = typeof(origin) == "CFrame" and origin.Position or origin
	local direction = (ehrp.Position - originPosition)
	if direction.Magnitude < 0.001 then
		direction = Vector3.new(0, 0, 1)
	else
		direction = direction.Unit
	end

	hum.AutoRotate = false
	hum:SetAttribute("ServerHumanoidAutoRotateLock", true)

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(50000, 50000, 50000)
	bodyVelocity.Velocity = direction * knockback
	bodyVelocity.Parent = ehrp

	task.delay(duration, function()
		if bodyVelocity then
			bodyVelocity:Destroy()
		end

		hum:SetAttribute("ServerHumanoidAutoRotateLock", nil)
		hum.AutoRotate = true
	end)
end

return Velocity