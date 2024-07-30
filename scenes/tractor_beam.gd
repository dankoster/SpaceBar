extends Node

@onready var spring = $DampedSpringJoint2D

@export var is_casting: bool: 
	set(value): 
		$LaserBeam2D.is_casting = value
		$DampedSpringJoint2D.node_b = target if value else null
	get(): 
		return $LaserBeam2D.is_casting

@export var source: PhysicsBody2D:
	set(value): spring.node_a = value
	get(): return spring.node_a

@export var target: PhysicsBody2D:
	set(value): target = value
	get(): return target

func _physics_process(_delta):
	if target: 
		$LaserBeam2D.look_at(target)
