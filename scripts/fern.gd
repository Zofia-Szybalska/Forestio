extends Node2D

signal has_grown

@export var currency_cost = 10
var growth_state = 0
var tile
var surronding_tiles_radius1 = []
var can_be_killed = false


func _ready():
	$AnimatedSprite2D.play("seedling")

func fully_grown():
	growth_state = 4
	$AnimatedSprite2D.play("fully_grown")

func _on_growth_timer_timeout():
	growth_state += 1
	if growth_state == 1:
		$AnimatedSprite2D.play("fully_grown")
	elif growth_state == 2:
		has_grown.emit(surronding_tiles_radius1)
		$GrowthTimer.stop()

func kill():
	print("To paprotka, jej się nie da zabić, weź to napraw.")
