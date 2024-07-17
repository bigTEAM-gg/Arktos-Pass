extends Area3D


var shake = 0


@onready var sprite_3d = $Sprite3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	shake = max(shake - 15 * delta, 0)
	sprite_3d.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))


func _on_body_entered(body):
	if body.is_in_group("critters"):
		shake = 25
	if body.is_in_group("player"):
		shake = 15
