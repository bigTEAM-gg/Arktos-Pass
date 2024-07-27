extends CharacterBody3D


class_name Monster


const SPEED = 18.0
const IS_HIT_ESCAPE = Vector3(10, 0, 10)
const DEBUG = false


@onready var hurtbox = $Hurtbox
@onready var target_search_area: Area3D = $TargetSearchArea
@onready var monster_sprite = $MonsterSprite


@export var player_slow_attack_delay := 1.0
@export var player_slow_attack_speed_thresh := 2.0
@export var delay_decision_time := 0.5


enum MonsterState { IDLE, STALKING }
var monster_state: MonsterState
var target = null
var previous_player_pos = null
var player_is_slow
var player_is_slow_accum := 0.0
var player_is_around := false
var trees_around: Array[FirTree] = []
var delay_decision_accum := 0.0


func _ready():
	hurtbox.body_entered.connect(_on_body_entered)
	monster_state = MonsterState.STALKING
	Global.monster = self


func _physics_process(delta):
	var player = Global.player
	if not is_instance_valid(player):
		return
	match monster_state:
		MonsterState.IDLE:
			pass
		MonsterState.STALKING:
			_look_around(player)
			if target == null:
				_track_player(delta, player)
				if _delay_decision(delta):
					target = _find_attack_target(player)
				else:
					# Hack to keep velocity very low for animation speed
					# but also maintain the sign enough to look the right direction
					velocity = velocity.sign() / 5
			elif _move_to_target(target):
				target = null
	_resolve_sprite()

# https://kidscancode.org/godot_recipes/3.x/2d/8_direction/
const anim_dirs = ['e', 'se', 's', 'sw', 'w', 'nw', 'n', 'ne']

func _resolve_sprite():
	var direction = Vector2(velocity.x, velocity.z).angle() + get_viewport().get_camera_3d().global_rotation.y
	var d = snapped(direction, PI/4) / (PI/4)
	d = wrapi(int(d), 0, 8)
	
	var current_animation = "walk"
	
	monster_sprite.speed_scale = velocity.length() / 7
	
	var next_animation = current_animation + '_' + anim_dirs[d]
	if monster_sprite.animation != next_animation:
		monster_sprite.play(next_animation)

func _look_around(player):
	player_is_around = false
	trees_around = []
	var overlapping := target_search_area.get_overlapping_areas()
	for a in overlapping:
		if a is FirTree:
			trees_around.append(a as FirTree)
	var overlapping_bodies := target_search_area.get_overlapping_bodies()
	for a in overlapping_bodies:
		if a.is_in_group("player"):
			player_is_around = true
	var player_pos = player.global_position
	trees_around.sort_custom(func(a, b): return (a.global_position - player_pos).length() < (b.global_position - player_pos).length())
	#if DEBUG: _debug_closest_tree()
	#if DEBUG: print("Monster loooked around, found ", trees_around.size(), " trees. Player: ", player_is_around, ".")


func _track_player(delta: float, player):
	if previous_player_pos != null:
		var frame_vel = null
		var moved_dist = (player.global_position - previous_player_pos).length()
		if !is_zero_approx(delta):
			frame_vel = moved_dist / delta
		if player_is_around:
			player_is_slow = (frame_vel != null && frame_vel < player_slow_attack_speed_thresh)
			if player_is_slow:
				player_is_slow_accum += delta
			else:
				player_is_slow_accum += 0.0
		else:
			player_is_slow = false
			player_is_slow_accum = 0.0
		if DEBUG: print("Monster tracks player. frame_vel = ", frame_vel, ", around = ", player_is_around, ", accum = ",  player_is_slow_accum, ".")
	previous_player_pos = player.global_position


func _delay_decision(delta: float):
	delay_decision_accum += delta
	if delay_decision_accum > delay_decision_time:
		delay_decision_accum = 0.0
		return true
	return false
	

func _find_attack_target(player):
	var target = null
	if player_is_around && player_is_slow:
		if player_is_slow_accum > player_slow_attack_delay:
			player_is_slow_accum = 0.0
			if player_is_around:
				if DEBUG: print("Monster's target is player")
				target = player.global_position
	elif trees_around.size() > 0:
		target = trees_around[0].global_position
	return target


func _find_retreat_target():
	var target = null
	if trees_around.size() > 0:
		target = trees_around[trees_around.size() - 1].global_position
	return target


func _move_to_target(target: Vector3):
	var displacement = target - global_position
	var dist = displacement.length()
	if dist > 0.2:
		var new_velocity = displacement.normalized()
		new_velocity = new_velocity * SPEED
		velocity = new_velocity
		move_and_slide()
		return false
	else:
		return true


func _debug_closest_tree():
	if trees_around.size() > 0:
		for tree in trees_around:
			tree.shake = 0
		
		trees_around[0].shake = 100


func shot():
	# This might have a little stale data, but should be ok, trees_around is reset and updated in one go in physics_process
	target = _find_retreat_target()


func _on_body_entered(body):
	if body.is_in_group("player"):
		target = null
		body.take_damage(1)
		target = _find_retreat_target()
