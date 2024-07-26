extends Node2D

@onready var lasers = $Lasers
@onready var player = $Player
@onready var asteroids = $Asteroids
@onready var hud = $UI/HUD
@onready var playerSpawn = $PlayerSpawn

var lives := 3: 
	set(value): 
		lives = value
		hud.lives = value


var score := 0:
	set(value):
		score = value
		hud.score = value


func _ready(): 
	score = 0
	lives = 3
	player.connect("laser_shot", onPlayerShotLaser)
	player.connect("died", onPlayerDied)
	Events.connect("AsteroidExploded", onAsteroidExploded)
	Events.connect("AsteroidHitBody", onAsteroidHitBody)
	Events.connect("LaserHitArea", onLaserHitArea)

	
func _process(_delta):
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()


func onAsteroidHitBody(asteroid, target):
	asteroid.explode()
	target.explode() #probably the player!

	
func onLaserHitArea(laser, area):
	print("onLaserHitArea" + str(laser) + str(area))


func onPlayerShotLaser(laser: Laser):
	lasers.add_child(laser)


func onAsteroidExploded(asteroid: Asteroid):
	score += asteroid.size * 100


func onPlayerDied(player: Player):
	lives -= 1
	if lives > 0:
		await get_tree().create_timer(1).timeout
		player.respawn(playerSpawn.global_position)
	else: 
		print("GAME OVER")
		await get_tree().create_timer(3).timeout 
		get_tree().reload_current_scene()

