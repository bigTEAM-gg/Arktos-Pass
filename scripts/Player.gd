extends CharacterBody3D

class_name Player

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENS = 0.002

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var yaw: float

@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var pivot: Node3D = $CameraPivot

func _input(event):	
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		yaw -= event.relative.x * MOUSE_SENS

@onready var camera_3d = $CameraPivot/Camera3D
var is_sniper_mode = false
const cam_over = Vector3(0, 15, 25)
const cam_over_angle = deg_to_rad(-30)
const cam_over_size = 12.5

const cam_fps = Vector3(0.5, 1.5, 0.15)
const cam_fps_angle = deg_to_rad(0.0)
const cam_fps_size = 3.0

func _physics_process(delta: float) -> void:
	
	if Input.is_action_just_pressed("dialogic_default_action"):
		is_sniper_mode = not is_sniper_mode
	
	if not is_sniper_mode:
		camera_3d.position = camera_3d.position.lerp(cam_over, 0.1)
		camera_3d.rotation.x = lerp_angle(camera_3d.rotation.x, cam_over_angle, 0.1)
		#camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera_3d.size = lerp(camera_3d.size, cam_over_size, 0.1)
	else:
		camera_3d.position = camera_3d.position.lerp(cam_fps, 0.1)
		camera_3d.rotation.x = lerp_angle(camera_3d.rotation.x, cam_fps_angle, 0.1)
		#camera_3d.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera_3d.size = lerp(camera_3d.size, cam_fps_size, 0.1)
	
	pivot.rotation.y = yaw
	
	var input_dir := Input.get_vector("player_left", "player_right", "player_forward", "player_back")
	var direction := (pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
