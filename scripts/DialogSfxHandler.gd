extends Node

@onready var radio_beep_sfx: AudioStreamPlayer =  $RadioBeep

func _ready():
	Dialogic.Portraits.character_joined.connect(_character_joined)
	
func _character_joined(info: Dictionary):
	if info.character.display_name == "Radio":
		radio_beep_sfx.play(0.66)
		pass
