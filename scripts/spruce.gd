extends Node2D

signal has_grown
signal generated_currency

@export var currency_per_second = 1
@export var currency_cost = 10
var growth_state = 0
var tile
var surronding_tiles_radius1 = []
var surronding_tiles_radius2 = []


func _ready():
	$AnimatedSprite2D.play("seedling")

func fully_grown():
	growth_state = 4
	$AnimatedSprite2D.play("fully_grown")

func _on_currency_timer_timeout():
	generated_currency.emit(currency_per_second)


func _on_growth_timer_timeout():
	if growth_state < 3:
		growth_state += 1
	if growth_state == 1:
		$AnimatedSprite2D.play("fully_grown")
	elif growth_state == 2:
		has_grown.emit(surronding_tiles_radius1)
	else:
		has_grown.emit(surronding_tiles_radius2)
		$GrowthTimer.stop()

func kill():
	$CurrencyTimer.stop()
	$GrowthTimer.stop()
	if growth_state < 1:
		$AnimatedSprite2D.play("seedling_dead")
	else:
		$AnimatedSprite2D.play("fully_grown_dead")
