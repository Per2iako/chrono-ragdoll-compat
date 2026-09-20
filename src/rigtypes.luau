local RigTypes = {}

type Limits = {
	UpperAngle: number,
	TwistLowerAngle: number,
	TwistUpperAngle: number,
	MaxFrictionTorque: number?,
}

type RigConfig = {
	BodyParts: { string },
	RootBodyPart: string,
	JointLimits: { [string]: Limits },
	NoCollisionPairs: { { string } },
}

local R6_HEAD_LIMITS: Limits = {
	UpperAngle = 30,
	TwistLowerAngle = -60,
	TwistUpperAngle = 60,
}

local R6_SHOULDER_LIMITS: Limits = {
	UpperAngle = 90,
	TwistLowerAngle = -30,
	TwistUpperAngle = 175,
}

local R6_HIP_LIMITS: Limits = {
	UpperAngle = 60,
	TwistLowerAngle = -5,
	TwistUpperAngle = 120,
}

local R15_NECK_LIMITS: Limits = {
	UpperAngle = 15,
	TwistLowerAngle = -25,
	TwistUpperAngle = 25,
	MaxFrictionTorque = 55,
}

local R15_WAIST_LIMITS: Limits = {
	UpperAngle = 40,
	TwistLowerAngle = -45,
	TwistUpperAngle = 40,
	MaxFrictionTorque = 25,
}

local R15_SHOULDER_LIMITS: Limits = {
	UpperAngle = 60,
	TwistLowerAngle = -180,
	TwistUpperAngle = 180,
	MaxFrictionTorque = 25,
}

local R15_ELBOW_LIMITS: Limits = {
	UpperAngle = 5,
	TwistLowerAngle = -20,
	TwistUpperAngle = 160,
	MaxFrictionTorque = 25,
}

local R15_HIP_LIMITS: Limits = {
	UpperAngle = 50,
	TwistLowerAngle = -30,
	TwistUpperAngle = 30,
	MaxFrictionTorque = 25,
}

local R15_KNEE_LIMITS: Limits = {
	UpperAngle = 5,
	TwistLowerAngle = -50,
	TwistUpperAngle = 10,
	MaxFrictionTorque = 25,
}

local R15_WRIST_LIMITS: Limits = {
	UpperAngle = 20,
	TwistLowerAngle = -70,
	TwistUpperAngle = 40,
	MaxFrictionTorque = 25,
}

local R15_ANKLE_LIMITS: Limits = {
	UpperAngle = 10,
	TwistLowerAngle = -45,
	TwistUpperAngle = 25,
	MaxFrictionTorque = 25,
}

local R6_CONFIG: RigConfig = {
	BodyParts = {
		"Head",
		"Torso",
		"Right Arm",
		"Left Arm",
		"Right Leg",
		"Left Leg",
	},
	RootBodyPart = "Torso",
	JointLimits = {
		Neck = R6_HEAD_LIMITS,
		["Right Shoulder"] = R6_SHOULDER_LIMITS,
		["Left Shoulder"] = R6_SHOULDER_LIMITS,
		["Right Hip"] = R6_HIP_LIMITS,
		["Left Hip"] = R6_HIP_LIMITS,
	},
	NoCollisionPairs = {
		{ "Head", "Torso" },
		{ "Left Arm", "Torso" },
		{ "Right Arm", "Torso" },
		{ "Left Leg", "Torso" },
		{ "Right Leg", "Torso" },
		{ "Left Leg", "Right Leg" },
	},
}

