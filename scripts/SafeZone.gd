extends Node3D

@onready var collision_shape: CollisionShape3D = $Area3D/CollisionShape3D
@onready var debug_shape: CSGSphere3D = $DebugShape


signal player_left


func set_radius(radius: float):
	collision_shape.shape.radius = radius
	debug_shape.radius = radius


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_left.emit()
		queue_free()
