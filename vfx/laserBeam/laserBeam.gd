extends RayCast2D

@export var cast_speed := 15000.0
@export var max_length := 1400
@export var growth_time := 0.1

@onready var casting_particles := $CastingParticles2D
@onready var collision_particles := $CollisionParticles2D
@onready var beam_particles := $BeamParticles2D
@onready var line := $FillLine2D
@onready var beamWidth: float = line.width


#func _unhandled_input(event):
	#if(event is InputEventMouseButton):
		#self.is_casting = event.pressed


var is_casting := true: 
	set(value):
		is_casting = value
		if is_casting:
			appear()
		else:
			disappear()
		
		set_physics_process(is_casting)
		beam_particles.emitting = is_casting
		casting_particles.emitting = is_casting


func appear() -> void:
	target_position = Vector2.ZERO
	line.points[1] = target_position
	var tween = create_tween()
	tween.tween_property(line, "width", beamWidth, growth_time * 2).from(0)


func disappear() -> void:
	var tween = create_tween()
	tween.tween_property(line, "width", 0, growth_time).from_current()
	await tween.finished
	line.points[1] = Vector2.ZERO
	collision_particles.emitting = false


func _ready() -> void:
	set_physics_process(false)
	line.points[1] = Vector2.ZERO


func _physics_process(delta: float) -> void:
	target_position = (target_position + Vector2.RIGHT * cast_speed * delta).limit_length(max_length)
	var cast_point := target_position

	# Required, the raycast's collisions update one frame after moving otherwise, making the laser
	# overshoot the collision point.
	force_raycast_update()
	if is_colliding():
		cast_point = to_local(get_collision_point())
		collision_particles.process_material.direction = Vector3(
			get_collision_normal().x, get_collision_normal().y, 0
		)

	collision_particles.emitting = is_colliding()

	line.points[1] = cast_point
	collision_particles.position = cast_point
	beam_particles.position = cast_point * 0.5
	beam_particles.process_material.emission_box_extents.x = cast_point.length() * 0.5
