extends Node

var tetherLength := 0.0
var source: PhysicsBody2D
var target: PhysicsBody2D

@export var pullStrength = 0.01

func _ready():
	source = get_parent()
	assert(source is PhysicsBody2D)
	$DampedSpringJoint2D.node_a = source.get_path()

func setBeamTarget(node: PhysicsBody2D):
	if (node):
		target = node
		tetherLength = source.global_position.distance_to(target.global_position)
		$Line2D.add_point(source.global_position)
		$Line2D.add_point(target.global_position)
		$DampedSpringJoint2D.node_b = target.get_path()
	else:
		target = null
		tetherLength = 0.0
		$Line2D.clear_points()
		$DampedSpringJoint2D.node_b = ""

func _physics_process(_delta):
	if target:
		$Line2D.set_point_position(0, source.global_position)
		$Line2D.set_point_position(1, target.global_position)

		#constrain position and direction
		var targetToSelf = source.global_position - target.global_position
		var length = targetToSelf.length()
		if length > tetherLength:
			#turn the velocity vecrtor toward the target (effectively collide with
			# a virtual sphere around the target
			var normalToTarget = source.global_position.direction_to(target.global_position)
			source.velocity = source.velocity.slide(normalToTarget)
			
			#rotate in the direction of travel
			source.rotation = source.velocity.orthogonal().rotated(deg_to_rad(180)).angle()

			#TODO: replace spring with force calculations for moving the target
			$DampedSpringJoint2D.node_b = target.get_path()
			# if target is RigidBody2D:
			# 	target.apply_impulse()
			# 	target.apply_torque_impulse()
			
		# add a little velocity as the tether is pulling in
		# shorten the tether if we're approaching the target so we don't go past and bounce
		elif length < tetherLength:
			source.velocity += source.velocity * pullStrength 
			tetherLength = length
		
		$DampedSpringJoint2D.look_at(target.global_position)
