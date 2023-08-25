extends Node2D

var tile
var is_destroyed = false

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
	print("Fabryka zniszczona.")

func _on_expand_timer_timeout():
	if curr_expansion_radius <= 3:
		expanded.emit(tile, curr_expansion_radius, 0)
		curr_expansion_radius += 1
	else:
		expanded.emit(tile, 3, 1)

