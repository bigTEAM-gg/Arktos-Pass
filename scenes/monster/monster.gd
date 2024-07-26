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

enum StalkingState { FOLLOW, CREEP, LUNGE, RETREAT }
var stalking_state: StalkingState

var closest_tree: FirTree = null
var farthest_tree: FirTree = null
var started_creeping_at_tree: FirTree = null
var creeping_timer := 0.0
var retreat_target = null
var retreat_timer := 0.0


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
		StalkingState.FOLLOW:
			_check_trees()
			if closest_tree != null:
				_move_to_target(closest_tree.global_position, SPEED)
				if _am_at_target(closest_tree.global_position):
					print("FOLLOW -> CREEP")
					stalking_state = StalkingState.CREEP
					started_creeping_at_tree = closest_tree
		StalkingState.CREEP:
			_check_trees()
			print(closest_tree, started_creeping_at_tree)
			if closest_tree != started_creeping_at_tree:
				print("CREEP -> FOLLOW")
				stalking_state = StalkingState.FOLLOW
				started_creeping_at_tree = null
				creeping_timer = 0.0
			creeping_timer -= delta
			if creeping_timer < 0.0:
				creeping_timer = 0.0
				print("CREEP -> LUNGE")
				stalking_state = StalkingState.LUNGE
				started_creeping_at_tree = null
		StalkingState.LUNGE:
			if _move_to_target(Global.player.global_position, LUNGE_SPEED):
				print("LUNGE -> RETREAT")
				stalking_state = StalkingState.RETREAT
		StalkingState.RETREAT:
			if retreat_target != null:
				if _move_to_target(retreat_target, SPEED):
					retreat_target = null
					retreat_timer = 2.0
			else:
				retreat_timer -= delta
				if retreat_timer < 0.0:
					retreat_timer = 0.0
					print("RETREAT -> FOLLOW")
					stalking_state = StalkingState.FOLLOW
			


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
	#target = _find_retreat_target()


func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(1)
		_set_safe_zone(body.global_position)
		_check_trees()
		retreat_target = farthest_tree.global_position
		stalking_state = StalkingState.RETREAT


func _set_safe_zone(position: Vector3):
	pass
	#player_is_in_safe_zone = trues
	#var safe_zone_node = safe_zone_scene.instantiate()
	#safe_zone_node.position = position
	#Global.level.add_child(safe_zone_node)
	#safe_zone_node.set_radius(SAFE_ZONE_RADIUS)
	#safe_zone_node.player_left.connect(func(): player_is_in_safe_zone = false)
