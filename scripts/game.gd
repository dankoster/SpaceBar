extends Node2D

@onready var lasers = $Lasers
@onready var player = $Player

func _ready(): 
	player.connect("laser_shot", onPlayerLaserShot)
	
func onPlayerLaserShot(laser):
	lasers.add_child(laser)
