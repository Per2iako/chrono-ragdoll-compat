local SHOULD_RAGDOLL_TAG = "KF_Should_Ragdoll"
local SKELETON_FOLDER_NAME = "KF_RAGDOLL_SKELETON"
local RUNTIME_FOLDER_NAME = "KF_RAGDOLL_RUNTIME"
local SERVER_RUNTIME_FOLDER_NAME = "KF_RAGDOLL_SERVER_RUNTIME"

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RigTypes = require(script.Parent.rigtypes)

local modelStates = setmetatable({}, { __mode = "k" })
local serverHumanoidStates = setmetatable({}, { __mode = "k" })

local function isSelfRagdoll(model: Model): boolean
	return RunService:IsClient() and model == Players.LocalPlayer.Character
end

local function hasAJU(model: Model): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("AnimationConstraint") then
			return true
		end
	end

	return false
end

local function cloneBodyPart(part: BasePart): BasePart
	local newPart = Instance.fromExisting(part)
	newPart.Transparency = 1
	newPart.CanCollide = true
	newPart.CanTouch = false
	newPart.CanQuery = false

	for _, child in part:GetChildren() do
		if child:IsA("Attachment") then
			child:Clone().Parent = newPart
		end
	end

	return newPart
end

local function saveAndStopAnimations(animator: Animator)
	local savedTracks = {}

	for _, track in animator:GetPlayingAnimationTracks() do
		if not track.Looped then
			track:Stop()
		end
	end

	local connection = animator.AnimationPlayed:Connect(function(track)
		table.insert(savedTracks, {
			track = track,
			savedTime = time() - track.TimePosition,
		})
		track:Stop()
	end)

	return savedTracks, connection
end

local function restoreAnimations(savedTracks, connection: RBXScriptConnection?)
	if connection then
		connection:Disconnect()
	end

	for _, saved in savedTracks or {} do
		local currentTrackTime = time() - saved.savedTime
		if currentTrackTime < saved.track.Length then
			saved.track:Play()
			saved.track.TimePosition = currentTrackTime
		end
	end
end

local function setCameraForRagdoll(model: Model, enabled: boolean, previousSubject: Instance?)
	if not isSelfRagdoll(model) then
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	if enabled then
		local head = model:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			camera.CameraSubject = head
		end
	elseif previousSubject then
		camera.CameraSubject = previousSubject
	else
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end

