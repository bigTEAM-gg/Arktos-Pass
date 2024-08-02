extends Area3D

class_name FirTree

var shake_level := 0.0
var shake_decay_to := 0.0
var shake_decay_rate := 2.0


@onready var foggy_sprite = $FoggySprite


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	shake_level = lerp(shake_level, shake_decay_to, delta * shake_decay_rate)
	foggy_sprite.scale.x = randf_range(-shake_level, shake_level)


func _on_body_entered(body):
	if body.is_in_group("critters"):
		shake_level = 30.0
		shake_decay_to = 12.0
		shake_decay_rate = 4.0
	if body.is_in_group("player"):
		shake_level = 15.0
		shake_decay_to = 5.0
		shake_decay_rate = 4.0


func _on_body_exited(body):
	if body.is_in_group("critters"):
		shake_decay_to = 0.0
		shake_decay_rate = 8.0
	if body.is_in_group("player"):
		shake_decay_to = 0.0
		shake_decay_rate = 8.0
