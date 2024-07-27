extends Area2D

var isEmpty: bool: 
	get:
		return !has_overlapping_areas() && !has_overlapping_bodies()
