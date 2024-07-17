extends CharacterBody3D


const SPEED = 6.0
const IS_HIT_ESCAPE = Vector3(10, 0, 10)

@onready var hurtbox = $Hurtbox


func _ready():
	hurtbox.body_entered.connect(_on_body_entered)


func _physics_process(delta):
	var player = Global.player
	if not is_instance_valid(player):
		return
	
	# Only move if player is moving
	if player.velocity.length() < 3:
		return
	
	var new_velocity = Global.player.global_position - global_position
	new_velocity = new_velocity.normalized()
	new_velocity = new_velocity * SPEED

	velocity = new_velocity

	move_and_slide()


func shot():
	# TODO: Run there instead of teleporting
	global_position += IS_HIT_ESCAPE * Vector3([1, -1].pick_random(), 0, [1, -1].pick_random())


func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(1)
		global_position += IS_HIT_ESCAPE * Vector3([1, -1].pick_random(), 0, [1, -1].pick_random())
