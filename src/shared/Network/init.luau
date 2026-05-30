local ByteNetMax = require(script.ByteNetMax)

return {
	General = ByteNetMax.defineNamespace("General", function()
		return {
			packets = {
				Notification = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						Message = ByteNetMax.string,
					})
				}),
			},
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
	Leaderboard = ByteNetMax.defineNamespace("Leaderboard", function()
		return {
			packets = {
				LeaderboardUpdate = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						rank = ByteNetMax.uint8,
						userId = ByteNetMax.float64,
						value = ByteNetMax.uint32,
						username = ByteNetMax.string,
						statName = ByteNetMax.string,
					})
				}),
			},
			queries = {
				GetLeaderboardData = ByteNetMax.defineQuery({
					request = ByteNetMax.struct({
                        statName = ByteNetMax.string,
                    }),
					response = ByteNetMax.struct({
						entries = ByteNetMax.array(ByteNetMax.struct({
							rank = ByteNetMax.uint8,
							userId = ByteNetMax.float64,
							value = ByteNetMax.uint32,
							username = ByteNetMax.string,
							statName = ByteNetMax.string,
						})),
						playerEntry = ByteNetMax.struct({
							rank = ByteNetMax.uint32,
							userId = ByteNetMax.float64,
							value = ByteNetMax.uint32,
							username = ByteNetMax.string,
							statName = ByteNetMax.string,
						}),
					})
				})
			},
		}
	end),
	SFX = ByteNetMax.defineNamespace("SFX", function()
		return {
			packets = {
				PlaySFX = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						handleId = ByteNetMax.string,
						Parent = ByteNetMax.inst,
						SoundId = ByteNetMax.optional(ByteNetMax.float64),
						SoundInstance = ByteNetMax.optional(ByteNetMax.inst),
					})
				}),
				StopSFX = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						handleId = ByteNetMax.string,
					})
				}),
			},
			queries = {},
		}
	end),
	VFX = ByteNetMax.defineNamespace("VFX", function()
		return {
			packets = {
				ClientFXPacket = ByteNetMax.definePacket({
					reliabilityType = "unreliable",
					value = ByteNetMax.struct({
						action = ByteNetMax.string,
						handleId = ByteNetMax.optional(ByteNetMax.string),
						fxData = ByteNetMax.optional(ByteNetMax.struct({
							Name = ByteNetMax.string,
							Type = ByteNetMax.string,
						})),
						args = ByteNetMax.struct({
							parent = ByteNetMax.optional(ByteNetMax.inst), -- Who to set to
                            weldPart = ByteNetMax.optional(ByteNetMax.inst),
                            vfx = ByteNetMax.optional(ByteNetMax.inst), -- Use for instances (particles, etc)
                            vfxName = ByteNetMax.optional(ByteNetMax.string), -- Use for highlight
                            vfxCFrame = ByteNetMax.optional(ByteNetMax.cframe),
                            deletionTime = ByteNetMax.optional(ByteNetMax.uint8), 
                            offset = ByteNetMax.optional(ByteNetMax.cframe),
                            position = ByteNetMax.optional(ByteNetMax.vec3),
                            isBeam = ByteNetMax.optional(ByteNetMax.bool),
                            shouldWeld = ByteNetMax.optional(ByteNetMax.bool),
                            weldC1 = ByteNetMax.optional(ByteNetMax.cframe),
                            caster = ByteNetMax.optional(ByteNetMax.inst),
                            target = ByteNetMax.optional(ByteNetMax.inst),
                            timeBetweenAfterimage = ByteNetMax.optional(ByteNetMax.float32),
                            afterimageDuration = ByteNetMax.optional(ByteNetMax.float32),
                            tween = ByteNetMax.optional(ByteNetMax.struct({
                                target = ByteNetMax.struct({
                                    CFrame = ByteNetMax.optional(ByteNetMax.cframe),
                                }),
                                duration = ByteNetMax.uint16,
                            }))
						})
					}),
				}),
			},
			queries = {},
		}
	end),
	Misc = ByteNetMax.defineNamespace("Misc", function()
		return {
			packets = {
				ClaimFreeGroupReward = ByteNetMax.definePacket({
					value = ByteNetMax.struct({})
				}),
				RoundResults = ByteNetMax.definePacket({
					value = ByteNetMax.map(ByteNetMax.string, ByteNetMax.uint8)
				}),
				SurviveLeaderboard = ByteNetMax.definePacket({
					value = ByteNetMax.array(ByteNetMax.struct({
						name = ByteNetMax.string,
						time = ByteNetMax.uint16,
					}))
				}),
			},
			queries = {},
		}
	end),
}