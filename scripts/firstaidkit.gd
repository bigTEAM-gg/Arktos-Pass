extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		Global.healthpickup.emit()
		queue_free()
		print("pick up happening")