local function enableLegacyRagdoll(model: Model, humanoid: Humanoid, hrp: BasePart, animator: Animator)
	local rigType = humanoid.RigType
	local rootAttachment = hrp:FindFirstChild("RootAttachment") :: Attachment?
	local rootJoint = RigTypes.FindRootJoint(model, hrp)
	local rootBodyPartName = RigTypes.GetRootBodyPart(rigType)
	local rootBodyPart = model:FindFirstChild(rootBodyPartName)

	if not rootAttachment or not rootJoint or not rootBodyPart or not rootBodyPart:IsA("BasePart") then
		return
	end

	if model:FindFirstChild(SKELETON_FOLDER_NAME) then
		return
	end

	local selfRagdoll = isSelfRagdoll(model)
	local camera = workspace.CurrentCamera
	local savedTracks, animatorConnection = saveAndStopAnimations(animator)
	local motorStates = {}

	for _, motor in RigTypes.GetLegacyMotors(model, rigType) do
		motorStates[motor] = motor.Enabled
		motor.Enabled = false
	end

	modelStates[model] = {
		mode = "LEGACY",
		rootCanCollide = hrp.CanCollide,
		rootJointEnabled = rootJoint.Enabled,
		cameraSubject = if selfRagdoll and camera then camera.CameraSubject else nil,
		savedTracks = savedTracks,
		animatorConnection = animatorConnection,
		motorStates = motorStates,
		requiresNeck = humanoid.RequiresNeck,
		breakJointsOnDeath = humanoid.BreakJointsOnDeath,
	}

	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	rootJoint.Enabled = false
	hrp.CanCollide = true

	local skeletonFolder = Instance.new("Folder")
	skeletonFolder.Name = SKELETON_FOLDER_NAME

	setCameraForRagdoll(model, true)
	if selfRagdoll then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Enabled = true
	alignPosition.Attachment1 = rootAttachment
	alignPosition.MaxAxesForce = Vector3.new(9, 9, 9)
	alignPosition.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	alignPosition.Responsiveness = 100
	alignPosition.ApplyAtCenterOfMass = true
	alignPosition.Parent = skeletonFolder

	local partMap = {}
	local realBodyParts = { hrp }
	local visualCollisionStates = {}

	for _, partName in RigTypes.GetBodyParts(rigType) do
		local realPart = model:FindFirstChild(partName)
		if not realPart or not realPart:IsA("BasePart") then
			continue
		end

		local skeletonPart = cloneBodyPart(realPart)
		partMap[skeletonPart] = realPart
		table.insert(realBodyParts, realPart)

		if partName == rootBodyPartName then
			local attachment = Instance.new("Attachment")
			attachment.Name = "RagdollRootAttachment"
			attachment.Parent = skeletonPart
			alignPosition.Attachment0 = attachment
		end

		skeletonPart.Parent = skeletonFolder
	end

	-- The visible R6 body is only a presentation layer while ragdolled. It is
	-- CFramed onto the calculation skeleton every Heartbeat, so it must not
	-- participate in collision resolution or it can continuously push the HRP
	-- and make the whole ragdoll creep/slide across the floor.
	--
	-- The original project solved this through Combatants2 <-> Players collision
	-- groups. Keep the module standalone by reproducing the same relationship
	-- explicitly instead.
	for _, realPart in realBodyParts do
		if realPart == hrp then
			continue
		end

		visualCollisionStates[realPart] = realPart.CanCollide
		realPart.CanCollide = false

		local rootNoCollision = Instance.new("NoCollisionConstraint")
		rootNoCollision.Name = "RagdollRootVisualNoCollisionConstraint"
		rootNoCollision.Part0 = hrp
		rootNoCollision.Part1 = realPart
		rootNoCollision.Parent = skeletonFolder
	end

	modelStates[model].visualCollisionStates = visualCollisionStates

	-- The calculation skeleton overlaps the visible character by design.
	-- Explicitly disable every skeleton <-> real-body collision so this module
	-- does not depend on any project-level CollisionGroup configuration.
	for skeletonPart in partMap do
		for _, realPart in realBodyParts do
			local noCollision = Instance.new("NoCollisionConstraint")
			noCollision.Name = "RagdollVisualNoCollisionConstraint"
			noCollision.Part0 = realPart
			noCollision.Part1 = skeletonPart
			noCollision.Parent = skeletonPart
		end
	end

	skeletonFolder.Parent = model

	local attachments = RigTypes.GetAttachments(skeletonFolder, model, model:GetScale(), rigType)
	for skeletonPart, realPart in partMap do
		local data = attachments[realPart.Name]
		if not data then
			continue
		end

		local constraint = Instance.new("BallSocketConstraint")
		constraint.Name = "RagdollBallSocketConstraint"
		constraint.Attachment0 = data.a0
		constraint.Attachment1 = data.a1
		constraint.LimitsEnabled = true
		constraint.UpperAngle = data.limits.UpperAngle
		constraint.TwistLimitsEnabled = true
		constraint.TwistLowerAngle = data.limits.TwistLowerAngle
		constraint.TwistUpperAngle = data.limits.TwistUpperAngle
		constraint.MaxFrictionTorque = data.limits.MaxFrictionTorque or 0
		constraint.Parent = skeletonPart
	end

	for _, objects in RigTypes.GetNoCollisions(skeletonFolder, rigType) do
		local constraint = Instance.new("NoCollisionConstraint")
		constraint.Name = "RagdollNoCollisionConstraint"
		constraint.Part0 = objects.part1
		constraint.Part1 = objects.part2
		constraint.Parent = objects.part1
	end

	local lastHrpPosition = hrp.Position
	local hasMoved = false

	local moveConnection = RunService.Heartbeat:Connect(function(dt)
		for skeletonPart, realPart in partMap do
			if skeletonPart.Parent and realPart.Parent then
				realPart.CFrame = skeletonPart.CFrame
			end
		end

		alignPosition.MaxAxesForce = Vector3.new(90000, 90000, 90000)
		alignPosition.Mode = Enum.PositionAlignmentMode.TwoAttachment

		if not hasMoved and (hrp.Position - lastHrpPosition).Magnitude < 0.5 then
			return
		end
		hasMoved = true

		local speed = (hrp.Position - lastHrpPosition).Magnitude / math.max(dt, 1 / 240)
		lastHrpPosition = hrp.Position

		if speed >= 5 then
			return
		end

		local castParams = RaycastParams.new()
		castParams.FilterType = Enum.RaycastFilterType.Exclude
		castParams.FilterDescendantsInstances = { model }
		castParams.RespectCanCollide = true

		local groundCast = workspace:Raycast(
			rootAttachment.WorldPosition,
			Vector3.new(0, -5, 0),
			castParams
		)

		if groundCast then
			alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
			alignPosition.Position = groundCast.Position + Vector3.new(0, 0.5, 0)
			alignPosition.MaxAxesForce = Vector3.new(90000, 0, 90000)
		end
	end)

	modelStates[model].moveConnection = moveConnection
