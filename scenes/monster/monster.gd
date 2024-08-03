# TODO:
# - what if player manages to run away while monster is lunging -- no exit from that ai state until player is hit

extends CharacterBody3D


class_name Monster


const DEBUG = true
const SAFE_ZONE_RADIUS = 3.0
const DIST_CLOSE = 0.2


@onready var hurtbox = $Hurtbox
@onready var target_search_area: Area3D = $TargetSearchArea
@onready var monster_sprite = $FoggyAnimatedSprite
@onready var safe_zone_scene := preload("res://scenes/safe_zone.tscn")



enum MonsterAiMode { IDLE, STALKING_1, STALKING_2, STALKING_3 }
@export var monster_ai_mode: MonsterAiMode = MonsterAiMode.IDLE
enum StalkingState { WAIT, FOLLOW_FIND_TARGET, FOLLOW_GO_TO_TARGET, ATTACK_CREEP, ATTACK_LUNGE, RETREAT_FIND_TARGET, RETREAT }
var stalking_state: StalkingState


func _ready():
	hurtbox.body_entered.connect(_on_body_entered)
	#monster_ai_mode = MonsterAiMode.STALKING_3
	Global.monster = self


func _physics_process(delta):
	if not is_instance_valid(Global.player):
		print("Monser.gd: Player instance invalid")
		return
	if not is_instance_valid(Global.level):
		print("Monser.gd: Level instance invalid")
		return
	match monster_ai_mode:
		MonsterAiMode.IDLE:
			pass
		MonsterAiMode.STALKING_1:
			_process_monster_stalking_1(delta)
		MonsterAiMode.STALKING_2:
			_process_monster_stalking_2(delta)
		MonsterAiMode.STALKING_3:
			_process_monster_stalking_3(delta)
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

########### COMMON VARS ###########

var started_creeping_at_tree: FirTree = null
var player_is_in_safe_zone := false

var retreat_target = null
var creep_timer := 0.0
var retreat_timer := 0.0
var aggressiveness_cap := 0.0
var aggressiveness_cap_timer := 0.0
var follow_target = null
var closest_tree: FirTree = null
var farthest_tree: FirTree = null
var wait_timer := 0.0

################### STALKING 1 ###################

const S1_WAIT_PERIOD := 2.0
const S1_MOVEMENT_SPEED := 8.0
const S1_PLAYER_LOOKAHEAD := 15.0

func _process_monster_stalking_1(delta: float):
	match stalking_state:
		StalkingState.WAIT:
			wait_timer -= delta
			if wait_timer < 0.0:
				wait_timer = 0.0
				_set_stalking_state(StalkingState.FOLLOW_FIND_TARGET)
		StalkingState.FOLLOW_FIND_TARGET:
			_check_trees(S1_PLAYER_LOOKAHEAD)
			if closest_tree == null:
				_set_stalking_state(StalkingState.WAIT)
				return
			_set_stalking_state(StalkingState.FOLLOW_GO_TO_TARGET)
			follow_target = closest_tree.global_position
		StalkingState.FOLLOW_GO_TO_TARGET:
			if follow_target == null:
				_set_stalking_state(StalkingState.FOLLOW_FIND_TARGET)
				return
			if _move_to_target(follow_target, S1_MOVEMENT_SPEED):
				_set_stalking_state(StalkingState.WAIT)
				wait_timer = S1_WAIT_PERIOD
		_:
			print("ERROR: Unhandled stalking state: Mode: ", MonsterAiMode.keys()[monster_ai_mode], "Stalking state: ", StalkingState.keys()[stalking_state])


################### STALKING 2 ###################

const S2_MOVEMENT_SPEED := 12.0
const S2_CREEP_PERIOD := 5.0
const S2_WAIT_PERIOD := 2.0
const S2_RETREAT_PERIOD := 5.0
const S2_CREEP_SPEED := 0.3
const S2_LUNGE_SPEED := 20.0
const S2_PLAYER_LOOKAHEAD := 15.0

