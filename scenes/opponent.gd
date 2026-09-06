extends Node3D

@export var ball: RigidBody3D
@export var racket: Node3D
@export var bot_home: Marker3D

# Movement and accuracy
@export var follow_speed: float = 25.0
@export var reaction_delay: float = 0.15
@export var max_x: float = 3.5
@export var min_y: float = 0.2
@export var max_y: float = 3.0
@export var wobble_amount: float = 0.0
@export var prediction_limit: float = 1.5

# Swing
@export var swing_trigger_distance: float = 1.0
@export var swing_speed: float = 10.0

var normal_position: Vector3
var normal_x_rotation: float
var normal_y_rotation: float
var normal_z_rotation: float

var target_position := Vector3.ZERO
var delayed_ball_pos := Vector3.ZERO
var delay_buffer: Array[Vector3] = []

var swing_progress: float = 0.0
var is_swinging: bool = false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()

	if not is_instance_valid(racket):
		push_error("Assign the bot's racket in the Inspector.")
		set_physics_process(false)
		return

	if bot_home != null:
		racket.global_position = bot_home.global_position

	normal_position = racket.global_position
	normal_x_rotation = racket.rotation.x
	normal_y_rotation = racket.rotation.y
	normal_z_rotation = racket.rotation.z

	target_position = normal_position
	delayed_ball_pos = normal_position


func _physics_process(delta: float) -> void:
	if not is_instance_valid(ball):
		return

	# Predict the ball's position when it reaches the racket.
	var predicted_position: Vector3 = predict_ball_position()

	# Apply reaction delay to the predicted target.
	if reaction_delay <= 0.0:
		delay_buffer.clear()
		delayed_ball_pos = predicted_position
	else:
		delay_buffer.append(predicted_position)

		var delay_frames: int = maxi(
			1, int(ceil(reaction_delay / delta))
		)

		while delay_buffer.size() > delay_frames + 1:
			delay_buffer.pop_front()

		delayed_ball_pos = delay_buffer[0]

	# Optional aiming imperfection.
	var wobble := Vector3(
		rng.randf_range(-wobble_amount, wobble_amount),
		rng.randf_range(-wobble_amount, wobble_amount),
		0.0
	)

	# Keep the target within the bot's movement limits.
	target_position = Vector3(
		clampf(delayed_ball_pos.x + wobble.x, -max_x, max_x),
		clampf(delayed_ball_pos.y + wobble.y, min_y, max_y),
		normal_position.z
	)

	# Move toward the predicted interception point.
	var follow_weight: float = clampf(
		follow_speed * delta, 0.0, 1.0
	)

	racket.global_position.x = lerpf(
		racket.global_position.x,
		target_position.x,
		follow_weight
	)

	racket.global_position.y = lerpf(
		racket.global_position.y,
		target_position.y,
		follow_weight
	)

	# Check whether the ball is close and moving toward the bot.
	var z_distance: float = (
		normal_position.z - ball.global_position.z
	)

	var ball_close_z: bool = (
		absf(z_distance) < swing_trigger_distance
	)

	var ball_approaching: bool = (
		z_distance * ball.linear_velocity.z > 0.0
	)

	if ball_close_z and ball_approaching and not is_swinging:
		is_swinging = true
		swing_progress = 0.0

	# Swing the racket.
	if is_swinging:
		swing_progress = move_toward(
			swing_progress, 1.0, swing_speed * delta
		)

		racket.rotation.x = lerpf(
			normal_x_rotation,
			normal_x_rotation - PI / 3.0,
			sin(swing_progress * PI)
		)

		if swing_progress >= 1.0:
			is_swinging = false
			racket.rotation.x = normal_x_rotation
	else:
		racket.rotation.x = lerpf(
			racket.rotation.x,
			normal_x_rotation,
			clampf(5.0 * delta, 0.0, 1.0)
		)

	# Stay at the Z position chosen by BotHome.
	racket.global_position.z = normal_position.z


func predict_ball_position() -> Vector3:
	var ball_position: Vector3 = ball.global_position
	var velocity: Vector3 = ball.linear_velocity

	# Avoid dividing by zero.
	if absf(velocity.z) < 0.01:
		return ball_position

	var time_to_racket: float = (
		(normal_position.z - ball_position.z) / velocity.z
	)

	# The ball is moving away from the racket's Z plane.
	if time_to_racket <= 0.0:
		return ball_position

	time_to_racket = minf(
		time_to_racket, maxf(prediction_limit, 0.0)
	)

	# These properties come from your ball.gd script.
	var sideways_accel: float = float(
		ball.get("sideways_acceleration")
	)

	var gravity: float = (
		float(ball.get("gravity_strength")) * ball.gravity_scale
	)

	var acceleration := Vector3(
		sideways_accel, -gravity, 0.0
	)

	return (
		ball_position
		+ velocity * time_to_racket
		+ 0.5 * acceleration * time_to_racket * time_to_racket
	)
