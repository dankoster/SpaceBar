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
		print('count: ' + str(count) + " value: " + str(value))
		
		while count > value: 
			count -= 1
			livesContainer.get_child(count).queue_free()
			print('removed one')
		while count < value:
			count += 1
			livesContainer.add_child(uiLife.instantiate())
			print('added one')
