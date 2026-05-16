local Controllers = script.Parent.Controllers

for _, module in ipairs(Controllers:GetDescendants()) do
	if module:IsA("ModuleScript") then
		local controller = require(module)
		if controller.Init then
			controller:Init()
		end
	end
end

for _, module in ipairs(Controllers:GetDescendants()) do
	if module:IsA("ModuleScript") then
		local controller = require(module)
		if controller.Start then
			controller:Start()
		end
	end
end