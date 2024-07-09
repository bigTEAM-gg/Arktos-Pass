extends Node2D

class_name Crosshair

@onready var horizontal_line: Line2D = $HorizontalLine
@onready var vertical_line: Line2D = $VerticalLine

func set_size(width: float, height: float):
	horizontal_line.points[1].x = width
	vertical_line.points[1].y = height
	
	
func _process(_delta: float) -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	horizontal_line.points[0].y = mouse_pos.y
	horizontal_line.points[1].y = mouse_pos.y
	vertical_line.points[0].x = mouse_pos.x
	vertical_line.points[1].x = mouse_pos.x
