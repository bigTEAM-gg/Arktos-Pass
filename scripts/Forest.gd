extends Node3D

class_name Forest

signal hunt_animal

@onready var critter_scene := preload("res://scenes/critter.tscn")
@onready var player_node: Player = $Player

func start_hunting_animal():
	hunt_animal.emit()
	
func _spawn_critter():
	var critter: Critter = critter_scene.instantiate()
	critter.goal = Critter.Goal.CHASE_PLAYER if randf() > 0.5 else Critter.Goal.RUN_AWAY_FROM_PLAYER
	critter.player_node = player_node
	critter.position = player_node.position + Vector3(randf_range(-10.0, 10.0), 0.0, randf_range(-10.0, 10.0))
	add_child(critter)

func _on_spawn_timer_timeout() -> void:
	_spawn_critter()
