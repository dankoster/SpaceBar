class_name Player extends CharacterBody2D

signal laser_shot(laser)
signal died(player)
signal spawned(player)

@export var acceleration := 10.0
@export var maxSpeed := 550
@export var rotation_speed := 100.0

@onready var gun = $Gun
@onready var sprite = $Sprite2D
@onready var explodeSound = $Explode
@onready var laserSound = $Laser

var shotCooldown := false
var shotRate := 0.15
var isAlive := true

var laser_scene = preload("res://scenes/laser.tscn")

func _process(delta):
	if !isAlive: return
	
	if Input.is_action_just_pressed("shoot"): 
		$LaserBeam2D.is_casting = true
		target = nearestNode(get_parent().asteroids.get_children())
		print(str(Time.get_ticks_msec()) + " ---- LASER! ----> " + str(target))
		$DampedSpringJoint2D.node_b = target.get_path()

	if Input.is_action_just_released("shoot"): 
		$LaserBeam2D.is_casting = false
		$DampedSpringJoint2D.node_b = ""
		target = null

func shoot_laser(): 
	assert(isAlive, "tried to shoot a laser while !isAlive")
	var l = laser_scene.instantiate()
	l.global_position = gun.global_position
	l.rotation = rotation
	laserSound.play()
	laser_shot.emit(l)

func nearestNode(nodes: Array[Node]) -> Node:
	var nearest: Asteroid = null
	var nearestDist: float
	for a in nodes:
		var d = global_position.distance_to(a.global_position)
		if nearest == null || d < nearestDist: 
			nearest = a
			nearestDist = d
	return nearest

var target: PhysicsBody2D

var elapsed := 1.0
func _physics_process(delta):
	
	#TODO: wait until the player is moving tangental
	# to the target object before attaching the spring
	
	var axis := Input.get_axis("move_forward", "move_backward")
	if axis:
		var inputVector := Vector2(0, axis)
		velocity += inputVector.rotated(rotation) * acceleration * delta
		velocity = velocity.limit_length(maxSpeed)

	if Input.is_action_pressed("rotate_right"):
		rotate(deg_to_rad(rotation_speed * delta))
	if Input.is_action_pressed("rotate_left"):
		rotate(deg_to_rad(-rotation_speed * delta))
	
	if Input.is_anything_pressed():
		elapsed = 0.0

	#correct direction of travel to face velocity vector
	if elapsed < 1:
		var targetAngle = velocity.angle() + deg_to_rad(90)
		rotation = lerp_angle(rotation, targetAngle, elapsed)
		elapsed += delta * (velocity.length() * 0.001)
		
		var targetVector = Vector2.from_angle(rotation)
		var vNorm = velocity.normalized()
		var dot = vNorm.dot(targetVector)
		var msec = Time.get_ticks_msec()
		if(abs(dot) < 0.01):
			print(str(msec) + " done correcting direction of travel:" + str(dot))
			elapsed = 1.0
		
	var collision = move_and_collide(velocity)
	if collision:
		print(str(delta) + " collided with ", collision.get_collider().name)
		velocity = velocity.slide(collision.get_normal())
		elapsed = 0.0


	#only need to change the target sometimes
	#TODO: constrain motion https://code.tutsplus.com/swinging-physics-for-player-movement-as-seen-in-spider-man-2-and-energy-hook--gamedev-8782t
	if $LaserBeam2D.is_casting:
		target = nearestNode(get_parent().asteroids.get_children())
		print(str(Time.get_ticks_msec()) + " ---- LASER! ----> " + str(target))
		$LaserBeam2D.look_at(target.global_position)
		$DampedSpringJoint2D.look_at(target.global_position)
		$DampedSpringJoint2D.node_b = target.get_path()
	else:
		target = null
		$DampedSpringJoint2D.node_b = ""

func explode():
	assert(isAlive, "tried to explode while !isAlive")
	#TODO: explosion vfx!
	isAlive = false
	sprite.visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	explodeSound.play()
	died.emit(self)


func respawn(pos):
	assert(!isAlive, "tried to respawn while isAlive")
	isAlive = true
	sprite.visible = true
	global_position = pos
	$CollisionShape2D.set_deferred("disabled", false)
	spawned.emit(self)
