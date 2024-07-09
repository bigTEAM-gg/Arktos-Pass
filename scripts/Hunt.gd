extends Node2D

class_name Hunt

@onready var AnimalHuntedScene = preload("res://scenes/animal_hunted.tscn")

@onready var background: Sprite2D = $Background
@onready var crosshair: Crosshair = $Crosshair

var animal_hunted: AnimalHunted = null

signal hunt_animal_done

func _ready() -> void:
	_on_viewport_resize()
	get_tree().get_root().size_changed.connect(self._on_viewport_resize)
	animal_hunted = AnimalHuntedScene.instantiate()
	self.add_child(animal_hunted)
	var half_animal_size = animal_hunted.get_screen_size() * 0.5
	var min = half_animal_size
	# TODO: problem if viewport is resized mid hunt
	var max = get_viewport_rect().size - half_animal_size
	animal_hunted.position = Vector2(randf_range(min.x, max.x), randf_range(min.y, max.y))
	animal_hunted.connect("animal_hunted_clicked", self._on_animal_hunted_clicked)
	
func _on_viewport_resize() -> void:
	var background_size := Vector2(float(background.texture.get_width()), float(background.texture.get_height()))
	var viewport_rect := get_viewport_rect()
	background.position = Vector2.ZERO
	background.scale = Vector2(viewport_rect.size.x / background_size.x, viewport_rect.size.y / background_size.y)
	crosshair.set_size(viewport_rect.size.x, viewport_rect.size.y)

func _on_animal_hunted_clicked() -> void:
	animal_hunted.queue_free()
	animal_hunted = null
	print("Hunt mode done")
	hunt_animal_done.emit()
