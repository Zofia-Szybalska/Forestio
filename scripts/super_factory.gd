extends Node2D

var tile
var is_destroyed = false
var surronding_tiles_radius1 = []
var surronding_tiles_radius2 = []
var surronding_tiles_radius3 = []

@export var curr_expansion_radius: int = 1
@export var currency_taken_per_second: int = 1

signal expanded
signal currency_decreased

func _ready():
	$AnimatedSprite2D.play("working")

func destroy():
	is_destroyed = true
	$ExpandTimer.queue_free()
	$Smoke.queue_free()
	$AnimatedSprite2D.play("destroyed")

func _on_expand_timer_timeout():
	print("zaczyna rosnąć, ", curr_expansion_radius)
	if curr_expansion_radius == 1:
		expanded.emit(surronding_tiles_radius1, 0, "super_pollution")
		curr_expansion_radius += 1
	elif curr_expansion_radius == 2:
		expanded.emit(surronding_tiles_radius2, 0, "super_pollution")
		curr_expansion_radius += 1
	else:
		expanded.emit(surronding_tiles_radius3, 1, "super_pollution")

