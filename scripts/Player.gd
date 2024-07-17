extends CharacterBody3D

class_name Player

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var JOY_SENS = 0.04
@export var MOUSE_SENS = 0.002
	
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var yaw: float

@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var pivot: Node3D = $CameraPivot
# TODO: This is an indoor sound. Should be an outdoor one
@onready var gunshot_sfx = $GunshotSFX
@onready var gunbolt_sfx = $GunboltSFX
@onready var shoot_hitbox = $ShootHitbox
@onready var shooting_delay = $ShootingDelay
@onready var gunempty_sfx = $GunemptySFX


var health = 5
var ammo = 5


func _ready():
	Global.player = self


func _input(event):	
	if event is InputEventMouseMotion and (Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or is_sniper_mode):
		yaw -= event.relative.x * MOUSE_SENS

@onready var camera_3d = $CameraPivot/Camera3D


var is_sniper_mode = false
const cam_over = Vector3(0, 10, 15)
const cam_over_angle = deg_to_rad(-30)
const cam_over_size = 12.5

const cam_fps = Vector3(0.5, 2.5, 0.15)
const cam_fps_angle = deg_to_rad(-10.0)
const cam_fps_size = 3.0

func _physics_process(delta: float) -> void:
	var look_vector = Input.get_vector("player_look_left", "player_look_right", "player_look_up", "player_look_down")
	if is_sniper_mode:
		yaw += look_vector.x * JOY_SENS * -1
	else:
		# This feels kinda wrong ... but idk. Maybe I'm overthinking it
		yaw += look_vector.x * JOY_SENS * -1
	
	if Input.is_action_just_pressed("player_aim"):
		is_sniper_mode = true
	if Input.is_action_just_released("player_aim"):
		is_sniper_mode = false
	
	if not is_sniper_mode:
		camera_3d.position = camera_3d.position.lerp(cam_over, 0.1)
		camera_3d.rotation.x = lerp_angle(camera_3d.rotation.x, cam_over_angle, 0.1)
		camera_3d.size = lerp(camera_3d.size, cam_over_size, 0.1)
	else:
		camera_3d.position = camera_3d.position.lerp(cam_fps, 0.1)
		camera_3d.rotation.x = lerp_angle(camera_3d.rotation.x, cam_fps_angle, 0.1)
		camera_3d.size = lerp(camera_3d.size, cam_fps_size, 0.1)
		
		if Input.is_action_just_pressed("player_shoot") and shooting_delay.is_stopped():
			if ammo > 1:
				
				var bodies = shoot_hitbox.get_overlapping_bodies()
				for body in bodies:
					if body.is_in_group("critters"):
						body.shot()
				
				gunshot_sfx.play()
				ammo -= 1
				shooting_delay.start()
				await get_tree().create_timer(0.4).timeout
				gunbolt_sfx.play()
			else:
				gunempty_sfx.play()
				
	
	rotation.y = yaw
	
	var input_dir := Input.get_vector("player_left", "player_right", "player_forward", "player_back").rotated(-rotation.y)
	var direction := (pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
func take_damage(amount):
	health += amount * -1
	print("Player takes damage. Total damage: ", health)
