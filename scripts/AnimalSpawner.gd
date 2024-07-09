extends Area3D

class_name AnimalSpawner

@onready var AnimalMarkerScene = preload("res://scenes/animal_marker.tscn")

var current_marker: AnimalMarker = null

@onready var forest: Forest = $".."

func _add_animal_marker() -> void:
	if current_marker == null:
		var position_to_add_to = Vector3(randf_range(-5, 5), 0.0, randf_range(-5, 5))
		print("Adding animal marker at ", str(position_to_add_to))
		current_marker = AnimalMarkerScene.instantiate()
		current_marker.position = position_to_add_to
		self.add_child(current_marker)
		current_marker.connect("animal_marker_clicked", self._on_animal_marker_clicked)
		current_marker.connect("animal_marker_expired", self._on_animal_marker_expired)
		
		
func _remove_animal_marker() -> void:
	if current_marker != null:
		print("Removing animal marker")
		current_marker.queue_free()
		current_marker = null

func _on_body_entered(body: Node3D) -> void:
		var player := body as Player
		if player != null:
			_add_animal_marker()

func _on_animal_marker_clicked() -> void:
	_remove_animal_marker()
	print("Transition into hunt mode")
	#get_tree().change_scene_to_file("res://scenes/hunt.tscn")
	forest.start_hunting_animal()

func _on_animal_marker_expired() -> void:
	_remove_animal_marker()
	print("Animal marker expired")
