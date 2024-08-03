extends Control

var uiLife = preload("res://scenes/ui_life.tscn")
@onready var livesContainer = $LivesContainer

@onready var score = $Score:
	set(value): 
		score.text = "SCORE: " + str(value)

@onready var lives: int:
	get(): return livesContainer.get_child_count()
	set(value): 
		var count := livesContainer.get_child_count()
		
		while count > value: 
			count -= 1
			livesContainer.get_child(count).queue_free()
		while count < value:
			count += 1
			livesContainer.add_child(uiLife.instantiate())
