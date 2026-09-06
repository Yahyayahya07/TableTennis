extends Node3D

@export var racket: Node3D
@export var opponent_racket: Node3D
@export var floor: CSGMesh3D

var ball_scene = preload("res://ball.tscn")
var current_ball: RigidBody3D = null

func _ready() -> void:
	# Use the ball already placed in the scene instead of spawning a new one
	current_ball = get_node("ball")  # adjust name if different
	current_ball.hit_floor.connect(_on_ball_hit_floor)

func destroy_ball() -> void:
	if current_ball:
		current_ball.queue_free()
		current_ball = null

func spawn_ball() -> void:
	current_ball = ball_scene.instantiate()
	add_child(current_ball)
	current_ball.racket = racket
	current_ball.floor = floor
	current_ball.hit_floor.connect(_on_ball_hit_floor)

func _on_ball_hit_floor() -> void:
	destroy_ball()
	spawn_ball()
