extends CharacterBody3D

class_name Player

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENS = 0.002
	
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var yaw: float

@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var pivot: Node3D = $CameraPivot

var damage_taken = 0

func _input(event):	
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		yaw -= event.relative.x * MOUSE_SENS

func _physics_process(delta: float) -> void:
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
	
func take_damage():
	damage_taken += 1
	print("Player takes damage. Total damage: ", damage_taken)
