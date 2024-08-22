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
	camera_rect = Rect2($Player.global_position - (0.5 * camera_viewport_size),  camera_viewport_size).grow(-600)

	visibleSectors = findSectorsInRect(camera_rect, sectorSize)
	queue_redraw()


# Find all sectors touching the specified rect. Sectors are cells
# of the specified size in an infinite grid starting at (0,0).
static func findSectorsInRect(rect: Rect2, size: int = 1000) -> PackedVector2Array: 
	var result := PackedVector2Array()

	#calc rectangle edges, offset on the top/left
	var x := int(rect.position.x) - size
	var y := int(rect.position.y) - size
	var x2 := int(rect.position.x + rect.size.x)
	var y2 := int(rect.position.y + rect.size.y)

	#calc nearest sector edges
	var startX := x - (x % size) 
	var startY := y - (y % size)
	var endX := x2 - (x2 % size) + size
	var endY := y2 - (y2 % size) + size

	var edgeX := startX
	while(edgeX < endX):
		var edgeY := startY
		while(edgeY < endY):
			result.append(Vector2(edgeX, edgeY))
			edgeY += size
		edgeX += size

	return result


func addZoom(value: float) -> void:
	var curZoom = $Player/Camera2D.zoom
	var newZoomFactor = clamp(curZoom.x + value, 0.2, 2)
	var newZoom = Vector2(newZoomFactor, newZoomFactor)
	var tween = create_tween()
	tween.tween_property($Player/Camera2D, "zoom", newZoom, 0.2).from(curZoom)
	await tween.finished

var visibleSectors: PackedVector2Array
var sectors := {}
var rng := RandomNumberGenerator.new()
var sectorSize: int = 500
var grid_origin: Vector2 = Vector2(0,0)
var cell_count: int = 6
var camera_rect: Rect2
@onready var default_font = ThemeDB.fallback_font
@onready var default_font_size = ThemeDB.fallback_font_size * 2



func _draw() -> void:
	var player_containing_rect: Rect2
	for s in visibleSectors: 
		var sectorRect := Rect2(s, Vector2(sectorSize, sectorSize))
		if sectorRect.has_point($Player.position): 
			player_containing_rect = sectorRect
		else:
			draw_rect(sectorRect, Color.ALICE_BLUE, false)
			debugString(str(sectorRect.position), sectorRect.position)

	draw_rect(player_containing_rect, Color.RED, false)
	debugString(str(player_containing_rect.position), player_containing_rect.position)

	var cameraRectIndicator = camera_rect
	draw_rect(cameraRectIndicator, Color.GREEN, false)
	debugString(str(cameraRectIndicator), cameraRectIndicator.position)

	debugString(str(Vector2i($Player.position)), $Player.position + Vector2(20,20))



func debugString(s: String, pos: Vector2): 
	pos.y += default_font_size
	draw_string(default_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, default_font_size)

	
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
