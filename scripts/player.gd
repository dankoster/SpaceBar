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
		$DampedSpringJoint2D.node_b = target.get_path()
		

	if Input.is_action_just_released("shoot"): 
		$LaserBeam2D.is_casting = false
		$DampedSpringJoint2D.node_b = ""
	
	#if Input.is_action_pressed("shoot"):
		#if !shotCooldown: 
			#shotCooldown = true
			#shoot_laser()
			#await get_tree().create_timer(shotRate).timeout
			#shotCooldown = false

	#if Input.is_action_pressed("rotate_right"):
		#apply_torque_impulse(rotation_speed)
	#if Input.is_action_pressed("rotate_left"):
		#apply_torque_impulse(-rotation_speed)
	#
	#if Input.is_action_pressed("move_forward"):
		#var inputVector := Vector2(0, Input.get_axis("move_forward", "move_backward"))
		#apply_impulse(inputVector.rotated(rotation) * acceleration)

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
	
	#TODO: Always face direction of travel
	# accelerate in direction of travel
	# wait until the player is moving tangental
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

	if elapsed < 1:
		rotation = lerp_angle(rotation, velocity.angle() + deg_to_rad(90), elapsed)
		elapsed += delta * 0.05
		

	var collision = move_and_collide(velocity)
	if collision:
		print("I collided with ", collision.get_collider().name)
		velocity = velocity.slide(collision.get_normal())
		

	#only need to change the target sometimes
	if !target || !$LaserBeam2D.is_casting:
		target = nearestNode(get_parent().asteroids.get_children())

	#always look at the target when we move
	$LaserBeam2D.look_at(target.global_position)
	$DampedSpringJoint2D.look_at(target.global_position)
	

	#teleoprt to the other side of the screen when you go off the edge
	var screenSize = get_viewport_rect().size
	if global_position.y < 0: 
		global_position.y = screenSize.y
	elif global_position.y > screenSize.y:
		global_position.y = 0
	if global_position.x < 0: 
		global_position.x = screenSize.x
	elif global_position.x > screenSize.x:
		global_position.x = 0


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
