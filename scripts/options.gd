extends Control

var previous_menu

func _on_back_button_pressed():
	hide()
	previous_menu.show()

func _on_h_slider_value_changed(value):
	pass # TODO sound handling
