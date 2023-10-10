extends Control

var previous_scene

func _on_back_button_pressed():
	hide()
	previous_scene.show()

func _on_h_slider_value_changed(value):
	pass # TODO sound handling