end

local function isRootAnimationConstraint(constraint: AnimationConstraint, hrp: BasePart): boolean
	if string.find(string.lower(constraint.Name), "root", 1, true) then
		return true
	end

	local a0 = constraint.Attachment0
	local a1 = constraint.Attachment1
	return (a0 and a0.Parent == hrp) or (a1 and a1.Parent == hrp)
end

local function enableAJURagdoll(model: Model, humanoid: Humanoid, hrp: BasePart, animator: Animator)
	if model:FindFirstChild(RUNTIME_FOLDER_NAME) then
		return
	end

	local selfRagdoll = isSelfRagdoll(model)
	local camera = workspace.CurrentCamera
	local savedTracks, animatorConnection = saveAndStopAnimations(animator)

	local runtimeFolder = Instance.new("Folder")
	runtimeFolder.Name = RUNTIME_FOLDER_NAME
	runtimeFolder.Parent = model

	-- AJU ragdoll joints are toggled on the server through
	-- AnimationConstraint.Enabled. Do not change IsKinematic/MaxForce/MaxTorque
	-- here: changing IsKinematic at runtime can leave current AJU characters in
	-- a broken prediction state after unragdoll.
	modelStates[model] = {
		mode = "AJU",
		cameraSubject = if selfRagdoll and camera then camera.CameraSubject else nil,
		savedTracks = savedTracks,
		animatorConnection = animatorConnection,
	}

	setCameraForRagdoll(model, true)
	if selfRagdoll then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end
end

local function EnableRagdoll(model: Model)
	if modelStates[model] then
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp or not hrp:IsA("BasePart") then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	if humanoid.RigType == Enum.HumanoidRigType.R15 and hasAJU(model) then
		enableAJURagdoll(model, humanoid, hrp, animator)
	else
		enableLegacyRagdoll(model, humanoid, hrp, animator)
	end
end

local function disableAJURagdoll(model: Model, humanoid: Humanoid, _hrp: BasePart, state)
	local runtimeFolder = model:FindFirstChild(RUNTIME_FOLDER_NAME)
	if runtimeFolder then
		runtimeFolder:Destroy()
	end

	restoreAnimations(state.savedTracks, state.animatorConnection)
	setCameraForRagdoll(model, false, state.cameraSubject)

	if isSelfRagdoll(model) and humanoid.Health > 0 then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function disableLegacyRagdoll(model: Model, humanoid: Humanoid, hrp: BasePart, state)
	local skeletonFolder = model:FindFirstChild(SKELETON_FOLDER_NAME)

	if state.moveConnection then
		state.moveConnection:Disconnect()
	end

	local rootJoint = RigTypes.FindRootJoint(model, hrp)
	if rootJoint then
		rootJoint.Enabled = state.rootJointEnabled
	end

	for motor, wasEnabled in state.motorStates or {} do
		if motor.Parent then
			motor.Enabled = wasEnabled
		end
	end

	for realPart, wasCanCollide in state.visualCollisionStates or {} do
		if realPart.Parent then
			realPart.CanCollide = wasCanCollide
		end
	end

	if skeletonFolder then
		skeletonFolder:Destroy()
	end

	hrp.CanCollide = state.rootCanCollide
	humanoid.RequiresNeck = state.requiresNeck
	humanoid.BreakJointsOnDeath = state.breakJointsOnDeath

	restoreAnimations(state.savedTracks, state.animatorConnection)
	setCameraForRagdoll(model, false, state.cameraSubject)

	if isSelfRagdoll(model) and humanoid.Health > 0 then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function DisableRagdoll(model: Model)
	local state = modelStates[model]
	if not state then
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp or not hrp:IsA("BasePart") then
		modelStates[model] = nil
		return
	end

	if state.mode == "AJU" then
		disableAJURagdoll(model, humanoid, hrp, state)
	else
		disableLegacyRagdoll(model, humanoid, hrp, state)
	end

	modelStates[model] = nil
