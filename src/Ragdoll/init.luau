--[[
	Ragdoll Controller
	Integrates the ragdoll system with Chrono replication for both R6 and R15.

	Requirements
	------------
	- This module must be required on both the server and the client.
	- PLAYER_RAGDOLL should be registered before Chrono.Start().
	- Chrono Holders are only used when holder.model matches Player.Character.

	Chrono State
	------------
	Ragdolled:
		Config            = PLAYER_RAGDOLL
		InterpolationMode = ALIGN

	Recovered:
		Config            = PLAYER
		InterpolationMode = CFRAME

	Rig Support
	-----------
	R6:
		Uses the custom invisible physics skeleton and BallSocketConstraints.

	R15:
		Uses Roblox Avatar Joint Upgrade constraints when available.
		Legacy Motor6D-based R15 rigs fall back to the custom skeleton path.

	Death Behaviour
	---------------
	Dead characters intentionally remain ragdolled. Normal StopRagdoll() and
	timed recovery will not restore a character whose Humanoid.Health <= 0.
]]

local Chrono = require(Path.To.Chrono)
local Ragdoll = require(script.ragdoll);

local R6_STAND_HEIGHT = 3
local RECOVERY_CAST_OFFSET = Vector3.new(0, 4, 0)
local RECOVERY_CAST_DIRECTION = Vector3.new(0, -16, 0)
local DEFAULT_LOOK_DIRECTION = Vector3.new(0, 0, -1)

local function getHolder(player: Player)
	local character = player.Character

	local holder = Chrono.Holder.GetEntityFromPlayer(player)
	if not holder or holder.model ~= character then
		return nil
	end

	return holder
end

local function clearCharacterMomentum(character: Model)
	for _, descendant in character:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end

		descendant.AssemblyAngularVelocity = Vector3.zero

		local velocity = descendant.AssemblyLinearVelocity
		descendant.AssemblyLinearVelocity = Vector3.new(
			velocity.X,
			math.min(velocity.Y, 0),
			velocity.Z
		)
	end
end

local function getRecoveryCFrame(character: Model, humanoid: Humanoid, root: BasePart): CFrame?
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.RespectCanCollide = true

	local ground = workspace:Raycast( root.Position + RECOVERY_CAST_OFFSET, RECOVERY_CAST_DIRECTION, raycastParams)

	if not ground then
		return nil
	end

	local standHeight;
	if humanoid.RigType == Enum.HumanoidRigType.R6 then 
		standHeight = R6_STAND_HEIGHT
	else 
		standHeight = humanoid.HipHeight + root.Size.Y * 0.5
	end

	local position = Vector3.new(
		root.Position.X,
		ground.Position.Y + standHeight,
		root.Position.Z
	)

	local lookDirection = Vector3.new(
		root.CFrame.LookVector.X,
		0,
		root.CFrame.LookVector.Z
	)

	if lookDirection.Magnitude < 0.001 then
		lookDirection = DEFAULT_LOOK_DIRECTION
	else
		lookDirection = lookDirection.Unit
	end

	return CFrame.lookAt(position, position + lookDirection, Vector3.yAxis)
end

local function stabilizeRoot(player: Player)
	local character = player.Character

	local humanoid = character:FindFirstChild("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	-- R15 uses its real body for ragdoll physics, so momentum is cleared from the
	-- entire character before restoring normal joints. This is safe for R6 too.
	clearCharacterMomentum(character)

	local recoveryCFrame = getRecoveryCFrame(character, humanoid, root)
	local holder = getHolder(player)
	if holder then
		pcall(Chrono.Entity.SetCFrame, holder, recoveryCFrame)
	end

	character:PivotTo(recoveryCFrame)
end

local function finishRagdoll(player: Player)
	local character = player.Character
	local humanoid = character:FindFirstChild("Humanoid")

	local holder = getHolder(player)
	stabilizeRoot(player)

	Ragdoll.SetRagdollDisabled(character)

	Chrono.Entity.SetInterpolationMode(holder, "CFRAME")

	humanoid.AutoRotate = true

	Chrono.Entity.SetConfig(holder, "PLAYER")
end

local function StartRagdoll(player: Player, duration: number?)
	local character = player.Character
	local humanoid = character:FindFirstChild("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	local holder = getHolder(player)
	Chrono.Entity.SetConfig(holder, "PLAYER_RAGDOLL")
	Chrono.Entity.SetInterpolationMode(holder, "ALIGN")

	humanoid.AutoRotate = false
	root.AssemblyAngularVelocity = Vector3.zero

	Ragdoll.SetRagdollEnabled(character)

	if not duration then
		return
	end

	task.delay(duration, function()
		local currentCharacter = player.Character
		local currentHumanoid = currentCharacter and currentCharacter:FindFirstChild("Humanoid")

		-- Dead characters intentionally remain in ragdoll/ALIGN. Restoring normal
		-- joints and CF interpolation while dead can cause launch/jitter behaviour.
		if not currentHumanoid or currentHumanoid.Health <= 0 then
			return
		end

		finishRagdoll(player)
	end)
end

local function StopRagdoll(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	finishRagdoll(player)
end

return {
	StartRagdoll = StartRagdoll,
	StopRagdoll = StopRagdoll,
}
