# TODO:
# - what if player manages to run away while monster is lunging -- no exit from that ai state until player is hit

extends CharacterBody3D


class_name Monster


const DEBUG = true
const SAFE_ZONE_RADIUS = 3.0
const DIST_CLOSE = 0.2


@onready var hurtbox = $Hurtbox
@onready var target_search_area: Area3D = $TargetSearchArea
@onready var monster_sprite = $MonsterSprite
@onready var safe_zone_scene := preload("res://scenes/safe_zone.tscn")


@export var movement_speed_a := 10.0
@export var movement_speed_b := 15.0
@export var lunge_speed := 25.0
@export var creep_speed := 0.5
@export var wait_period_a := 1.2
@export var wait_period_b := 0.4
@export var creep_period_a := 1.0
@export var creep_period_b := 0.5
@export var retreat_period_a := 2.0
@export var retreat_period_b := 1.0
@export var aggressiveness = 0.0
@export var full_aggressiveness_after_time := 15.0
@export var must_follow_distance = 10.0

enum MonsterState { IDLE, STALKING }
var monster_state: MonsterState
enum StalkingState { WAIT, FOLLOW_FIND_TARGET, FOLLOW_GO_TO_TARGET, ATTACK_CREEP, ATTACK_LUNGE, RETREAT }
var stalking_state: StalkingState


var started_creeping_at_tree: FirTree = null
var player_is_in_safe_zone := false
var closest_tree: FirTree = null
var farthest_tree: FirTree = null
var retreat_target = null
var follow_target = null
var creep_timer := 0.0
var retreat_timer := 0.0
var wait_timer := 0.0
var aggressiveness_cap := 0.0
var aggressiveness_cap_timer := 0.0


func _ready():
	hurtbox.body_entered.connect(_on_body_entered)
	monster_state = MonsterState.STALKING
	Global.monster = self


func _physics_process(delta):
	if not is_instance_valid(Global.player):
		return
	match monster_state:
		MonsterState.IDLE:
			pass
		MonsterState.STALKING:
			_calculate_aggressiveness_level(delta)
			_process_monster_stalking(delta)
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

func _process_monster_stalking(delta):
	match stalking_state:
		StalkingState.WAIT:
			wait_timer -= delta
			if wait_timer < 0.0:
				wait_timer = 0.0
				_check_trees()
				var dist_to_player = (Global.player.global_position - global_position).length()
				if closest_tree != null && _am_at_target(closest_tree.global_position) && dist_to_player > _get_must_follow_distance():
					_set_stalking_state(StalkingState.ATTACK_CREEP)
					started_creeping_at_tree = closest_tree
					creep_timer = _get_creep_period()
				else:
					_set_stalking_state(StalkingState.FOLLOW_FIND_TARGET)
		StalkingState.FOLLOW_FIND_TARGET:
			_check_trees()
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
			_check_trees()
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
				_set_stalking_state(StalkingState.RETREAT)
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
	


func _check_trees():
	var player_pos = Global.player.global_position
	var closest_tree_dist = 1000000.0
	var farthest_tree_dist = 0.0
	closest_tree = null
	farthest_tree = null
	var overlapping := target_search_area.get_overlapping_areas()
	for a in overlapping:
		if a is FirTree:
			var tree_dist = (player_pos - a.global_position).length()
			if tree_dist < closest_tree_dist:
				closest_tree_dist = tree_dist
				closest_tree = a
			if tree_dist > farthest_tree_dist:
				farthest_tree_dist = tree_dist
				farthest_tree = a


func _set_stalking_state(new_state: StalkingState):
	if DEBUG: print(StalkingState.keys()[stalking_state], " -> ", StalkingState.keys()[new_state])
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
	_check_trees()
	if farthest_tree != null:
		_set_stalking_state(StalkingState.RETREAT)
		retreat_target = farthest_tree.global_position


func _on_body_entered(body):
	if body.is_in_group("player") && stalking_state == StalkingState.ATTACK_LUNGE:
		#body.take_damage(1)
		Global.takedamage.emit()
		_set_safe_zone(body.global_position)
		_check_trees()
		_set_stalking_state(StalkingState.RETREAT)
		retreat_target = farthest_tree.global_position


func _set_safe_zone(position: Vector3):
	player_is_in_safe_zone = true
	var safe_zone_node = safe_zone_scene.instantiate()
	safe_zone_node.position = position
	Global.level.add_child(safe_zone_node)
	safe_zone_node.set_radius(SAFE_ZONE_RADIUS)
	safe_zone_node.player_left.connect(func(): player_is_in_safe_zone = false)
