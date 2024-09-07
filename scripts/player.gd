class_name Player extends CharacterBody2D

signal laser_shot(laser)
signal died(player)
signal spawned(player)

@export var homePort: Node2D = null
@export var acceleration := 10.0
@export var maxSpeed := 550
@export var rotation_speed := 100.0
@export var fuel: float:
	get(): return $CanvasLayer/FuelGauge.value
	set(value): $CanvasLayer/FuelGauge.value = value

var cargo := {}

@onready var gun = $Gun
@onready var sprite = $Sprite2D
@onready var explodeSound = $Explode
@onready var laserSound = $Laser
@onready var cargoProgress = $CanvasLayer/CargoHold
@onready var cargoGrid = $CanvasLayer/GridContainer

var laser_scene = preload("res://scenes/laser.tscn")

var shotCooldown := false
var shotRate := 0.15
var isAlive := true
var target: PhysicsBody2D
var nearest: PhysicsBody2D
var navTarget: Asteroid
var elapsed := 1.0
var moveAxis: float = 0.0
var recalculateNearest: float = 0


func setBeamTarget(node: Node2D):
	if (node):
		$TractorBeam.setBeamTarget(node)
		target = node
	else:
		$TractorBeam.setBeamTarget(null)
		target = null


func _draw():
	draw_set_transform_matrix(get_global_transform().affine_inverse())
	
	if (nearest != null): draw_circle(nearest.global_position, 80.0, Color.GREEN, false)
	if (target != null): draw_circle(target.global_position, 60.0, Color.DODGER_BLUE, false)


func _process(delta):
	if !isAlive: return
	
	#recalculate nearest body every n-seconds
	recalculateNearest += delta
	if (recalculateNearest >= 0.01):
		recalculateNearest = 0.0
		var asteroids = get_parent().asteroids.get_children()
		nearest = nearestNode(global_position, asteroids)
		navTarget = nearestNode(global_position, asteroids, Materials.MaterialKind.EXPLODIUM)
		queue_redraw()
	
	moveAxis = Input.get_axis("move_forward", "move_backward")
	if (moveAxis != 0):
		if (fuel > 0): fuel -= (20 * delta)
		else: moveAxis = 0
	
	if Input.is_action_just_pressed("shoot"): setBeamTarget(nearest)
	if Input.is_action_just_released("shoot"): setBeamTarget(null)
	if Input.is_action_pressed("rotate_right"): rotate(deg_to_rad(rotation_speed * delta))
	if Input.is_action_pressed("rotate_left"): rotate(deg_to_rad(-rotation_speed * delta))
	if Input.is_anything_pressed(): elapsed = 0.0


func _physics_process(delta):
		
	if moveAxis:
		var inputVector := Vector2(0, moveAxis)
		velocity += inputVector.rotated(rotation) * acceleration * delta
		velocity = velocity.limit_length(maxSpeed)

	rotateTowardVelocityVector(delta, 0.01)

	$NavHome.target = homePort
	$NavTarget.target = navTarget

	if target is Asteroid:
		harvestFromTarget(target)
		
	var collision = move_and_collide(velocity)
	if collision:
		var collider = collision.get_collider()
		print(str(Time.get_ticks_msec()) + " collided with ", collider.name)
		velocity = velocity.slide(collision.get_normal())
		elapsed = 0.0
		Events.PlayerCollided.emit(self, collider)


func harvestFromTarget(asteroid: Asteroid):
	for kind in asteroid.payload:
		var amount = target.minePayload(kind, 0.1)
		addCargo(kind, amount)


func addCargo(kind: String, amount: float = 0.1):
	# $CanvasLayer/CargoHold.value = cargo[kind]
	if !cargo.has(kind): 
		var pb = ProgressBar.new()
		pb.value = amount
		pb.name = kind
		var label = Label.new()
		label.text = kind
		pb.add_child(label)
		cargoProgress.add_child(pb)		
		cargo[kind] = {
			"amount": amount,
			"pb": pb
		}
	else: 
		cargo[kind].amount += amount
		cargo[kind].pb.value = cargo[kind].amount


func shoot_laser():
	assert(isAlive, "tried to shoot a laser while !isAlive")
	var l = laser_scene.instantiate()
	l.global_position = gun.global_position
	l.rotation = rotation
	laserSound.play()
	laser_shot.emit(l)


static func nearestNode(from: Vector2, nodes: Array[Node], payload = null) -> Node:
	var n: Node2D = null
	var nearestDist: float
	var matNames := Materials.MaterialKind.keys() if payload is Materials.MaterialKind else []

	for a in nodes:
		if payload == null || (a.payload != null && a.payload.has(matNames[payload])):
			var distance = from.distance_to(a.global_position)
			if n == null || distance < nearestDist:
				n = a
				nearestDist = distance
	return n


func rotateTowardVelocityVector(delta, factor := 0.001):
	if elapsed < 1:
		var targetAngle = velocity.angle() + deg_to_rad(90)
		rotation = lerp_angle(rotation, targetAngle, elapsed)
		elapsed += delta * (velocity.length() * factor)
		
		var targetVector = Vector2.from_angle(rotation)
		var vNorm = velocity.normalized()
		var angleDiff = vNorm.dot(targetVector)
		if (abs(angleDiff) < 0.01):
			#print(str(Time.get_ticks_msec()) + " done correcting direction of travel:" + str(dot))
			elapsed = 1.0


func explode():
	assert(isAlive, "tried to explode while !isAlive")
	isAlive = false
	sprite.visible = false
	setBeamTarget(null)
	$CollisionShape2D.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	explodeSound.play()
	died.emit(self)


func respawn(pos):
	assert(!isAlive, "tried to respawn while isAlive")
	isAlive = true
	sprite.visible = true
	global_position = pos
	$CollisionShape2D.set_deferred("disabled", false)
	spawned.emit(self)
