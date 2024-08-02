extends CharacterBody3D

class_name Player

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var JOY_SENS = 0.04
@export var MOUSE_SENS = 0.002
@export var heal_point = 2
	
	
var yaw: float
var updown: float

#scope sprite
@onready var scope = $Scope
#bullet sprites
@onready var bullet_count = $AmmoCount/Control/BulletCount
@onready var total_ammo = $AmmoCount/Control/TotalAmmo

#ammo display
@onready var health_count = $HealthUI/HealthCount


@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var pivot: Node3D = $CameraPivot
# TODO: This is an indoor sound. Should be an outdoor one
@onready var gunshot_sfx = $GunshotSFX
@onready var gunbolt_sfx = $GunboltSFX
@onready var shoot_hitbox = $ShootHitbox
@onready var shooting_delay = $ShootingDelay
@onready var gunempty_sfx = $GunemptySFX
@onready var hit_animation: AnimatedSprite3D = $AnimatedSprite3D
@onready var player_sprite = $PlayerSprite
@onready var wt = $WT
@onready var reloadsfx = $Reload


var health = 5
var ammo
@export var ammo_magazine_capacity = 2
@export var ammo_total = 10


signal sniper_mode_changed(current: bool)


func _ready():
	Global.player = self
	ammo = ammo_magazine_capacity
	sniper_mode_changed.connect(Global.handle_player_sniper_mode_changed)
	Global.beepradio.connect(wtbeep)
	Global.reloadammo.connect(reload)
	Global.takedamage.connect(take_damage)
	Global.healthpickup.connect(heal)
	Global.ammopickup.connect(ammo_pickup)
	
	total_ammo.text = "%s" % ammo_total

func _process(_delta):
	RenderingServer.global_shader_parameter_set("player_position", global_position)
	if Input.is_action_just_pressed("reload"):
		Global.reloadammo.emit()
		

func _input(event):	
	if event is InputEventMouseMotion and (Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or is_sniper_mode):
		yaw -= event.relative.x * MOUSE_SENS
		updown -= event.relative.y * MOUSE_SENS

@onready var camera_3d = $CameraPivot/Camera3D

var is_in_dialog = false
var is_sniper_mode = false
var is_sniper_mode_ready = false
const cam_over = Vector3(0, 10, 15)
const cam_over_angle = deg_to_rad(-30)
const cam_over_size = 12.5

const cam_fps = Vector3(0.5, 2.5, 0.15)
const cam_fps_angle = deg_to_rad(-10.0)
const cam_fps_size = 3.0

func _physics_process(delta: float) -> void:
	if !is_in_dialog:
		process_player_controls()
	process_sniper_mode()
	_resolve_sprite()


# https://kidscancode.org/godot_recipes/3.x/2d/8_direction/
const anim_dirs = ['e', 'se', 's', 'sw', 'w', 'nw', 'n', 'ne']

func _resolve_sprite():
	var direction = Vector2(velocity.x, velocity.z).angle() + get_viewport().get_camera_3d().global_rotation.y
	var d = snapped(direction, PI/4) / (PI/4)
	d = wrapi(int(d), 0, 8)
	
	var current_animation = "walk"
	
	player_sprite.speed_scale = velocity.length() / 3
	
	var next_animation = current_animation + '_' + anim_dirs[d]
	
	if is_sniper_mode:
		next_animation = "walk_n"
		player_sprite.speed_scale = 0
	
	if player_sprite.animation != next_animation:
		player_sprite.play(next_animation)


func process_player_controls():
	var look_vector = Vector2.ZERO#Input.get_vector("player_look_left", "player_look_right", "player_look_up", "player_look_down")
	if is_sniper_mode:
		yaw += look_vector.x * JOY_SENS * -1
		updown += look_vector.y * JOY_SENS * -1
	#else:
		# This feels kinda wrong ... but idk. Maybe I'm overthinking it
		#yaw += look_vector.x * JOY_SENS * -1
	
	if Input.is_action_just_pressed("player_aim"):
		is_sniper_mode = true
	if Input.is_action_just_released("player_aim"):
		is_sniper_mode = false
	
	if Input.is_action_just_pressed("player_shoot") and shooting_delay.is_stopped():
		if ammo >= 1:
			var bodies = shoot_hitbox.get_overlapping_bodies()
			for body in bodies:
				if body.is_in_group("critters"):
					body.shot(global_position)
			gunshot_sfx.play()
			ammo -= 1
			bullet_count.text = "%s" % ammo
			shooting_delay.start()
			await get_tree().create_timer(0.4).timeout
			gunbolt_sfx.play()	
			
		else:
			gunempty_sfx.play()
			
		
	rotation.x = updown
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

func process_sniper_mode():
	
	if not is_sniper_mode:
		scope.visible = false
		player_sprite.visible = true
		camera_3d.position = camera_3d.position.lerp(cam_over, 0.1)
		camera_3d.rotation.x = lerp_angle(camera_3d.rotation.x, cam_over_angle, 0.1)
		camera_3d.size = lerp(camera_3d.size, cam_over_size, 0.1)
		if (camera_3d.position - cam_fps).length() > 1.0:
			if is_sniper_mode_ready:
				sniper_mode_changed.emit(false)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			is_sniper_mode_ready = false
	else:
		scope.visible = true
		player_sprite.visible = false
		camera_3d.position = camera_3d.position.lerp(cam_fps, 0.1)
		camera_3d.rotation.x = lerp_angle(camera_3d.rotation.x, cam_fps_angle, 0.1)
		camera_3d.size = lerp(camera_3d.size, cam_fps_size, 0.1)
		if (camera_3d.position - cam_fps).length() < 1.0:
			if !is_sniper_mode_ready:
				sniper_mode_changed.emit(true)
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			is_sniper_mode_ready = true
	
func take_damage(amount):
	health += amount * -1
	health_count.text = "%s" % health
	#print("Player takes damage. Total damage: ", health)
	hit_animation.play()
	
func heal():
	health = health + heal_point
	health_count.text = "%s" % health
	
func wtbeep():
	wt.play()
	
func reload():
	
	if (ammo == ammo_magazine_capacity):
		print ("full ammo")
		
	if (ammo < ammo_magazine_capacity) and (ammo_total >= ammo_magazine_capacity):
		ammo_total = ammo_total - (ammo_magazine_capacity - ammo)
		ammo = ammo_magazine_capacity
		await get_tree().create_timer(0.2).timeout
		reloadsfx.play()
		bullet_count.text = "%s" % ammo
		
	if (ammo < ammo_magazine_capacity) and (ammo_total < ammo_magazine_capacity) and (ammo_total > 0):
		ammo = ammo + ammo_total
		ammo_total = 0
		await get_tree().create_timer(0.2).timeout
		reloadsfx.play()
		bullet_count.text = "%s" % ammo
		
	if (ammo < ammo_magazine_capacity) and (ammo_total <= 0):
		print ("not enough ammo")
		
	total_ammo.text = "%s" % ammo_total
	print("ammo reload complete")
	print("total new ammo ", ammo)
	print("total ammo left:  ", ammo_total)
	
func ammo_pickup():
	ammo_total= ammo_total + 6
	total_ammo.text = "%s" % ammo_total
	reloadsfx.play()




