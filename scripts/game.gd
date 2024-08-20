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
	if Input.is_action_just_pressed("reset"): get_tree().reload_current_scene()
	if Input.is_action_just_pressed("zoom_in"): addZoom(0.3)
	if Input.is_action_just_pressed("zoom_out"): addZoom(-0.3)


func _physics_process(_delta):

	var camera_viewport_size = get_canvas_transform().affine_inverse().basis_xform(get_viewport_rect().size)
	camera_rect = Rect2($Player.global_position - (0.5 * camera_viewport_size),  camera_viewport_size).grow(-200)
	queue_redraw()

	print($Player.position)


func addZoom(value: float) -> void:
	var curZoom = $Player/Camera2D.zoom
	var newZoomFactor = clamp(curZoom.x + value, 0.2, 2)
	var newZoom = Vector2(newZoomFactor, newZoomFactor)
	var tween = create_tween()
	tween.tween_property($Player/Camera2D, "zoom", newZoom, 0.2).from(curZoom)
	await tween.finished


var sectors := {}
var rng := RandomNumberGenerator.new()
var cell_size: float = 1000.0
var grid_origin: Vector2 = Vector2(0.0,0.0)
var cell_count: int = 6
var camera_rect: Rect2

func _draw() -> void:
	if cell_size == 0:
		return

	var position_origin := grid_origin * cell_size

	var half_cell_count := int(cell_count / 2.0)
	var half_cell_size := cell_size/2.0
	
	for x in range(-half_cell_count, half_cell_count):
		for y in range(-half_cell_count, half_cell_count):
			var cell_rect := Rect2(
				Vector2(
					position_origin.x + x * cell_size - half_cell_size,
					position_origin.y + y * cell_size - half_cell_size
				),
				Vector2(cell_size, cell_size)
			)

			var color = Color.RED if cell_rect.has_point($Player.position) else Color.SKY_BLUE
			draw_rect(cell_rect, color, false)

	draw_rect(camera_rect, Color.GREEN, false)




func initLayout(numAsteroids: int):
	var rect = get_viewport_rect()

	rng.seed = hash("12345678")

	#playerSpawn.global_position = rect.size/2
	#player.global_position = playerSpawn.global_position
	
	print('init asteroids layout ' + str(rect))
	for n in numAsteroids:
		#random size between 1 and 3 becasue size 0 is "NONE" because of how the asteroid works internally
		var randomSize = Asteroid.AsteroidSize.keys()[rng.randi_range(1, Asteroid.AsteroidSize.size() - 1)]
		var a = asteroid_scene.instantiate()
		a.global_position = Vector2(rng.randf_range(0, rect.size.x), rng.randf_range(0, rect.size.y))
		a.size = Asteroid.AsteroidSize[randomSize]
		a.mass = Asteroid.AsteroidMass[Asteroid.AsteroidSize[randomSize]]
		a.rotation = rng.randf_range(0, 2*PI)
		asteroids.add_child(a)


func onAsteroidHitBody(asteroid, target):
	print('onAsteroidHitBody ' + str(asteroid) + " " + str(target))
	asteroid.explode()
	target.explode() #probably the player!


func onPlayerShotLaser(laser: Laser):
	lasers.add_child(laser)

 
func onAsteroidExploded(asteroid: Asteroid):
	score += asteroid.size * 100


func onPlayerCollided(p: Player, collider):
	if(collider is Asteroid):
		collider.explode(p.velocity)
		p.explode()


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
