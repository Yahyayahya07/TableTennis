extends Node3D

@export var racket: Node3D
var normal_z: float
var normal_x_rotation: float
var normal_y_rotation: float
var normal_z_rotation: float


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	MouseUtils.set_center(get_viewport())
	normal_z = racket.global_position.z
	normal_x_rotation = racket.rotation.x
	normal_z_rotation = racket.rotation.z
	normal_y_rotation = racket.rotation.y
	

func _input(ev):
	if ev is InputEventMouseMotion:
		MouseUtils.update_from_motion(ev, get_viewport())
		if Input.is_action_pressed("left_click"):    
			racket.global_position.z += ev.relative.y * 0.008
		else:
			racket.global_position.z = normal_z
   #while holding left click move in z axis as opposed to y

		
	if Input.is_action_just_pressed("ui_cancel"):
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
func _physics_process(delta: float) -> void:
	var cam := $Camera3D

	var mousePos := MouseUtils.virtual_cursor

	var rayStart: Vector3 = cam.project_ray_origin(mousePos)
	var direction: Vector3 = cam.project_ray_normal(mousePos)
	var plane: Plane
	
	plane = Plane(Vector3.FORWARD)

	var intersection = plane.intersects_ray(rayStart, direction)

	if intersection:
		racket.global_position.x = intersection.x
		racket.global_position.y = intersection.y
	
	
	#rotate along z-axis
		
	var rotation_speedz := 0.0
	var max_rotation_speedz := 800
	var accelerationz := 800.0
	
	if Input.is_action_pressed("ui_left"):
		rotation_speedz = move_toward(rotation_speedz, max_rotation_speedz, accelerationz * delta)
	elif Input.is_action_pressed("ui_right"):
		rotation_speedz = move_toward(rotation_speedz, -max_rotation_speedz, accelerationz * delta)
	else:
		rotation_speedz = move_toward(rotation_speedz, 0.0, accelerationz * delta)
		racket.rotation.z = normal_z_rotation
	racket.rotate_z(rotation_speedz * delta)
	
	racket.rotation.z = clamp(
	racket.rotation.z,
	normal_z_rotation - PI / 2,
	normal_z_rotation + PI / 2
)
	
	#rotate along x axis
	
	var rotation_speedy := 0.0
	var max_rotation_speedy := 5000
	var accelerationy := 5000.0
		
	if Input.is_action_pressed("right_click"):
		rotation_speedy = move_toward(rotation_speedy, max_rotation_speedy, accelerationy * delta)
		
	racket.rotate_object_local(Vector3.RIGHT, -rotation_speedy * delta)

	racket.rotation.x = clamp(
		racket.rotation.x,
		normal_x_rotation - PI / 3,
		normal_x_rotation
	)
	
	
	var rotation_speedw := 0.0
	var max_rotation_speedw := 1000
	var accelerationw := 1000.0
	
	
	if Input.is_action_pressed("ui_up"):
		rotation_speedw = move_toward(rotation_speedw, max_rotation_speedw, accelerationw * delta)
		
	racket.rotate_object_local(Vector3.RIGHT, -rotation_speedw * delta)

	racket.rotation.x = clamp(
		racket.rotation.x,
		normal_x_rotation - 7*PI / 9,
		normal_x_rotation
	)
	
	
	if not Input.is_action_pressed("right_click") and not Input.is_action_pressed("ui_up"):
		rotation_speedy = move_toward(rotation_speedy, 0.0, accelerationy * delta)
		rotation_speedw = move_toward(rotation_speedw, 0.0, accelerationw * delta)
		racket.rotation.x = normal_x_rotation
	

	if Input.is_action_pressed("middle_click"): #hopefully a tempory racket reset transofmation button as opposed to permanent
		racket.rotation.x = normal_x_rotation
		racket.rotation.z = normal_z_rotation
		racket.rotation.y = normal_y_rotation
	
		
	#print(intersection.x)
	#print(racket.global_position.x)
	


func _on_ball_body_entered(body: Node) -> void:
	pass # Replace with function body.