end

local function IsRagdolled(instance: Instance)
	return instance:HasTag(SHOULD_RAGDOLL_TAG)
end

local function SetRagdollEnabled(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart")

	if humanoid and not serverHumanoidStates[model] then
		local state = {
			requiresNeck = humanoid.RequiresNeck,
			breakJointsOnDeath = humanoid.BreakJointsOnDeath,
			ajuConstraintStates = {},
		}

		serverHumanoidStates[model] = state
		humanoid.RequiresNeck = false
		humanoid.BreakJointsOnDeath = false

		-- R15 AJU already contains tuned BallSocketConstraints. The intended
		-- ragdoll transition is to disable the non-root AnimationConstraints
		-- and let those BallSockets simulate the character.
		if humanoid.RigType == Enum.HumanoidRigType.R15 and hrp and hrp:IsA("BasePart") and hasAJU(model) then
			for _, descendant in model:GetDescendants() do
				if descendant:IsA("AnimationConstraint") and not isRootAnimationConstraint(descendant, hrp) then
					state.ajuConstraintStates[descendant] = descendant.Enabled
					descendant.Enabled = false
				end
			end

			local runtimeFolder = Instance.new("Folder")
			runtimeFolder.Name = SERVER_RUNTIME_FOLDER_NAME
			runtimeFolder.Parent = model
			state.runtimeFolder = runtimeFolder

			for _, objects in RigTypes.GetNativeNoCollisionPairs(model) do
				local constraint = Instance.new("NoCollisionConstraint")
				constraint.Name = "RagdollNoCollisionConstraint"
				constraint.Part0 = objects.part1
				constraint.Part1 = objects.part2
				constraint.Parent = runtimeFolder
			end
		end
	end

	model:AddTag(SHOULD_RAGDOLL_TAG)

	if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end
end

local function SetRagdollDisabled(model: Model)
	model:RemoveTag(SHOULD_RAGDOLL_TAG)

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local state = serverHumanoidStates[model]

	if state then
		for constraint, wasEnabled in state.ajuConstraintStates or {} do
			if constraint.Parent then
				constraint.Enabled = wasEnabled
			end
		end

		if state.runtimeFolder and state.runtimeFolder.Parent then
			state.runtimeFolder:Destroy()
		else
			local runtimeFolder = model:FindFirstChild(SERVER_RUNTIME_FOLDER_NAME)
			if runtimeFolder then
				runtimeFolder:Destroy()
			end
		end
	end

	if humanoid then
		if state then
			humanoid.RequiresNeck = state.requiresNeck
			humanoid.BreakJointsOnDeath = state.breakJointsOnDeath
		end

		if humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end

	serverHumanoidStates[model] = nil
end

if RunService:IsClient() then
	CollectionService:GetInstanceAddedSignal(SHOULD_RAGDOLL_TAG):Connect(function(model)
		if model:IsA("Model") then
			EnableRagdoll(model)
		end
	end)

	CollectionService:GetInstanceRemovedSignal(SHOULD_RAGDOLL_TAG):Connect(function(model)
		if model:IsA("Model") then
			DisableRagdoll(model)
		end
	end)

	for _, model in CollectionService:GetTagged(SHOULD_RAGDOLL_TAG) do
		if model:IsA("Model") then
			task.defer(EnableRagdoll, model)
		end
	end
end

return {
	EnableRagdoll = EnableRagdoll,
	DisableRagdoll = DisableRagdoll,
	IsRagdolled = IsRagdolled,
	SetRagdollEnabled = SetRagdollEnabled,
	SetRagdollDisabled = SetRagdollDisabled,
}
