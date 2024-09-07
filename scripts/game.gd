extends Node2D

var asteroid_scene = preload("res://scenes/asteroid.tscn")

@onready var lasers = $Lasers
@onready var player = $Player
@onready var asteroids = $Asteroids
@onready var hud = $UI/HUD
@onready var gameOver = $UI/GameOverScreen
@onready var playerSpawn = $PlayerSpawn
@onready var default_font = ThemeDB.fallback_font
@onready var default_font_size = ThemeDB.fallback_font_size * 2

var lives := 3: 
	set(value): 
		lives = value
		hud.lives = value


var score := 0:
	set(value):
		score = value
		hud.score = value


var visibleSectors: PackedVector2Array
var sectors := {}
var rng := RandomNumberGenerator.new()
const rngSeed = "12345678"
const sectorSize: int = 500
var camera_rect: Rect2


func _ready(): 
	gameOver.visible = false
	score = 0
	lives = 3
	player.fuel = 100.0
	player.homePort = $Station
	player.connect("laser_shot", onPlayerShotLaser)
	player.connect("died", onPlayerDied)
	Events.connect("AsteroidExploded", onAsteroidExploded)
	Events.connect("AsteroidHitBody", onAsteroidHitBody)
	Events.PlayerCollided.connect(onPlayerCollided)
	$Player/Camera2D.ignore_rotation = true

	player.velocity = Vector2.from_angle(player.rotation).orthogonal() * 8
     

func _process(_delta):
	if Input.is_action_just_pressed("reset"): get_tree().reload_current_scene()
	if Input.is_action_just_pressed("zoom_in"): addZoom(0.3)
	if Input.is_action_just_pressed("zoom_out"): addZoom(-0.3)


func _physics_process(_delta):
	var camera_viewport_size = get_canvas_transform().affine_inverse().basis_xform(get_viewport_rect().size)
	camera_rect = Rect2($Player.global_position - (0.5 * camera_viewport_size),  camera_viewport_size)
	visibleSectors = findSectorsInRect(camera_rect, sectorSize)

	# for id in sectors.keys():
	# 	var pos: Vector2 = sectors[id]["rect"].position
	# 	if not visibleSectors.has(pos):
	# 		print('free sector: ' + id, sectors[id])
	# 		for asteroid in sectors[id].asteroids:
	# 			if asteroid != null and !asteroid.is_queued_for_deletion():
	# 				asteroid.queue_free()

	# 		sectors.erase(id)

	for sector in visibleSectors:
		var sectorID := str(sector)
		if not sectors.has(sectorID):
			# print('init sector' + str(sector))    
			var rect = Rect2(sector,Vector2(sectorSize, sectorSize))  
			var ast = generateAsteroids(rect, 5, 0.2)
			ast.map(func(a): asteroids.add_child(a))

			sectors[sectorID] = {
				"rect": rect,
				"asteroids": ast
			}
	
# 	queue_redraw()


# func _draw() -> void:
# 	#draw background grid
# 	for s in visibleSectors: 
# 		var sectorRect := Rect2(s, Vector2(sectorSize, sectorSize))
# 		draw_rect(sectorRect, Color.html("#00ff0010"), false)

	# var cameraRectIndicator = camera_rect
	# draw_rect(cameraRectIndicator, Color.GREEN, false)
	# debugString(str(cameraRectIndicator), cameraRectIndicator.position)
	# debugString(str(Vector2i($Player.position)), $Player.position + Vector2(20,20))


# Find all sectors touching the specified rect. Sectors are cells
# of the specified size in an infinite grid starting at (0,0).
static func findSectorsInRect(rect: Rect2, size: int = 1000) -> PackedVector2Array: 
	var result := PackedVector2Array()

	#calc rectangle edges, offset on the top/left
	var x := int(rect.position.x)
	var y := int(rect.position.y)
	var x2 := int(rect.position.x + rect.size.x)
	var y2 := int(rect.position.y + rect.size.y)

	#calc nearest sector edges
	var startX := x - (x % size) - (size if(x < 0) else 0)
	var startY := y - (y % size) - (size if(y < 0) else 0)
	var endX := x2 - (x2 % size) + (size if(x2 > 0) else 0)
	var endY := y2 - (y2 % size) + (size if(y2 > 0) else 0)

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
	var newZoomFactor = clamp(curZoom.x + value, 0.1, 2)
	var newZoom = Vector2(newZoomFactor, newZoomFactor)
	var tween = create_tween()
	tween.tween_property($Player/Camera2D, "zoom", newZoom, 0.2).from(curZoom)
	await tween.finished


func debugString(s: String, pos: Vector2): 
	pos.y += default_font_size
	draw_string(default_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, default_font_size)

	
# var rect = get_viewport_rect()
#playerSpawn.global_position = rect.size/2
#player.global_position = playerSpawn.global_position

func generateAsteroids(area: Rect2, maxInSector: int, probability: float = 1) -> Array[Asteroid]:
	assert(probability <= 1)

	var result: Array[Asteroid] = []

	rng.seed = hash(rngSeed + str(area))

	for n in maxInSector:
		if probability >= rng.randf():
			#random size between 1 and 3 becasue size 0 is "NONE" because of how the asteroid works internally
			var randomSize = Asteroid.AsteroidSize.keys()[rng.randi_range(1, Asteroid.AsteroidSize.size() - 1)]
			var a: Asteroid = asteroid_scene.instantiate()
			a.global_position = Vector2(
				rng.randf_range(area.position.x, area.position.x + area.size.x), 
				rng.randf_range(area.position.y, area.position.y + area.size.y)
			)
			a.size = Asteroid.AsteroidSize[randomSize]
			a.mass = Asteroid.AsteroidMass[Asteroid.AsteroidSize[randomSize]]
			a.rotation = rng.randf_range(0, 2*PI)

			#Generate asteroid payload from a table of materials
			var randomMaterial = Materials.getRandomMaterial(rng)
			a.payload[randomMaterial.material] = randomMaterial.amount

			result.append(a)

	return result


func onAsteroidHitBody(asteroid, target):
	print('onAsteroidHitBody ' + str(asteroid) + " " + str(target))
	#asteroid.explode()
	#target.explode() #probably the player!


func onPlayerShotLaser(laser: Laser):
	lasers.add_child(laser)

 
func onAsteroidExploded(asteroid: Asteroid):
	score += asteroid.size * 100


func onPlayerCollided(p: Player, collider):
	if(collider is Asteroid):
		print('player hit ' + str(collider))
		# collider.explode(p.velocity)
		# p.explode()


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
