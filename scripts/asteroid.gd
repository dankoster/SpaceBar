class_name Asteroid extends RigidBody2D

var movementVector := Vector2(0,-1)
var speed := 50.0

enum AsteroidSize { NONE, LARGE, MEDIUM, SMALL }
const AsteroidMass = {
	Asteroid.AsteroidSize.LARGE: 10,
	Asteroid.AsteroidSize.MEDIUM: 5,
	Asteroid.AsteroidSize.SMALL: 1
}

@export var size := AsteroidSize.LARGE

@onready var sprite = $Sprite2D
@onready var cshape = $CollisionShape2D

func explode(velocity: Vector2):
	var vel1 = velocity.orthogonal() * 100
	var vel2 = vel1.rotated(deg_to_rad(20))
	var newMass =  AsteroidMass[size + 1] if size < (AsteroidSize.size() -1)  else 1

	match size: 
		AsteroidSize.LARGE:
			$ExplodeSoundLg.play()
			spawnSiblingInParent(AsteroidSize.MEDIUM, vel1, newMass)
			spawnSiblingInParent(AsteroidSize.MEDIUM, vel2, newMass)
		AsteroidSize.MEDIUM:
			$ExplodeSoundMd.play()
			spawnSiblingInParent(AsteroidSize.SMALL, vel1, newMass)
			spawnSiblingInParent(AsteroidSize.SMALL, vel2, newMass)
		AsteroidSize.SMALL:
			$ExplodeSoundSm.play()

	Events.AsteroidExploded.emit(self)
	queue_free()


func spawnSiblingInParent(siblingSize: AsteroidSize, velocity: Vector2, newMass: float):
	var a = duplicate()
	a.global_position = global_position
	a.size = siblingSize
	a.linear_velocity = velocity
	a.mass = newMass
	get_parent().call_deferred("add_child", a)


func _ready():	
	rotation = randf_range(0, 2*PI)

	match size:
		AsteroidSize.LARGE:
			speed = randf_range(50, 100)
			sprite.texture = preload("res://assets/meteorGrey_big1.png")
			cshape.shape = preload("res://resources/asteroid_large_cshape.tres")
		AsteroidSize.MEDIUM:
			speed = randf_range(100, 150)
			sprite.texture = preload("res://assets/meteorGrey_med1.png")
			cshape.shape = preload("res://resources/asteroid_medium_cshape.tres")
		AsteroidSize.SMALL:
			speed = randf_range(150, 200)
			sprite.texture = preload("res://assets/meteorGrey_small1.png")
			cshape.shape = preload("res://resources/asteroid_small_cshape.tres")


#func _physics_process(_delta):
	#global_position += movementVector.rotated(rotation) * speed * delta
	
	#teleoprt to the other side of the screen when you go off the edge
	#var radius = cshape.shape.radius
	#var screenSize = get_viewport_rect().size
	#if global_position.y + radius < 0: 
		#global_position.y = screenSize.y + radius
	#elif global_position.y - radius > screenSize.y:
		#global_position.y = 0 - radius
	#
	#if global_position.x + radius < 0: 
		#global_position.x = screenSize.x + radius
	#elif global_position.x - radius > screenSize.x:
		#global_position.x = 0 - radius

func _on_area_entered(area):
	if(area is Laser):
		area.queue_free()
		explode(Vector2.ZERO)
	else:
		Events.AsteroidHitArea.emit(self, area)


func _on_area_2d_body_entered(body):
	Events.AsteroidHitBody.emit(self, body)
