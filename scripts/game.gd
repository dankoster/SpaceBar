extends Node2D

var asteroid_scene = preload("res://scenes/asteroid.tscn")

@onready var lasers = $Lasers
@onready var player = $Player
@onready var asteroids = $Asteroids
@onready var hud = $UI/HUD
@onready var gameOver = $UI/GameOverScreen
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
	gameOver.visible = false
	score = 0
	lives = 3
	player.fuel = 100.0
	player.connect("laser_shot", onPlayerShotLaser)
	player.connect("died", onPlayerDied)
	Events.connect("AsteroidExploded", onAsteroidExploded)
	Events.connect("AsteroidHitBody", onAsteroidHitBody)
	Events.PlayerCollided.connect(onPlayerCollided)
	get_viewport().connect("size_changed", initLayout)
	$Player/Camera2D.ignore_rotation = true
	initLayout(15)


func _process(_delta):
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()


func initLayout(numAsteroids: int):
	var rect = get_viewport_rect()
	#playerSpawn.global_position = rect.size/2
	#player.global_position = playerSpawn.global_position
	
	for n in numAsteroids:
		#random size between 1 and 3 becasue size 0 is "NONE" because of how the asteroid works internally
		var randomSize = Asteroid.AsteroidSize.keys()[randi_range(1, Asteroid.AsteroidSize.size() - 1)]
		var a = asteroid_scene.instantiate()
		a.global_position = Vector2(randf_range(0, rect.size.x), randf_range(0, rect.size.y))
		a.size = Asteroid.AsteroidSize[randomSize]
		a.mass = Asteroid.AsteroidMass[Asteroid.AsteroidSize[randomSize]]
		print('add asteroid ' + str(a.size) + ' ' + str(a.mass))
		asteroids.add_child(a)


func onAsteroidHitBody(asteroid, target):
	print('onAsteroidHitBody ' + str(asteroid) + " " + str(target))
	asteroid.explode()
	target.explode() #probably the player!


func onPlayerShotLaser(laser: Laser):
	lasers.add_child(laser)

 
func onAsteroidExploded(asteroid: Asteroid):
	score += asteroid.size * 100


func onPlayerCollided(player: Player, collider):
	if(collider is Asteroid):
		collider.explode(player.velocity)
		player.explode()

func onPlayerDied(p: Player):
	lives -= 1
	if lives > 0:
		await get_tree().create_timer(1).timeout
		#while !playerSpawn.isEmpty:
			#print('player spawn point is not empty')
			#await get_tree().create_timer(0.5).timeout
		
		playerSpawn.global_position = get_viewport_rect().size/2
		p.respawn(playerSpawn.global_position)
	else: 
		await get_tree().create_timer(3).timeout 
		gameOver.visible = true