local R15_CONFIG: RigConfig = {
	BodyParts = {
		"Head",
		"UpperTorso",
		"LowerTorso",
		"LeftUpperArm",
		"LeftLowerArm",
		"LeftHand",
		"RightUpperArm",
		"RightLowerArm",
		"RightHand",
		"LeftUpperLeg",
		"LeftLowerLeg",
		"LeftFoot",
		"RightUpperLeg",
		"RightLowerLeg",
		"RightFoot",
	},
	RootBodyPart = "LowerTorso",
	JointLimits = {
		Neck = R15_NECK_LIMITS,
		Waist = R15_WAIST_LIMITS,
		LeftShoulder = R15_SHOULDER_LIMITS,
		LeftElbow = R15_ELBOW_LIMITS,
		LeftWrist = R15_WRIST_LIMITS,
		RightShoulder = R15_SHOULDER_LIMITS,
		RightElbow = R15_ELBOW_LIMITS,
		RightWrist = R15_WRIST_LIMITS,
		LeftHip = R15_HIP_LIMITS,
		LeftKnee = R15_KNEE_LIMITS,
		LeftAnkle = R15_ANKLE_LIMITS,
		RightHip = R15_HIP_LIMITS,
		RightKnee = R15_KNEE_LIMITS,
		RightAnkle = R15_ANKLE_LIMITS,
	},
	NoCollisionPairs = {
		{ "HumanoidRootPart", "UpperTorso" },
		{ "HumanoidRootPart", "LowerTorso" },
		{ "HumanoidRootPart", "Head" },
		{ "HumanoidRootPart", "RightUpperArm" },
		{ "HumanoidRootPart", "LeftUpperArm" },
		{ "HumanoidRootPart", "RightLowerArm" },
		{ "HumanoidRootPart", "LeftLowerArm" },
		{ "HumanoidRootPart", "RightHand" },
		{ "HumanoidRootPart", "LeftHand" },
		{ "HumanoidRootPart", "RightUpperLeg" },
		{ "HumanoidRootPart", "LeftUpperLeg" },
		{ "HumanoidRootPart", "RightLowerLeg" },
		{ "HumanoidRootPart", "LeftLowerLeg" },
		{ "HumanoidRootPart", "RightFoot" },
		{ "HumanoidRootPart", "LeftFoot" },

		{ "UpperTorso", "Head" },
		{ "RightUpperArm", "Head" },
		{ "LeftUpperArm", "Head" },
		{ "RightLowerArm", "Head" },
		{ "LeftLowerArm", "Head" },
		{ "LeftLowerArm", "LeftHand" },
		{ "LeftHand", "LeftUpperArm" },
		{ "RightLowerArm", "RightHand" },
		{ "RightHand", "RightUpperArm" },
		{ "LeftUpperArm", "LeftLowerArm" },
		{ "RightUpperArm", "RightLowerArm" },
		{ "UpperTorso", "LeftUpperArm" },
		{ "UpperTorso", "RightUpperArm" },
		{ "LeftLowerLeg", "LeftFoot" },
		{ "LeftUpperLeg", "LeftLowerLeg" },
		{ "LowerTorso", "UpperTorso" },
		{ "RightLowerLeg", "UpperTorso" },
		{ "LeftUpperLeg", "UpperTorso" },
		{ "LeftHand", "UpperTorso" },
		{ "RightHand", "UpperTorso" },
		{ "LowerTorso", "LeftUpperLeg" },
		{ "LeftUpperLeg", "RightUpperLeg" },
		{ "RightLowerLeg", "RightFoot" },
		{ "RightUpperLeg", "RightLowerLeg" },
		{ "RightUpperLeg", "LowerTorso" },
		{ "LeftLowerLeg", "LowerTorso" },
		{ "LeftHand", "LowerTorso" },
		{ "RightHand", "LowerTorso" },
	},
}

local function getConfig(rigType: Enum.HumanoidRigType): RigConfig
	if rigType == Enum.HumanoidRigType.R15 then
		return R15_CONFIG
	end

	return R6_CONFIG
end

local function attachment(name: string, parent: string, position: Vector3?)
	return function(model: Instance, scale: number): Attachment?
		local part = model:FindFirstChild(parent)
		if not part or not part:IsA("BasePart") then
			return nil
		end

		local existing = part:FindFirstChild(name)
		if existing then
			assert(existing:IsA("Attachment"))
			if position then
				existing.Position = position * scale
			end
			return existing
		end

		local newAttachment = Instance.new("Attachment")
		newAttachment.Name = name
		if position then
			newAttachment.Position = position * scale
		end
		newAttachment.Parent = part
		return newAttachment
	end
end

local R6_ATTACHMENTS = {
	rightLeg = attachment("RagdollRightLegAttachment", "Right Leg", Vector3.new(0, 1, 0)),
	leftLeg = attachment("RagdollLeftLegAttachment", "Left Leg", Vector3.new(0, 1, 0)),
	torsoLeft = attachment("RagdollTorsoLeftAttachment", "Torso", Vector3.new(-0.5, -1, 0)),
	torsoRight = attachment("RagdollTorsoRightAttachment", "Torso", Vector3.new(0.5, -1, 0)),
	head = attachment("RagdollHeadAttachment", "Head", Vector3.new(0, -0.5, 0)),
	leftArm = attachment("RagdollLeftArmAttachment", "Left Arm", Vector3.new(0.5, 1, 0)),
	rightArm = attachment("RagdollRightArmAttachment", "Right Arm", Vector3.new(-0.5, 1, 0)),
	neck = attachment("NeckAttachment", "Torso"),
	leftCollar = attachment("LeftCollarAttachment", "Torso"),
	rightCollar = attachment("RightCollarAttachment", "Torso"),
}

local function ballSocket(a0: Attachment?, a1: Attachment?, limits: Limits)
	if not a0 or not a1 then
		return nil
	end

	return {
		a0 = a0,
		a1 = a1,
		limits = limits,
	}
end

