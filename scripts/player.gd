extends CharacterBody2D

signal laser_shot(laser)

@export var acceleration := 10.0
@export var maxSpeed := 550
@export var rotation_speed := 250.0

@onready var gun = $Gun

var shotCooldown = false
var shotRate = 0.15

var laser_scene = preload("res://scenes/laser.tscn")

func _process(delta):
	if Input.is_action_pressed("shoot"):
		if !shotCooldown: 
			shotCooldown = true
			shoot_laser()
			await get_tree().create_timer(shotRate).timeout
			shotCooldown = false
		
func shoot_laser(): 
	var l = laser_scene.instantiate()
	l.global_position = gun.global_position
	l.rotation = rotation
	emit_signal("laser_shot", l)


func _physics_process(delta):
	
	var inputVector := Vector2(0, Input.get_axis("move_forward", "move_backward"))
	
	
	velocity += inputVector.rotated(rotation) * acceleration
	velocity = velocity.limit_length(maxSpeed)
	
	if Input.is_action_pressed("rotate_right"):
		rotate(deg_to_rad(rotation_speed * delta))
	if Input.is_action_pressed("rotate_left"):
		rotate(deg_to_rad(-rotation_speed * delta))
	
	if inputVector.y == 0: 
		#decrease speed incrementally when no accelleration button pressed
		velocity = velocity.move_toward(Vector2.ZERO, 3)
		
	move_and_slide()
	
	var screenSize = get_viewport_rect().size
	if global_position.y < 0: 
		global_position.y = screenSize.y
	elif global_position.y > screenSize.y:
		global_position.y = 0
		
	if global_position.x < 0: 
		global_position.x = screenSize.x
	elif global_position.x > screenSize.x:
		global_position.x = 0

#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0
#
## Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
#
#
#func _physics_process(delta):
	## Add the gravity.
	#if not is_on_floor():
		#velocity.y += gravity * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var direction = Input.get_axis("ui_left", "ui_right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
#
	#move_and_slide()
