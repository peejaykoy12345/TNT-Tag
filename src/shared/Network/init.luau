local BugReporterService = game:GetService("BugReporterService")
local ByteNetMax = require(script.ByteNetMax)

return {
    General = ByteNetMax.defineNamespace("General", function()
        return {
            packets = {},
            queries = {},
        }
    end),
    Ability = ByteNetMax.defineNamespace("Ability", function()
        return {
            packets = {
                Perform = ByteNetMax.definePacket({
                    value = ByteNetMax.struct({})
                }),
            },
            queries = {},
        }
    end),
    Inventory = ByteNetMax.defineNamespace("Inventory", function()
        return {
            packets = {
                EquipItem = ByteNetMax.definePacket({
                    value = ByteNetMax.struct({
                        ItemName = ByteNetMax.string,
                        Type = ByteNetMax.string,
                    })
                }),
            },
            queries = {
                GetInventoryData = ByteNetMax.defineQuery({
                    request = ByteNetMax.struct({}),
                    response = ByteNetMax.struct({
                        Equipped = ByteNetMax.map(ByteNetMax.string, ByteNetMax.string),
                        Owned = ByteNetMax.map(ByteNetMax.string, ByteNetMax.array(ByteNetMax.string))
                    })
                })
            },
        }
    end),
    Replication = ByteNetMax.defineNamespace("Replication", function()
        return {
            packets = {
                Initialize = ByteNetMax.definePacket({
                    value = ByteNetMax.struct({
                        Name = ByteNetMax.string,
                    })
                }),
                Update = ByteNetMax.definePacket({
                    value = ByteNetMax.struct({
                        Name = ByteNetMax.string,
                        Args = ByteNetMax.optional(ByteNetMax.struct({
                            Type = ByteNetMax.optional(ByteNetMax.string),
                            Action = ByteNetMax.optional(ByteNetMax.string),
                        })),
                        Value = ByteNetMax.struct({
                            string = ByteNetMax.optional(ByteNetMax.string),
                            uint8 = ByteNetMax.optional(ByteNetMax.uint8),
                            uint16 = ByteNetMax.optional(ByteNetMax.uint16),
                            uint32 = ByteNetMax.optional(ByteNetMax.uint32),
                            custom = ByteNetMax.optional(ByteNetMax.unknown),
                        }),
                    })
                }),
                UnreliableUpdate = ByteNetMax.definePacket({
                    reliabilityType = "unreliable",
                    value = ByteNetMax.struct({
                        Name = ByteNetMax.string,
                        Args = ByteNetMax.optional(ByteNetMax.struct({
                            Type = ByteNetMax.optional(ByteNetMax.string),
                            Action = ByteNetMax.optional(ByteNetMax.string),
                        })),
                        Value = ByteNetMax.struct({
                            string = ByteNetMax.optional(ByteNetMax.string),
                            uint8 = ByteNetMax.optional(ByteNetMax.uint8),
                            uint16 = ByteNetMax.optional(ByteNetMax.uint16),
                            uint32 = ByteNetMax.optional(ByteNetMax.uint32),
                            custom = ByteNetMax.optional(ByteNetMax.unknown),
                        }),
                    })
                }),
            },
            queries = {},
        }
    end),
}