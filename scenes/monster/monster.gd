# TODO:
# - what if player manages to run away while monster is lunging -- no exit from that ai state until player is hit

extends CharacterBody3D


class_name Monster


const SPEED = 15.0
const LUNGE_SPEED = 25.0
const CREEP_SPEED = 0.5
const IS_HIT_ESCAPE = Vector3(10, 0, 10)
const DEBUG = true
const SAFE_ZONE_RADIUS = 3.0
const DIST_CLOSE = 0.2

@onready var hurtbox = $Hurtbox
@onready var target_search_area: Area3D = $TargetSearchArea
@onready var safe_zone_scene := preload("res://scenes/safe_zone.tscn")


@export var attack_delay := 2.0
@export var movement_delay := 0.7


enum MonsterState { IDLE, STALKING }
var monster_state: MonsterState

var target = null

var previous_player_pos = null
var player_is_slow
var player_is_slow_accum := 0.0
var player_is_around := false
var delay_decision_accum := 0.0
var player_is_in_safe_zone := false
var is_lunging := false
var closest_tree_while_creeping: FirTree = null

var closest_tree: FirTree = null
var farthest_tree: FirTree = null


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
			if target == null:
				target = _find_attack_target(delta)
			elif _move_to_target(target, _get_speed()):
				target = null


func _find_attack_target(delta):
	var target = null
	_check_trees()
	if _am_at_target(closest_tree):
		if player_is_in_safe_zone:
			pass
		else:
			if _delay_decision(delta, attack_delay):
				if DEBUG: print("Monster's target is player")
				target = Global.player.global_position
				is_lunging = true
	else:
		if _delay_decision(delta, movement_delay):
			target = closest_tree.global_position
	return target


func _get_speed():
	if is_lunging:
		return LUNGE_SPEED
	return SPEED

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


func _am_at_target(closest_tree: FirTree):
	if closest_tree != null:
		var dist = (self.global_position - closest_tree.global_position).length()
		return dist < DIST_CLOSE
	else:
		return false


func _delay_decision(delta: float, delay_time: float):
	delay_decision_accum += delta
	if delay_decision_accum > delay_time:
		delay_decision_accum = 0.0
		return true
	return false
	

func _find_retreat_target():
	_check_trees()
	return farthest_tree.global_position


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


func shot(from_where: Vector3):
	_set_safe_zone(from_where)
	target = _find_retreat_target()


func _on_body_entered(body):
	if body.is_in_group("player") && is_lunging:
		body.take_damage(1)
		_set_safe_zone(body.global_position)
		is_lunging = false
		target = _find_retreat_target()


func _set_safe_zone(position: Vector3):
	player_is_in_safe_zone = true
	var safe_zone_node = safe_zone_scene.instantiate()
	safe_zone_node.position = position
	Global.level.add_child(safe_zone_node)
	safe_zone_node.set_radius(SAFE_ZONE_RADIUS)
	safe_zone_node.player_left.connect(func(): player_is_in_safe_zone = false)