local function getR6Attachments(skeletonParent: Instance, scale: number)
	return {
		Head = ballSocket(
			R6_ATTACHMENTS.neck(skeletonParent, scale),
			R6_ATTACHMENTS.head(skeletonParent, scale),
			R6_HEAD_LIMITS
		),
		["Left Arm"] = ballSocket(
			R6_ATTACHMENTS.leftCollar(skeletonParent, scale),
			R6_ATTACHMENTS.leftArm(skeletonParent, scale),
			R6_SHOULDER_LIMITS
		),
		["Right Arm"] = ballSocket(
			R6_ATTACHMENTS.rightCollar(skeletonParent, scale),
			R6_ATTACHMENTS.rightArm(skeletonParent, scale),
			R6_SHOULDER_LIMITS
		),
		["Left Leg"] = ballSocket(
			R6_ATTACHMENTS.torsoLeft(skeletonParent, scale),
			R6_ATTACHMENTS.leftLeg(skeletonParent, scale),
			R6_HIP_LIMITS
		),
		["Right Leg"] = ballSocket(
			R6_ATTACHMENTS.torsoRight(skeletonParent, scale),
			R6_ATTACHMENTS.rightLeg(skeletonParent, scale),
			R6_HIP_LIMITS
		),
	}
end

local function findMotor(model: Model, motorName: string): Motor6D?
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Motor6D") and descendant.Name == motorName then
			return descendant
		end
	end

	return nil
end

local function getR15LegacyAttachments(skeletonParent: Instance, model: Model)
	local result = {}

	for motorName, limits in R15_CONFIG.JointLimits do
		local motor = findMotor(model, motorName)
		if not motor or not motor.Part0 or not motor.Part1 then
			continue
		end

		local part0 = skeletonParent:FindFirstChild(motor.Part0.Name)
		local part1 = skeletonParent:FindFirstChild(motor.Part1.Name)
		if not part0 or not part1 or not part0:IsA("BasePart") or not part1:IsA("BasePart") then
			continue
		end

		local a0 = Instance.new("Attachment")
		a0.Name = `Ragdoll{motorName}Attachment0`
		a0.CFrame = motor.C0
		a0.Parent = part0

		local a1 = Instance.new("Attachment")
		a1.Name = `Ragdoll{motorName}Attachment1`
		a1.CFrame = motor.C1
		a1.Parent = part1

		result[motor.Part1.Name] = {
			a0 = a0,
			a1 = a1,
			limits = limits,
		}
	end

	return result
end

function RigTypes.GetBodyParts(rigType: Enum.HumanoidRigType): { string }
	return getConfig(rigType).BodyParts
end

function RigTypes.GetRootBodyPart(rigType: Enum.HumanoidRigType): string
	return getConfig(rigType).RootBodyPart
end

function RigTypes.GetAttachments(
	skeletonParent: Instance,
	model: Model,
	scale: number,
	rigType: Enum.HumanoidRigType
)
	if rigType == Enum.HumanoidRigType.R15 then
		return getR15LegacyAttachments(skeletonParent, model)
	end

	return getR6Attachments(skeletonParent, scale)
end

function RigTypes.GetLegacyMotors(model: Model, rigType: Enum.HumanoidRigType): { Motor6D }
	local config = getConfig(rigType)
	local motors = {}

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Motor6D") and config.JointLimits[descendant.Name] then
			table.insert(motors, descendant)
		end
	end

	return motors
end

function RigTypes.FindRootJoint(model: Model, hrp: BasePart): Motor6D?
	local direct = hrp:FindFirstChild("RootJoint")
	if direct and direct:IsA("Motor6D") then
		return direct
	end

	for _, descendant in model:GetDescendants() do
		if not descendant:IsA("Motor6D") then
			continue
		end

		if descendant.Part0 ~= hrp and descendant.Part1 ~= hrp then
			continue
		end

		local lowerName = string.lower(descendant.Name)
		if string.find(lowerName, "root", 1, true) then
			return descendant
		end
	end

	return nil
end

function RigTypes.GetNoCollisions(skeletonFolder: Instance, rigType: Enum.HumanoidRigType)
	local list = {}
	local config = getConfig(rigType)

	for _, pair in config.NoCollisionPairs do
		local part1 = skeletonFolder:FindFirstChild(pair[1])
		local part2 = skeletonFolder:FindFirstChild(pair[2])

		if part1 and part2 and part1:IsA("BasePart") and part2:IsA("BasePart") then
			table.insert(list, {
				part1 = part1,
				part2 = part2,
			})
		end
	end

	return list
end

function RigTypes.GetNativeNoCollisionPairs(model: Model)
	local list = {}

	for _, pair in R15_CONFIG.NoCollisionPairs do
		local part1 = model:FindFirstChild(pair[1])
		local part2 = model:FindFirstChild(pair[2])

		if part1 and part2 and part1:IsA("BasePart") and part2:IsA("BasePart") then
			table.insert(list, {
				part1 = part1,
				part2 = part2,
			})
		end
	end

	return list
end

return RigTypes
