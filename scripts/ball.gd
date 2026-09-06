extends RigidBody3D

@export var racket: AnimatableBody3D
@export var bot_racket: AnimatableBody3D
@export var floor: Node3D
@export var score_label: Label3D
@export var table:Node3D
@export var topspin_strength: float = 4.0
@export var max_topspin: float = 60.0
@export var topspin_dip: float = 0.05

@export var player_landing: Marker3D
@export var bot_landing: Marker3D

# Height of the arc above the higher of its start/end points.
@export var arc_height: float = 0.8

# Maximum sideways offset from either landing marker.
# Keep this comfortably inside the table's edges.
@export var max_aim_offset: float = 0.5
@export var crosscourt_strength: float = 0.6

# Spin tuning.
@export var max_spin: float = 30.0
@export var spin_curve: float = 1.5
@export var spin_direction: float = 1.0

var has_been_hit: bool = false
signal hit_floor

var pending_racket: Node3D
var sideways_acceleration: float = 0.0
var gravity_strength: float = 9.8

var player_rest_basis: Basis
var bot_rest_basis: Basis
var spawn_position: Vector3
var is_resetting := false

var last_table_side: String = ""
var player_score: int = 0
var bot_score: int = 0

var player_previous_basis: Basis
var bot_previous_basis: Basis

var player_pitch_velocity: float = 0.0
var bot_pitch_velocity: float = 0.0
var current_topspin: float = 0.0

func _ready() -> void:
	assert(racket != null, "Assign the player's racket.")
	assert(bot_racket != null, "Assign the bot's racket.")
	assert(player_landing != null, "Assign PlayerLanding.")
	assert(bot_landing != null, "Assign BotLanding.")

	gravity_strength = float(
		ProjectSettings.get_setting("physics/3d/default_gravity")
	)

	player_rest_basis = racket.global_basis.orthonormalized()
	bot_rest_basis = bot_racket.global_basis.orthonormalized()
	player_previous_basis = racket.global_basis.orthonormalized()
	bot_previous_basis = bot_racket.global_basis.orthonormalized()
	
	gravity_scale = 0.0
	freeze = false
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 8

	# The calculated arc assumes no linear drag.
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	linear_damp = 0.0

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	spawn_position = global_position
func _physics_process(delta: float) -> void:
	var player_basis: Basis = racket.global_basis.orthonormalized()
	var bot_basis: Basis = bot_racket.global_basis.orthonormalized()

	player_pitch_velocity = measure_pitch_velocity(
		player_previous_basis, player_basis, delta
	)
	bot_pitch_velocity = measure_pitch_velocity(
		bot_previous_basis, bot_basis, delta
	)

	player_previous_basis = player_basis
	bot_previous_basis = bot_basis


func measure_pitch_velocity(
	previous: Basis,
	current: Basis,
	delta: float
) -> float:
	# Rotation since the previous frame, in the racket's local axes.
	var change: Basis = previous.transposed() * current
	var rotation: Quaternion = change.get_rotation_quaternion()

	# Use the shortest rotation.
	if rotation.w < 0.0:
		rotation = -rotation

	if rotation.get_angle() < 0.00001:
		return 0.0

	return (
		rotation.get_axis().x
		* rotation.get_angle()
		/ maxf(delta, 0.00001)
	)
	
	
func _on_body_entered(body: Node) -> void:
	if is_resetting:
		return

	if body == racket or body == bot_racket:
		has_been_hit = true
		gravity_scale = 1.0
		pending_racket = body as Node3D

	elif body == table:
		# Compare Z distances to identify the side of the table.
		var player_distance: float = absf(
			global_position.z - player_landing.global_position.z
		)
		var bot_distance: float = absf(
			global_position.z - bot_landing.global_position.z
		)

		if player_distance < bot_distance:
			last_table_side = "player"
		else:
			last_table_side = "bot"

	elif body == floor:
		is_resetting = true

		if last_table_side == "player":
			bot_score += 1
		elif last_table_side == "bot":
			player_score += 1

		score_label.text = str(player_score) + " : " + str(bot_score)

		hit_floor.emit()
		reset_ball.call_deferred()


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if is_instance_valid(pending_racket):
		launch_shot(state, pending_racket)
		pending_racket = null

	elif has_been_hit:
		# Actual sideways movement, in addition to visual rotation.
		state.linear_velocity += (
			Vector3.RIGHT * sideways_acceleration * state.step
		)
		state.linear_velocity.y -= (
			current_topspin * topspin_dip * state.step
		)


func launch_shot(
	state: PhysicsDirectBodyState3D,
	hitting_racket: Node3D
) -> void:
	var target: Vector3
	var rest_basis: Basis

	if hitting_racket == racket:
		target = bot_landing.global_position
		rest_basis = player_rest_basis
	else:
		target = player_landing.global_position
		rest_basis = bot_rest_basis

	var centre_x: float = (
		player_landing.global_position.x
		+ bot_landing.global_position.x
	) * 0.5

	# Left racket -> right target; right racket -> left target.
	var racket_offset: float = (
		hitting_racket.global_position.x - centre_x
	)

	target.x += clampf(
		-racket_offset * crosscourt_strength,
		-max_aim_offset,
		max_aim_offset
	)

	# Read roll using the racket's right axis relative to rest.
	# A local X swing does not itself rotate this right axis.
	var right_axis: Vector3 = (
		hitting_racket.global_basis.x.normalized()
	)

	var roll: float = atan2(
		right_axis.dot(rest_basis.y),
		right_axis.dot(rest_basis.x)
	)

	var spin_amount: float = clampf(
		roll / (PI / 2.0), -1.0, 1.0
	) * spin_direction

	# Positive roll gives a leftward curve along world X.
	sideways_acceleration = -spin_amount * spin_curve

	var start: Vector3 = state.transform.origin
	var gravity: float = maxf(gravity_strength, 0.01)
	var apex_y: float = (
		maxf(start.y, target.y) + maxf(arc_height, 0.05)
	)

	var upward_speed: float = sqrt(
		2.0 * gravity * (apex_y - start.y)
	)

	var flight_time: float = (
		upward_speed / gravity
		+ sqrt(2.0 * (apex_y - target.y) / gravity)
	)

	var displacement: Vector3 = target - start

	# Compensate for the sideways curve so the shot still aims
	# at the selected landing point.
	state.linear_velocity = Vector3(
		displacement.x / flight_time
			- 0.5 * sideways_acceleration * flight_time,
		upward_speed,
		displacement.z / flight_time
	)

	# Rotate the ball around its vertical axis.
	var pitch_velocity: float
	if hitting_racket == racket:
		pitch_velocity = player_pitch_velocity
	else:
		pitch_velocity = bot_pitch_velocity

	current_topspin = minf(
		absf(pitch_velocity) * topspin_strength,
		max_topspin
	)

	var horizontal_direction: Vector3 = Vector3(
		displacement.x, 0.0, displacement.z
	).normalized()

	# Forward-rolling axis changes with the shot's direction.
	var topspin_axis: Vector3 = Vector3.UP.cross(horizontal_direction)

	state.angular_velocity = (
		Vector3(
			0.0,
			-spin_amount * signf(displacement.z) * max_spin,
			0.0
		)
		+ topspin_axis * current_topspin
	)
	
func reset_ball() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sideways_acceleration = 0.0
	current_topspin = 0.0
	pending_racket = null

	global_position = spawn_position
	gravity_scale = 0.0
	has_been_hit = false
	sleeping = false
	is_resetting = false
	last_table_side = ""
	
