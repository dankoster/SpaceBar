extends Control

var uiLife = preload("res://scenes/ui_life.tscn")


@onready var score = $Score:
	set(value): 
		score.text = "SCORE: " + str(value)

@onready var lives = $LivesContainer:
	set(value): 
		var count := lives.get_child_count()
		while count > value: 
			count -= 1
			lives.get_child(count).queue_free()
		while count < value:
			lives.add_child(uiLife.instantiate())
