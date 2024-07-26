class_name Player extends CharacterBody2D

signal laser_shot(laser)
signal died(player)
signal spawned(player)

@export var acceleration := 10.0
@export var maxSpeed := 550
@export var rotation_speed := 250.0

@onready var gun = $Gun
@onready var sprite = $Sprite2D

var shotCooldown := false
var shotRate := 0.15
var isAlive := true

var laser_scene = preload("res://scenes/laser.tscn")

func _ready():
	pass

func _process(_delta):
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
	#TODO: explosion!
	isAlive = false
	sprite.visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	emit_signal("died", self)


func respawn(position):
	assert(!isAlive, "tried to respawn while isAlive")
	isAlive = true
	sprite.visible = true
	global_position = position
	process_mode = Node.PROCESS_MODE_INHERIT
	emit_signal("spawned", self)
