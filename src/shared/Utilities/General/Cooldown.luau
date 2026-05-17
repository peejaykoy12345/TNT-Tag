local Cooldown = {}
Cooldown.Cooldowns = {}

function Cooldown:InitializeCharacter(char: Model)
    self.Cooldowns[char] = {}

    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    hum.Died:Connect(function()
        self.Cooldowns[char] = nil
    end)
end

function Cooldown:SetCooldown(char: Model, action: string, cooldown: number)
    if not self.Cooldowns[char] then
        self:InitializeCharacter(char)
    end
    
    self.Cooldowns[char][action] = true

    task.delay(cooldown, function()
        if not self.Cooldowns[char] then return end
        self.Cooldowns[char][action] = nil
    end)
end

function Cooldown:IsOnCooldown(char: Model, action: string): boolean
    if not self.Cooldowns then
        return false
    end
    
    if not self.Cooldowns[char] then
        return false
    end

    return self.Cooldowns[char][action] ~= nil
end

return Cooldown