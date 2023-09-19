extends Node2D

signal has_grown
signal generated_currency
signal game_lost

@export var currency_generated: int = 1
@export var currency_generation_time: int = 1
@export var currency_cost: int = 10
@export var growth_time: int = 5
var growth_state = 0
var tile
var can_be_killed = true
var surronding_tiles_radius1 = []
var surronding_tiles_radius2 = []
var max_radius = 2
var type = "spruce tree"

func _ready():
	$AnimatedSprite2D.play("seedling")
	$CurrencyTimer.wait_time = currency_generation_time
	$GrowthTimer.wait_time = growth_time

func fully_grown():
	growth_state = 4
	$AnimatedSprite2D.play("fully_grown")

func _on_currency_timer_timeout():
	generated_currency.emit(currency_generated)


func _on_growth_timer_timeout():
	if growth_state < 3:
		growth_state += 1
	if growth_state == 1:
		$AnimatedSprite2D.play("fully_grown")
	elif growth_state == 2:
		has_grown.emit(surronding_tiles_radius1)
	else:
		has_grown.emit(surronding_tiles_radius2)

func get_time_to_next_expansion():
	return $GrowthTimer.get_time_left()

func kill():
	$CurrencyTimer.stop()
	$GrowthTimer.stop()
	game_lost.emit("Your Primal Spruce was destroyed, you lost!")
	if growth_state < 1:
		$AnimatedSprite2D.play("seedling_dead")
	else:
		$AnimatedSprite2D.play("fully_grown_dead")
