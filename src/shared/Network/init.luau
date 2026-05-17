local ByteNetMax = require(script.ByteNetMax)

return {
    General = ByteNetMax.defineNamespace("General", function()
        return {
            packets = {},
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
                    value = ByteNetMax.struct({
                        Name = ByteNetMax.string,
                        Value = ByteNetMax.struct({
                            string = ByteNetMax.optional(ByteNetMax.string),
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