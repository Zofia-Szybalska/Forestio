extends Control

var options_scene = preload("res://scenes/UI/options.tscn").instantiate()

func _ready():
	get_tree().root.add_child.call_deferred(options_scene)
	options_scene.previous_scene = self

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/levels/level.tscn")

func _on_load_button_pressed():
	pass # Replace with function body.

func _on_options_button_pressed():
	options_scene.show()
	hide()

func _on_credits_button_pressed():
	pass

func _on_quit_button_pressed():
	get_tree().quit()
