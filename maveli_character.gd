extends Node3D

@onready var root: Node3D = $Root
@onready var torso: Node3D = $Root/Torso
@onready var head: Node3D = $Root/Torso/Head
@onready var left_arm: Node3D = $Root/Torso/LeftArmPivot
@onready var right_arm: Node3D = $Root/Torso/RightArmPivot
@onready var umbrella: Node3D = $Root/Torso/LeftArmPivot/UmbrellaRoot
@onready var left_leg: Node3D = $Root/LeftLegPivot
@onready var right_leg: Node3D = $Root/RightLegPivot

var base_torso_y: float = 0.88
var run_cycle: float = 0.0

func _ready() -> void:
	if torso != null:
		base_torso_y = torso.position.y

func update_animation(delta: float, is_grounded: bool, speed: float, vy: float, vx: float) -> void:
	if is_grounded:
		var step_freq := speed * 1.5
		run_cycle += delta * step_freq
		
		# Leg stride running swing
		var leg_swing := sin(run_cycle) * 0.75
		left_leg.rotation.x = leg_swing
		right_leg.rotation.x = -leg_swing
		
		# Arm running swing
		right_arm.rotation.x = leg_swing * 0.7
		left_arm.rotation.x = -leg_swing * 0.4
		
		# Torso running bounce & swagger
		var bob := absf(sin(run_cycle)) * 0.07
		torso.position.y = base_torso_y + bob
		torso.rotation.z = sin(run_cycle * 0.5) * 0.06
		torso.rotation.y = sin(run_cycle * 0.5) * 0.04
		
		# Umbrella gentle dynamic sway in wind
		umbrella.rotation.x = sin(run_cycle * 0.8) * 0.12
		umbrella.rotation.z = 0.7 + cos(run_cycle * 0.6) * 0.08
		
		# Head focus
		head.rotation.x = -0.05 + sin(run_cycle) * 0.03
	else:
		# Jump pose: legs tucked/extended, arms up, umbrella held high
		var t := 10.0 * delta
		left_leg.rotation.x = lerpf(left_leg.rotation.x, -0.4, t)
		right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.35, t)
		left_arm.rotation.x = lerpf(left_arm.rotation.x, -0.5, t)
		right_arm.rotation.x = lerpf(right_arm.rotation.x, -0.6, t)
		torso.position.y = lerpf(torso.position.y, base_torso_y, t)
		torso.rotation.z = lerpf(torso.rotation.z, 0.0, t)
		torso.rotation.y = lerpf(torso.rotation.y, 0.0, t)
		umbrella.rotation.x = lerpf(umbrella.rotation.x, -0.2, t)
