class_name Player extends RigidBody2D

signal laser_shot(laser)
signal died(player)
signal spawned(player)

@export var acceleration := 10.0
@export var maxSpeed := 550
@export var rotation_speed := 10.0

@onready var gun = $Gun
@onready var sprite = $Sprite2D
@onready var explodeSound = $Explode
@onready var laserSound = $Laser

var shotCooldown := false
var shotRate := 0.15
var isAlive := true

var laser_scene = preload("res://scenes/laser.tscn")

func _process(_delta):
	if !isAlive: return
	
	if Input.is_action_pressed("shoot"):
		if !shotCooldown: 
			shotCooldown = true
			shoot_laser()
			await get_tree().create_timer(shotRate).timeout
			shotCooldown = false
	
	if Input.is_action_pressed("rotate_right"):
		apply_torque_impulse(rotation_speed)
	if Input.is_action_pressed("rotate_left"):
		apply_torque_impulse(-rotation_speed)
	
	if Input.is_action_pressed("move_forward"):
		var inputVector := Vector2(0, Input.get_axis("move_forward", "move_backward"))
		apply_impulse(inputVector.rotated(rotation) * acceleration)




func shoot_laser(): 
	assert(isAlive, "tried to shoot a laser while !isAlive")
	var l = laser_scene.instantiate()
	l.global_position = gun.global_position
	l.rotation = rotation
	laserSound.play()
	laser_shot.emit(l)


func _physics_process(_delta):
	if !isAlive: return
	
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
