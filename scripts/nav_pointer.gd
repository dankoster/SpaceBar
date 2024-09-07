extends Node2D

@export var target: Node

@export var color: Color:
	get(): return $Pointer.get_self_modulate()
	set(value): $Pointer.set_self_modulate(value)

@export var targetIsInView := false

func _physics_process(_delta):

	if target != null:
		var camera_viewport_size = get_canvas_transform().affine_inverse().basis_xform(get_viewport_rect().size)
		var camera_rect = Rect2(get_parent().global_position - (0.5 * camera_viewport_size),  camera_viewport_size)

		targetIsInView = camera_rect.has_point(target.global_position)
		$Pointer.visible = !targetIsInView
		if targetIsInView:
			global_position = target.global_position
			rotation = 0.0
		else:
			position = Vector2.ZERO
			look_at(target.global_position)

		queue_redraw()


func _draw():
	if target != null && targetIsInView:
		draw_circle(Vector2.ZERO, 90.0, Color.RED, false)