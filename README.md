# Chrono Ragdoll Compatibility

A ragdoll implementation adapted for **Chrono v2.2.0+**.

> Built for [Chrono — Drop-in Custom Physics Replication Library](https://devforum.roblox.com/t/chrono-drop-in-custom-physics-replication-library/3873294)

Supports both **R6** and **R15**, with additional fixes for ragdoll stability, death handling, recovery, and Chrono replication.

> [!IMPORTANT]
> This module must be required on both the **server** and **client**.

## Features

* R6 ragdoll support
* R15 / Avatar Joint Upgrade support
* Chrono replication integration
* Timed ragdolls
* Safe death handling
* Root stabilization before recovery
* Protection against launch, jitter, and sliding
* No custom `CollisionGroup` dependency
* Legacy R15 fallback support

## Requirements

* Roblox
* Chrono v2.2.0+
* Server and client initialization

`PLAYER_RAGDOLL` should be registered before:

```lua
Chrono.Start(...)
```

Example:

```lua
Chrono.Config.RegisterEntityType("PLAYER_RAGDOLL", {
	BUFFER = 0,
	TICK_RATE = 1 / 20,
	HALF_TICK_DISTANCE = math.huge,
	FULL_ROTATION = true,
	MODEL_REPLICATION_MODE = "NATIVE",
	ASSEMBLY_ROOT_PART_CHECK = false,
})
```

The module also attempts fallback registration if the entity type has not already been registered.

## Installation

Example structure:

```text
Ragdoll/
├── init.luau
├── ragdoll.luau
└── rigtypes.luau
```

Set the Chrono path inside `init.luau`:

```lua
local Chrono = require(path.To.Chrono)
```

Then require the module on both the server and client.

## Usage

```lua
local Ragdoll = require(path.To.Ragdoll)

Ragdoll:StartRagdoll(player)
Ragdoll:StartRagdoll(player, 5)

Ragdoll:StopRagdoll(player)
```

Timed ragdolls automatically recover unless the character has died.

`StopRagdoll()` intentionally does not recover dead characters.

## Rig Support

### R6

R6 uses a custom invisible physics skeleton driven by `BallSocketConstraint`.

The visible character follows the simulated skeleton while collision safeguards prevent the root, visible body, and skeleton from pushing against each other.

This helps prevent:

* Sliding
* Jitter
* Self-collision impulses
* Character launching

### R15

R15 supports Roblox's **Avatar Joint Upgrade**.

The implementation uses the character's existing:

* `AnimationConstraint`
* `BallSocketConstraint`

Relevant animation constraints are disabled during ragdoll so the existing physics constraints can simulate the body.

Their original states are restored during recovery.

Legacy R15 rigs using `Motor6D` may fall back to the custom skeleton implementation.

## Chrono Integration

While ragdolled:

```text
Entity Config       = PLAYER_RAGDOLL
Interpolation Mode  = ALIGN
```

After recovery:

```text
Entity Config       = PLAYER
Interpolation Mode  = CFRAME
```

`ALIGN` is used during ragdoll so normal CFrame replication does not fight against the physics simulation.

Before returning to `CFRAME`, the character is stabilized and synchronized with Chrono.

The Holder is resolved using:

```lua
Chrono.Holder.GetEntityFromPlayer(player)
```

and is only accepted when:

```lua
holder.model == player.Character
```

This prevents Chrono operations from affecting an outdated character during respawn.

## Death Behaviour

Dead characters intentionally remain ragdolled.

The module does not restore normal joints, `PLAYER` configuration, or `CFRAME` interpolation when:

```lua
humanoid.Health <= 0
```

Restoring them while the corpse is still being simulated can cause:

* Launch impulses
* Jitter
* Position corrections
* Constraint instability
* Unwanted movement

## Character Recovery

Before leaving ragdoll, `stabilizeRoot()` prepares the character for normal movement again.

It:

1. Clears unwanted angular velocity.
2. Reduces remaining vertical momentum.
3. Finds the ground below the character.
4. Calculates a valid standing position.
5. Preserves horizontal facing direction.
6. Synchronizes the recovery CFrame with Chrono.
7. Moves the character to the same position before restoring normal replication.

Without this step, leftover ragdoll momentum and Chrono position correction can happen at the same time, causing the character to launch, spin, slide, or recover in an invalid position.

## Timer Safety

Timed ragdolls use per-player tokens.

Starting, restarting, or stopping ragdoll invalidates previous timers.

This prevents an old delayed callback from unexpectedly recovering a newer ragdoll state.

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
