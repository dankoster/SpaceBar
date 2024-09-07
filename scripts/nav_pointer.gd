extends Node2D

@export var color: Color:
	get(): return $Sprite2D.get_self_modulate()
	set(value): $Sprite2D.set_self_modulate(value)
