extends Node2D

var tile
var is_destroyed = false
var surronding_tiles_radius1 = []
var surronding_tiles_radius2 = []
var surronding_tiles_radius3 = []
var type = "Super factory."
var max_radius = 3

@export var curr_expansion_radius: int = 1
@export var currency_taken_per_second: int = 1
@export var expand_time: int = 20

signal expanded
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
	if curr_expansion_radius == 1:
		expanded.emit(surronding_tiles_radius1, "super_pollution")
		curr_expansion_radius += 1
	elif curr_expansion_radius == 2:
		expanded.emit(surronding_tiles_radius2, "super_pollution")
		curr_expansion_radius += 1
	else:
		expanded.emit(surronding_tiles_radius3, "super_pollution")

