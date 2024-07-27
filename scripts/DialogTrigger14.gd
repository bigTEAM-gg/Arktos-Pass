extends Node3D

class_name DialogTrigger14

@export var dialogic_timeline = "test3"

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		Dialogic.timeline_ended.connect(_on_dialog_timeline_ended)
		var dialogic_node = Dialogic.start(dialogic_timeline)
		dialogic_node.process_mode = Node.PROCESS_MODE_ALWAYS
		Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS
		Global.player.is_sniper_mode = false
		Global.player.is_in_dialog = true
		Global.player.process_mode = Node.PROCESS_MODE_ALWAYS
		Global.wayback = 1
		get_tree().paused = true
		
		
func _on_dialog_timeline_ended() -> void:
	Dialogic.timeline_ended.disconnect(_on_dialog_timeline_ended)
	Global.player.process_mode = Node.PROCESS_MODE_INHERIT
	Global.player.is_in_dialog = false
	Global.player.shooting_delay.start()
	get_tree().paused = false
	queue_free()
