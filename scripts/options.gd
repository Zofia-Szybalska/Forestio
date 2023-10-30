extends Control

var previous_menu

func _on_back_button_pressed():
	hide()
	previous_menu.show()

