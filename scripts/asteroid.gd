class_name Asteroid extends RigidBody2D

var movementVector := Vector2(0,-1)

enum AsteroidSize{NONE, LARGE, MEDIUM, SMALL}
@export var size := AsteroidSize.LARGE

var speed := 50.0

@onready var sprite = $Sprite2D
@onready var cshape = $CollisionShape2D

func explode():
	match size: 
		AsteroidSize.LARGE:
			$ExplodeSoundLg.play()
			spawnSiblingInParent(AsteroidSize.MEDIUM)
			spawnSiblingInParent(AsteroidSize.MEDIUM)
		AsteroidSize.MEDIUM:
			$ExplodeSoundMd.play()
			spawnSiblingInParent(AsteroidSize.SMALL)
			spawnSiblingInParent(AsteroidSize.SMALL)
		AsteroidSize.SMALL:
			$ExplodeSoundSm.play()

	Events.AsteroidExploded.emit(self)
	queue_free()


func spawnSiblingInParent(siblingSize):
	var a = duplicate()
	a.global_position = global_position
	a.size = siblingSize
	get_parent().call_deferred("add_child", a)


func _ready():	
	rotation = randf_range(0, 2*PI)
	
	match size:
		AsteroidSize.LARGE:
			speed = randf_range(50, 100)
			sprite.texture = preload("res://assets/kenney_space-shooter-redux/PNG/Meteors/meteorGrey_big1.png")
			cshape.shape = preload("res://resources/asteroid_large_cshape.tres")
		AsteroidSize.MEDIUM:
			speed = randf_range(100, 150)
			sprite.texture = preload("res://assets/kenney_space-shooter-redux/PNG/Meteors/meteorGrey_med1.png")
			cshape.shape = preload("res://resources/asteroid_medium_cshape.tres")
		AsteroidSize.SMALL:
			speed = randf_range(150, 200)
			sprite.texture = preload("res://assets/kenney_space-shooter-redux/PNG/Meteors/meteorGrey_small1.png")
			cshape.shape = preload("res://resources/asteroid_small_cshape.tres")


func _physics_process(_delta):
	#global_position += movementVector.rotated(rotation) * speed * delta
	
	#teleoprt to the other side of the screen when you go off the edge
	var radius = cshape.shape.radius
	var screenSize = get_viewport_rect().size
	if global_position.y + radius < 0: 
		global_position.y = screenSize.y + radius
	elif global_position.y - radius > screenSize.y:
		global_position.y = 0 - radius
	
	if global_position.x + radius < 0: 
		global_position.x = screenSize.x + radius
	elif global_position.x - radius > screenSize.x:
		global_position.x = 0 - radius

func _on_area_entered(area):
	if(area is Laser):
		area.queue_free()
		explode()
	else:
		Events.AsteroidHitArea.emit(self, area)


func _on_area_2d_body_entered(body):
	Events.AsteroidHitBody.emit(self, body)
