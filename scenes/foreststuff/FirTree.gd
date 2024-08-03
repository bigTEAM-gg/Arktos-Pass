extends Node3D

class_name FirTree

var shake_level := 0.0
var shake_decay_to := 0.0
var shake_decay_rate := 2.0

@onready var foggy_sprite = $FoggySprite

func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	shake_level = lerp(shake_level, shake_decay_to, delta * shake_decay_rate)
	if shake_level > 0.1:
		var direction_to_camera = (Global.player.camera.position - self.position)
		direction_to_camera.y = 0.0
		direction_to_camera = direction_to_camera.normalized()
		var x_rel = Vector3(0.0, 1.0, 0.0).cross(direction_to_camera).normalized()
		var y_rel = direction_to_camera.cross(x_rel)
		foggy_sprite.position = x_rel * randf_range(-shake_level, shake_level) * 0.005 + y_rel * randf_range(-shake_level, shake_level) * 0.005
	else:
		foggy_sprite.position = Vector3.ZERO


func _on_body_entered(body):
	if body.is_in_group("player"):
		shake_level = 15.0
		shake_decay_to = 5.0
		shake_decay_rate = 4.0


func _on_body_exited(body):
	if body.is_in_group("player"):
		shake_decay_to = 0.0
		shake_decay_rate = 8.0


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("critters"):
		print(self.name, ": ", "critter entered")
		shake_level = 30.0
		shake_decay_to = 12.0
		shake_decay_rate = 4.0


func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.is_in_group("critters"):
		shake_decay_to = 0.0
		shake_decay_rate = 8.0
