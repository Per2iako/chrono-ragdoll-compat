--// Script

local Chrono = require(Path.To.Chrono)
local Ragdoll = require(script.Parent.Ragdoll)

-- PLAYER_RAGDOLL should normally be registered by the Chrono bootstrap before
-- Chrono.Start(). This registration is only a fallback.
Chrono.Config.RegisterEntityType("PLAYER_RAGDOLL", {
    BUFFER = 0,
    TICK_RATE = 1 / 20,
    HALF_TICK_DISTANCE = math.huge,
    FULL_ROTATION = true,
    MODEL_REPLICATION_MODE = "NATIVE",
    ASSEMBLY_ROOT_PART_CHECK = false,
})


Chrono.Start()

--// no time Limit Ragdoll
Ragdoll.StartRagdoll(player)

--// set timeout for ragdoll
Ragdoll.StartRagdoll(player, 5)

--// stop ragdoll
Ragdoll.StopRagdoll(player)