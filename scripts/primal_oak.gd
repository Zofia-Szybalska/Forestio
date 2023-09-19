extends Node2D

signal has_grown
signal generated_currency
signal game_lost

@export var currency_generated:int = 2
@export var currency_generation_time: int = 1
@export var currency_cost = 10
@export var growth_time: int = 10
var growth_state = 0
var tile
var can_be_killed = true
var surronding_tiles_radius1 = []
var surronding_tiles_radius2 = []
var surronding_tiles_radius3 = []
var max_radius = 3
var type = "primal oak tree"

func _ready():
	$AnimatedSprite2D.play("seedling")
	$CurrencyTimer.wait_time = currency_generation_time

func fully_grown():
	growth_state = 4
	$AnimatedSprite2D.play("fully_grown")

func get_time_to_next_expansion():
	return $GrowthTimer.get_time_left()

func _on_currency_timer_timeout():
	generated_currency.emit(currency_generated)

func _on_growth_timer_timeout():
	if growth_state < 4:
		growth_state += 1
	if growth_state == 1:
		$AnimatedSprite2D.play("fully_grown")
	elif growth_state == 2:
		has_grown.emit(surronding_tiles_radius1)
	elif growth_state == 3:
		has_grown.emit(surronding_tiles_radius2)
	else:
		has_grown.emit(surronding_tiles_radius3)

func kill():
	$CurrencyTimer.stop()
	$GrowthTimer.stop()
	game_lost.emit("Your Primal Oak was destroyed, you lost!")
	if growth_state < 1:
		$AnimatedSprite2D.play("seedling_dead")
	else:
		$AnimatedSprite2D.play("fully_grown_dead")

