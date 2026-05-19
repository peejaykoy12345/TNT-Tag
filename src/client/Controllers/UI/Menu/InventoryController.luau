local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Values = ReplicatedStorage.Values
local GameStarted: BoolValue = Values.GameStarted

local Modules = ReplicatedStorage.Modules

local ItemConfig = require(Modules.Config.Items)

local Network = require(Modules.Network)
local ReplicationNamespace = Network.Replication
local ReplicationPackets = ReplicationNamespace.packets
local InitializePacket = ReplicationPackets.Initialize
local UpdatePacket = ReplicationPackets.Update

local InventoryNamespace = Network.Inventory
local InventoryPackets =InventoryNamespace.packets
local InventoryQueries = InventoryNamespace.queries
local EquipItem = InventoryPackets.EquipItem
local GetInventoryData = InventoryQueries.GetInventoryData

local plr = Players.LocalPlayer
local MenuGui = plr:WaitForChild("PlayerGui"):WaitForChild("MenuGui"):WaitForChild("MiddleContainer")
local InventoryMenu = MenuGui:WaitForChild("InventoryMenu") :: Frame
local HeaderFrame = InventoryMenu:WaitForChild("HeaderFrame") :: Frame
local TabsFrame = InventoryMenu:WaitForChild("TabsFrame") :: Frame
local InfoFrame = InventoryMenu:WaitForChild("InfoFrame") :: Frame
local ContentFrame = InventoryMenu:WaitForChild("Content") :: Frame

local CONFIG = {
    DEFAULT_TAB = "Bombs",
}

local InventoryController = {}

function InventoryController:_ChangeTextContent(TextLabel: TextLabel, text: string)
    local TextLabelShadow = TextLabel:WaitForChild(TextLabel.Name)

    TextLabel.Text = text
    TextLabelShadow.Text = text
end

function InventoryController:_UpdateContent(tabName: string, itemName: string, action: "Add" | "Remove")
    local contentFrame = ContentFrame:FindFirstChild(tabName)
    if not contentFrame then
        warn(`Content frame: {tabName} not found`)
        return
    end

    local itemConfig = ItemConfig[tabName][itemName]

    if action == "Add" then
        local itemFrame = contentFrame.Template:Clone()
        itemFrame.Visible = true
        itemFrame.Parent = contentFrame

        local rarity = itemConfig.Rarity

        local button = itemFrame.Button
        self:_ChangeTextContent(button.NameLabel, itemName)
        self:_ChangeTextContent(button.RarityLabel, rarity)

        button.Activated:Connect(function()
            local nameLabel = InfoFrame:WaitForChild("NameLabel") :: TextLabel
            local rarityLabel = InfoFrame:WaitForChild("RarityLabel") :: TextLabel
            
            if nameLabel.Text == itemName and InfoFrame.Visible then
                InfoFrame.Visible = false
                nameLabel.Text = ""
                InfoFrame:SetAttribute("CurrentType", nil)
            else
                InfoFrame.Visible = true
            end

            self:_ChangeTextContent(nameLabel, itemName)
            self:_ChangeTextContent(rarityLabel, rarity)

            InfoFrame:SetAttribute("CurrentType", tabName)
        end)

        itemFrame.Name = itemName
    elseif action == "Remove" then
        local itemFrame = contentFrame:FindFirstChild(itemName)
        if itemFrame then
            itemFrame:Destroy()
        end
    else
        warn(`Invalid action: {action}`)
    end
end

function InventoryController:_ShowCurrentTab()
    if self.currentTabFrame then
        self.currentTabFrame.Visible = false
    end

    local tabFrame = ContentFrame:FindFirstChild(self.currentTab)
    if not tabFrame then
        warn(`Tab Frame {self.currentTab} not found`)
        return
    end

    tabFrame.Visible = true
    self.currentTabFrame = tabFrame
end

function InventoryController:Init()
    UpdatePacket.listen(function(data)
        if data.Name ~= "Inventory" then return end

        local args = data.Args
        local value = data.Value

        local tabName = args.Type
        local action = args.Action
        local itemName = value.string

        self:_UpdateContent(tabName, itemName, action)
    end)

    InfoFrame:WaitForChild("EquipButton").Activated:Connect(function()
        local nameLabel = InfoFrame:WaitForChild("NameLabel") :: TextLabel
        if nameLabel.Text == "" then return end

        local currentType = InfoFrame:GetAttribute("CurrentType")
        if not currentType then return end

        EquipItem.send({
            ItemName = nameLabel.Text,
            Type = currentType,
        })
    end)

    HeaderFrame:WaitForChild("CloseButton").Activated:Connect(function()
        InventoryMenu.Visible = false
    end)

    local result = GetInventoryData.invoke({})
    for tabName, owned in pairs(result.Owned) do
        for _, itemName in ipairs(owned) do
            self:_UpdateContent(tabName, itemName, "Add")
        end
    end
end

function InventoryController:Start()
    ContentFrame.Visible = true
    self.currentTab = CONFIG.DEFAULT_TAB
    self:_ShowCurrentTab()

    for _, btn in ipairs(TabsFrame:GetChildren()) do
        if not btn:IsA("ImageButton") then continue end

        btn.Activated:Connect(function()
            self.currentTab = btn.Name
            self:_ShowCurrentTab()
        end)
    end
end

return InventoryController