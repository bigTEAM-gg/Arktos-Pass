extends Node

class_name VisualTimer

@onready var total_bar: Sprite3D = $TimerDisplay/Total
@onready var current_bar: Sprite3D = $TimerDisplay/Current
@onready var timer = $"ExpirationTimer"

@export var scale_x: float = 1.0
@export var scale_y: float = 1.0

signal timer_done

func set_bars_scale(x: float, y: float) -> void:
	current_bar.scale.x = x
	current_bar.scale.y = y
	total_bar.scale.x = x
	total_bar.scale.y = y
	
func start_timer(duration: float) -> void:
	timer.start(duration)

func _process(delta: float) -> void:
	current_bar.scale.x = total_bar.scale.x * timer.time_left / timer.wait_time

func _on_expiration_timer_timeout() -> void:
	timer_done.emit()
