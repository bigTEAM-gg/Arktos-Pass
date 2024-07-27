# TODO:
# - what if player manages to run away while monster is lunging -- no exit from that ai state until player is hit

extends CharacterBody3D


class_name Monster


const DEBUG = true
const SAFE_ZONE_RADIUS = 3.0
const DIST_CLOSE = 0.2


@onready var hurtbox = $Hurtbox
@onready var target_search_area: Area3D = $TargetSearchArea
@onready var safe_zone_scene := preload("res://scenes/safe_zone.tscn")


@export var movement_speed := 15.0
@export var lunge_speed := 25.0
@export var creep_speed := 0.5
@export var wait_period := 0.7
@export var creeping_period := 1.0
@export var retreat_period := 2.0


enum MonsterState { IDLE, STALKING }
var monster_state: MonsterState
enum StalkingState { WAIT, FOLLOW_FIND_TARGET, FOLLOW_GO_TO_TARGET, CREEP, LUNGE, RETREAT }
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
			_process_monster_stalking(delta)


func _process_monster_stalking(delta):
	match stalking_state:
		StalkingState.WAIT:
			wait_timer -= delta
			if wait_timer < 0.0:
				wait_timer = 0.0
				_check_trees()
				if closest_tree != null && _am_at_target(closest_tree.global_position):
					_set_stalking_state(StalkingState.CREEP)
					started_creeping_at_tree = closest_tree
					creep_timer = creeping_period
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
			if _move_to_target(follow_target, movement_speed):
				_set_stalking_state(StalkingState.WAIT)
				wait_timer = wait_period
		StalkingState.CREEP:
			_check_trees()
			if closest_tree != started_creeping_at_tree:
				_set_stalking_state(StalkingState.FOLLOW_FIND_TARGET)
			else:
				_move_to_target(Global.player.global_position, creep_speed)
				creep_timer -= delta
				if creep_timer < 0.0:
					creep_timer = 0.0
					_set_stalking_state(StalkingState.LUNGE)
		StalkingState.LUNGE:
			if _move_to_target(Global.player.global_position, lunge_speed):
				_set_stalking_state(StalkingState.RETREAT)
		StalkingState.RETREAT:
			if retreat_target != null:
				if _move_to_target(retreat_target, movement_speed):
					retreat_target = null
					retreat_timer = retreat_period
			elif player_is_in_safe_zone:
				pass
			else:
				retreat_timer -= delta
				if retreat_timer < 0.0:
					retreat_timer = 0.0
					_set_stalking_state(StalkingState.FOLLOW_FIND_TARGET)


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


func shot(from_where: Vector3):
	_set_safe_zone(from_where)
	_check_trees()
	if farthest_tree != null:
		_set_stalking_state(StalkingState.RETREAT)
		retreat_target = farthest_tree.global_position


func _on_body_entered(body):
	if body.is_in_group("player") && stalking_state == StalkingState.LUNGE:
		body.take_damage(1)
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
