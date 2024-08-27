extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	var enviro = get_tree().get_nodes_in_group('enviro')
	var monster = get_tree().get_nodes_in_group('critters')[0]
	
	for e: Node3D in enviro:
		if e.global_position.distance_squared_to(global_position) > 3000 and e.global_position.distance_squared_to(monster.global_position) > 3000:
			e.visible = false
			e.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			e.visible = true
			e.process_mode = Node.PROCESS_MODE_INHERIT
