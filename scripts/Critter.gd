extends Node3D

class_name Critter

const MOVEMENT_SPEED = 4.8
const ACTIVE_RADIUS = 20.0
const TARGET_THRESHOLD = 1.0

@export var player_node: Player = null

enum Goal { CHASE_PLAYER, RUN_AWAY_FROM_PLAYER }
@export var goal: Goal = Goal.CHASE_PLAYER

func _physics_process(delta: float) -> void:
	if _despawn_if_too_far():
		return
	
	match goal:
		Goal.CHASE_PLAYER:
			_chase_player(delta)
		Goal.RUN_AWAY_FROM_PLAYER:
			_run_away_from_player(delta)
	
func _chase_player(delta: float) -> void:
	if _move_to_target(delta, player_node.global_position, TARGET_THRESHOLD):
		# player_node.take_damage()
		self.queue_free()
	
func _run_away_from_player(delta: float) -> void:
	var direction = (self.global_position - player_node.global_position).normalized()
	direction.y = 0.0
	self.position += direction * MOVEMENT_SPEED * delta
	
func _move_to_target(delta: float, target: Vector3, target_threshold: float) -> bool:
	var displacement := target - self.global_position
	var distance := displacement.length()
	if distance < target_threshold:
		return true
	var translation = minf(MOVEMENT_SPEED * delta, distance)
	var direction := displacement / distance
	self.position += direction * translation
	return false
	
func _despawn_if_too_far() -> bool:
	if (self.global_position - player_node.global_position).length() > ACTIVE_RADIUS:
		self.queue_free()
		return true
	return false
