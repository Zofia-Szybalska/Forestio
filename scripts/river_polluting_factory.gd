extends Node2D

var tile
var is_destroyed = false
var water_tiles: Array = []
var starting_water_tiles: Array = []
var riverbank_tiles = []
var direction: Vector2i
var type = "River polluting factory."
var max_radius = "Pollutes the entire river below it."

@export var curr_expansion_radius = "rivers next to it."
@export var currency_taken_per_second: int = 1
@export var expand_time:int = 5

signal water_polluted
signal currency_decreased

func _ready():
	$AnimatedSprite2D.play("working")

func destroy():
	is_destroyed = true
	$ExpandTimer.queue_free()
	$Smoke.queue_free()
	$AnimatedSprite2D.play("destroyed")

func get_time_to_next_expansion():
	return $ExpandTimer.get_time_left()

func _on_expand_timer_timeout():
	if water_tiles.size() == 0:
		water_polluted.emit(starting_water_tiles, direction, tile, riverbank_tiles)
	else:
		water_polluted.emit(water_tiles, direction, tile, riverbank_tiles)

