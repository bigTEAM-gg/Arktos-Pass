extends Node3D

class_name AnimalMarker

@onready var expiration_timer: VisualTimer = $VisualTimer

const MARKER_DURATION = 2.0

func _ready() -> void:
	expiration_timer.start_timer(MARKER_DURATION)

signal animal_marker_clicked
signal animal_marker_expired

func _on_click_area_input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			animal_marker_clicked.emit()

func _on_visual_timer_timer_done() -> void:
	print("Timer expired")
	animal_marker_expired.emit()
