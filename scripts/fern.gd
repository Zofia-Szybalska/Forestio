extends Node2D

signal has_grown

@export var currency_generated: int = 0
@export var currency_generation_time: int = 1
@export var currency_cost = 10
@export var growth_time: int = 2
var growth_state = 0
var tile
var surronding_tiles_radius1 = []
var can_be_killed = false
var max_radius = 1
var type = "fern that can remove super pollution"

func _ready():
	$AnimatedSprite2D.play("seedling")
	$CurrencyTimer.wait_time = currency_generation_time

func fully_grown():
	growth_state = 4
	$AnimatedSprite2D.play("fully_grown")

func get_time_to_next_expansion():
	return $GrowthTimer.get_time_left()

func _on_growth_timer_timeout():
	growth_state += 1
	if growth_state == 1:
		$AnimatedSprite2D.play("fully_grown")
	elif growth_state == 2:
		has_grown.emit(surronding_tiles_radius1)
		$GrowthTimer.stop()

func kill():
	print("To paprotka, jej się nie da zabić, weź to napraw.")
