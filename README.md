# Chrono Ragdoll Compatibility

A ragdoll implementation adapted for **Chrono v2.2.0+**.

> Built for [Chrono — Drop-in Custom Physics Replication Library](https://devforum.roblox.com/t/chrono-drop-in-custom-physics-replication-library/3873294)

Supports both **R6** and **R15**, with additional fixes for ragdoll stability, death handling, recovery, and Chrono replication.

> [!IMPORTANT]
> This module must be required on both the **server** and **client**.

## Requirements

* Chrono v2.2.0+

## Installation Guide

> Ragdoll/init.luau
```lua
local Chrono = require(Path.To.Chrono)
```

> LocalScript
```lua
--// LocalScript

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
```

> Script 
```lua
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

--// no time limit ragdoll
Ragdoll.StartRagdoll(player)

--// set timeout for ragdoll
Ragdoll.StartRagdoll(player, 5)

--// stop ragdoll
Ragdoll.StopRagdoll(player)
```

## Collision Handling

No custom Roblox `CollisionGroup` setup is required.
The module instead uses:

* `NoCollisionConstraint`
* Controlled `CanCollide` states
* Character filtering for raycasts

This makes the module easier to integrate into other projects without modifying global collision groups.

## Third-Party Code

This project contains code derived from and inspired by third-party ragdoll implementations, including work associated with **Tazm0ndo** and **Dr_Sinek / Brawldude2**.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for full attribution and licensing information.

## License

See [LICENSE](LICENSE).

Third-party portions remain subject to their respective copyright and license terms.
