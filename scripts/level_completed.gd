extends ColorRect

signal level_restarted

func _on_restart_button_pressed():
	print("Jesteśmy w funkcji",get_tree().current_scene)
	get_tree().reload_current_scene()
	get_tree().paused = false

func display(text):
	show()
	$CenterContainer/VBoxContainer/Label.text = text
