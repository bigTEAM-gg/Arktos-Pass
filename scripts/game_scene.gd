extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var style: DialogicStyle = load("res://dialog/styles/default_dialog.tres")
	style.prepare()
