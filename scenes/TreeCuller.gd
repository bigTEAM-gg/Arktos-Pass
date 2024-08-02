extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var enviro = get_tree().get_nodes_in_group('enviro')
	
	for e: Node3D in enviro:
		if e.global_position.distance_squared_to(global_position) > 2000:
			e.visible = false
			e.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			e.visible = true
			e.process_mode = Node.PROCESS_MODE_INHERIT
