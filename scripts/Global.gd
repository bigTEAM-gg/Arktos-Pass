extends Node

var level: Forest = null
var player: Player = null
var monster: Monster = null
@export var wayback: int = 0
signal beepradio
signal pickup

func handle_player_sniper_mode_changed(sniper_mode_active: bool):
	print("sniper_mode_active ", sniper_mode_active)
	if monster != null:
		#monster.visible = sniper_mode_active
		pass
