local Services = game:GetService("ServerScriptService").Services

for _, module in ipairs(Services:GetDescendants()) do
	if module:IsA("ModuleScript") then
		local service = require(module)
		if service.Init then
			--[[local ok, err = pcall(function() service:Init() end)
			if not ok then
				warn(err)
			end]]
			service:Init()
		end
	end
end

for _, module in ipairs(Services:GetDescendants()) do
	if module:IsA("ModuleScript") then
		local service = require(module)
		if service.Start then
			service:Start()
		end
	end
end