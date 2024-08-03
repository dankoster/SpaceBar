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
@onready var originalColor :Color = sprite.self_modulate

var laser_scene = preload("res://scenes/laser.tscn")

var shotCooldown := false
var shotRate := 0.15
var isAlive := true
var target: PhysicsBody2D
var elapsed := 1.0
var tetherLength := 0.0

func setBeamTarget(node: Node2D): 
	if(node):
		target = node
		$LaserBeam2D.is_casting = true
		tetherLength = global_position.distance_to(target.global_position)
		print(str(Time.get_ticks_msec()) + " ---- LASER! ----> " + str(target.name) + " " + str(tetherLength))
		#sprite.self_modulate = Color.FUCHSIA
	else:
		$LaserBeam2D.is_casting = false
		$DampedSpringJoint2D.node_b = ""
		tetherLength = 0.0 
		target = null
		#sprite.self_modulate = originalColor
		print(str(Time.get_ticks_msec()) + ' ------------------')

func _process(delta):
	if !isAlive: return
	
	if Input.is_action_just_pressed("shoot"): 
		setBeamTarget(nearestNode(get_parent().asteroids.get_children()))

	if Input.is_action_just_released("shoot"): 
		setBeamTarget(null)
	
	if Input.is_action_pressed("rotate_right"):
		rotate(deg_to_rad(rotation_speed * delta))
	if Input.is_action_pressed("rotate_left"):
		rotate(deg_to_rad(-rotation_speed * delta))
	
	if Input.is_anything_pressed():
		elapsed = 0.0

func _physics_process(delta):
	
	#TODO: wait until the player is moving tangental
	# to the target object before attaching the spring
	
	var axis := Input.get_axis("move_forward", "move_backward")
	if axis:
		var inputVector := Vector2(0, axis)
		velocity += inputVector.rotated(rotation) * acceleration * delta
		velocity = velocity.limit_length(maxSpeed)

	#correct totation to face velocity vector up
	correctRotation(delta, 0.01)


	#only need to change the target sometimes
	#TODO: constrain motion https://code.tutsplus.com/swinging-physics-for-player-movement-as-seen-in-spider-man-2-and-energy-hook--gamedev-8782t
	if $LaserBeam2D.is_casting:
		assert(target.global_position, "invalid target!")
		
		#constrain position and direction
		var targetToSelf = global_position - target.global_position
		var length = targetToSelf.length()
		if length > tetherLength: 
			#turn the velocity vecrtor toward the target (effectively collide with
			# a virtual sphere around the target
			var normalToTarget = global_position.direction_to(target.global_position)
			velocity = velocity.slide(normalToTarget)
			
			#rotate in the direction of travel
			rotation = velocity.orthogonal().rotated(deg_to_rad(180)).angle()
			$DampedSpringJoint2D.node_b = target.get_path()
			
		#shorten the tether if we're approaching the target so we don't go past and bounce
		elif length < tetherLength:	
			tetherLength = length
		
		$LaserBeam2D.look_at(target.global_position)
		$DampedSpringJoint2D.look_at(target.global_position)
		
	var collision = move_and_collide(velocity)
	if collision:
		print(str(Time.get_ticks_msec()) + " collided with ", collision.get_collider().name)
		velocity = velocity.slide(collision.get_normal())
		elapsed = 0.0
		explode()


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


func correctRotation(delta, factor := 0.001): 
	if elapsed < 1:
		var targetAngle = velocity.angle() + deg_to_rad(90)
		rotation = lerp_angle(rotation, targetAngle, elapsed)
		elapsed += delta * (velocity.length() * factor)
		
		var targetVector = Vector2.from_angle(rotation)
		var vNorm = velocity.normalized()
		var angleDiff = vNorm.dot(targetVector)
		if(abs(angleDiff) < 0.01):
			#print(str(Time.get_ticks_msec()) + " done correcting direction of travel:" + str(dot))
			elapsed = 1.0


func explode():
	assert(isAlive, "tried to explode while !isAlive")
	isAlive = false
	sprite.visible = false
	setBeamTarget(null)
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