func _process_monster_stalking_2(delta: float):
	match stalking_state:
		StalkingState.WAIT:
			wait_timer -= delta
			if wait_timer < 0.0:
				wait_timer = 0.0
				_check_trees(S2_PLAYER_LOOKAHEAD)
				if closest_tree != null && _am_at_target(closest_tree.global_position):
					_set_stalking_state(StalkingState.ATTACK_CREEP)
					started_creeping_at_tree = closest_tree
					creep_timer = S2_CREEP_PERIOD
				else:
					_set_stalking_state(StalkingState.FOLLOW_FIND_TARGET)
		StalkingState.FOLLOW_FIND_TARGET:
			_check_trees(S2_PLAYER_LOOKAHEAD)
			if closest_tree == null:
				_set_stalking_state(StalkingState.WAIT)
				return
			_set_stalking_state(StalkingState.FOLLOW_GO_TO_TARGET)
			follow_target = closest_tree.global_position
		StalkingState.FOLLOW_GO_TO_TARGET:
			if follow_target == null:
				_set_stalking_state(StalkingState.FOLLOW_FIND_TARGET)
				return
			if _move_to_target(follow_target, S2_MOVEMENT_SPEED):
				_set_stalking_state(StalkingState.WAIT)
				wait_timer = S2_WAIT_PERIOD
		StalkingState.ATTACK_CREEP:
			_check_trees(S2_PLAYER_LOOKAHEAD)
			if closest_tree != started_creeping_at_tree:
				_set_stalking_state(StalkingState.FOLLOW_FIND_TARGET)
			else:
				_move_to_target(Global.player.global_position, S2_CREEP_SPEED)
				creep_timer -= delta
				if creep_timer < 0.0:
					creep_timer = 0.0
					_set_stalking_state(StalkingState.ATTACK_LUNGE)
		StalkingState.ATTACK_LUNGE:
			#_check_trees(S2_PLAYER_LOOKAHEAD)
			#if closest_tree != started_creeping_at_tree:
				#_set_stalking_state(StalkingState.FOLLOW_FIND_TARGET)
			if _move_to_target(Global.player.global_position, S2_LUNGE_SPEED):
				_set_stalking_state(StalkingState.RETREAT_FIND_TARGET)
		StalkingState.RETREAT_FIND_TARGET:
			_check_trees(S2_PLAYER_LOOKAHEAD)
			if farthest_tree == null:
				_set_stalking_state(StalkingState.WAIT)
				return
			_set_stalking_state(StalkingState.RETREAT)
			retreat_target = farthest_tree.global_position
		StalkingState.RETREAT:
			if retreat_target != null:
				if _move_to_target(retreat_target, S2_MOVEMENT_SPEED):
					retreat_target = null
					retreat_timer = S2_RETREAT_PERIOD
			elif player_is_in_safe_zone:
				pass
			else:
				retreat_timer -= delta
				if retreat_timer < 0.0:
					retreat_timer = 0.0
					_set_stalking_state(StalkingState.FOLLOW_FIND_TARGET)
		_:
			print("ERROR: Unhandled stalking state: Mode: ", MonsterAiMode.keys()[monster_ai_mode], "; Stalking state: ", StalkingState.keys()[stalking_state])


################### STALKING 3 ###################

var movement_speed_a := 10.0
var movement_speed_b := 15.0
var lunge_speed := 25.0
var creep_speed := 0.5
var wait_period_a := 1.2
var wait_period_b := 0.4
var creep_period_a := 2.0
var creep_period_b := 0.5
var retreat_period_a := 2.0
var retreat_period_b := 1.0
var aggressiveness = 0.0
var full_aggressiveness_after_time := 15.0
var must_follow_distance = 10.0
const S3_PLAYER_LOOKAHEAD := 15.0

func _process_monster_stalking_3(delta):
	_calculate_aggressiveness_level(delta)
	match stalking_state:
		StalkingState.WAIT:
			wait_timer -= delta
			if wait_timer < 0.0:
				wait_timer = 0.0
				_check_trees(S3_PLAYER_LOOKAHEAD)
				var dist_to_player = (Global.player.global_position - global_position).length()
				if closest_tree != null && _am_at_target(closest_tree.global_position):# && dist_to_player > _get_must_follow_distance():
					_set_stalking_state(StalkingState.ATTACK_CREEP)
					started_creeping_at_tree = closest_tree
					creep_timer = _get_creep_period()
				else:
					_set_stalking_state(StalkingState.FOLLOW_FIND_TARGET)
		StalkingState.FOLLOW_FIND_TARGET:
			_check_trees(S3_PLAYER_LOOKAHEAD)
			if closest_tree == null:
				_set_stalking_state(StalkingState.WAIT)
				return
			_set_stalking_state(StalkingState.FOLLOW_GO_TO_TARGET)
			follow_target = closest_tree.global_position
		StalkingState.FOLLOW_GO_TO_TARGET:
			if follow_target == null:
				_set_stalking_state(StalkingState.FOLLOW_FIND_TARGET)
				return
			if _move_to_target(follow_target, _get_movement_speed()):
				_set_stalking_state(StalkingState.WAIT)
				wait_timer = _get_wait_period()
		StalkingState.ATTACK_CREEP:
			_check_trees(S3_PLAYER_LOOKAHEAD)
			if closest_tree != started_creeping_at_tree:
				_set_stalking_state(StalkingState.FOLLOW_FIND_TARGET)
			else:
				_move_to_target(Global.player.global_position, creep_speed)
				creep_timer -= delta
				if creep_timer < 0.0:
					creep_timer = 0.0
					_set_stalking_state(StalkingState.ATTACK_LUNGE)
		StalkingState.ATTACK_LUNGE:
			if _move_to_target(Global.player.global_position, lunge_speed):
				_set_stalking_state(StalkingState.RETREAT_FIND_TARGET)
		StalkingState.RETREAT_FIND_TARGET:
			_check_trees(S3_PLAYER_LOOKAHEAD)
			if farthest_tree == null:
				_set_stalking_state(StalkingState.WAIT)
				return
			_set_stalking_state(StalkingState.RETREAT)
			retreat_target = farthest_tree.global_position
		StalkingState.RETREAT:
			if retreat_target != null:
				if _move_to_target(retreat_target, _get_movement_speed()):
					retreat_target = null
					retreat_timer = _get_retreat_period()
			elif player_is_in_safe_zone:
				pass
			else:
				retreat_timer -= delta
				if retreat_timer < 0.0:
					retreat_timer = 0.0
					_set_stalking_state(StalkingState.FOLLOW_FIND_TARGET)
		_:
			print("ERROR: Unhandled stalking state: Mode: ", MonsterAiMode.keys()[monster_ai_mode], "Stalking state: ", StalkingState.keys()[stalking_state])


