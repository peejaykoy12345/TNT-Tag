local ByteNetMax = require(script.ByteNetMax)

return {
    General = ByteNetMax.defineNamespace("General", function()
        return {
            packets = {},
            queries = {},
        }
    end),
    Ability = ByteNetMax.defineNamespace("General", function()
        return {
            packets = {
                Perform = ByteNetMax.definePacket({
                    value = ByteNetMax.struct({})
                }),
            },
            queries = {},
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
                    reliabilityType = "unreliable",
                    value = ByteNetMax.struct({
                        Name = ByteNetMax.string,
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