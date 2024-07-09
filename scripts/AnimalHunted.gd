extends Area2D

class_name AnimalHunted

signal animal_hunted_clicked

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func get_screen_size() -> Vector2:
	return sprite.get_rect().size

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			animal_hunted_clicked.emit()