var avg_calc_period = 5.0
var avg_player_displacement := Vector3.ZERO
var frame_t_accum := 0.0
var frame_d_accum := Vector3.ZERO
var prev_player_pos = null
func _calculate_aggressiveness_level(delta):
	if prev_player_pos != null:
		frame_d_accum += Global.player.global_position - prev_player_pos
		frame_t_accum += delta
		if frame_t_accum > avg_calc_period:
			avg_player_displacement = frame_d_accum / frame_t_accum
			frame_d_accum = Vector3.ZERO
			frame_t_accum = 0.0
			aggressiveness = clamp(lerp(1.0, 0.0, avg_player_displacement.length() / 5.0), 0.0, min(aggressiveness_cap, 1.0))
		aggressiveness_cap = lerp(0.0, 1.0, aggressiveness_cap_timer / full_aggressiveness_after_time)
		aggressiveness_cap_timer += delta
	prev_player_pos = Global.player.global_position
	#aggressiveness = 0.0


################### HELPERS ###################

func _check_trees(player_lookahead_amount):
	var player_pos = Global.player.global_position + Global.player.velocity / Global.player.SPEED * player_lookahead_amount
	var closest_tree_dist = 1000000.0
	var farthest_tree_dist = 0.0
	closest_tree = null
	farthest_tree = null
	var overlapping := target_search_area.get_overlapping_areas()
	for a in overlapping:
		if a.is_in_group("fir_tree"):
			var tree_dist = (player_pos - a.global_position).length()
			if tree_dist < closest_tree_dist:
				closest_tree_dist = tree_dist
				closest_tree = a.get_parent() as FirTree
			if tree_dist > farthest_tree_dist:
				farthest_tree_dist = tree_dist
				farthest_tree = a.get_parent() as FirTree


func _set_stalking_state(new_state: StalkingState):
	if DEBUG: print(MonsterAiMode.keys()[monster_ai_mode], ": ", StalkingState.keys()[stalking_state], " -> ", StalkingState.keys()[new_state])
	stalking_state = new_state
	wait_timer = 0.0
	retreat_timer = 0.0
	creep_timer = 0.0
	started_creeping_at_tree = null
	retreat_target = null
	follow_target = null


func _move_to_target(target: Vector3, speed: float):
	var displacement = target - global_position
	var dist = displacement.length()
	if dist > DIST_CLOSE:
		var new_velocity = displacement.normalized()
		new_velocity = new_velocity * speed
		velocity = new_velocity
		move_and_slide()
		return false
	else:
		return true


func _am_at_target(target):
	if target != null:
		var dist = (self.global_position - target).length()
		return dist < DIST_CLOSE
	else:
		return false
		
		
func _get_movement_speed():
	return lerp(movement_speed_a, movement_speed_b, aggressiveness)
func _get_lunge_speed():
	return lunge_speed
func _get_creep_speed():
	return creep_speed
func _get_wait_period():
	return lerp(wait_period_a, wait_period_b, aggressiveness)
func _get_creep_period():
	return lerp(creep_period_a, creep_period_b, aggressiveness)
func _get_retreat_period():
	return lerp(retreat_period_a, retreat_period_b, aggressiveness)
func _get_must_follow_distance():
	return lerp(must_follow_distance, 0.0, aggressiveness)


func shot(from_where: Vector3):
	_set_safe_zone(from_where)
	if farthest_tree != null:
		_set_stalking_state(StalkingState.RETREAT_FIND_TARGET)


func _on_body_entered(body):
	if body.is_in_group("player") && stalking_state == StalkingState.ATTACK_LUNGE:
		#body.take_damage(1)
		Global.takedamage.emit()
		_set_safe_zone(body.global_position)
		_set_stalking_state(StalkingState.RETREAT_FIND_TARGET)


func _set_safe_zone(position: Vector3):
	player_is_in_safe_zone = true
	var safe_zone_node = safe_zone_scene.instantiate()
	safe_zone_node.position = position
	Global.level.add_child(safe_zone_node)
	safe_zone_node.set_radius(SAFE_ZONE_RADIUS)
	safe_zone_node.player_left.connect(func(): player_is_in_safe_zone = false)
