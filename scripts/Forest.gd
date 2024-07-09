extends Node3D

class_name Forest

signal hunt_animal

func start_hunting_animal():
	hunt_animal.emit()
