extends Control

var options_scene = preload("res://scenes/UI/options.tscn").instantiate()

func _ready():
	get_parent().add_child.call_deferred(options_scene)
	options_scene.hide()
	options_scene.previous_menu = self

func _on_cross_texturebutton_pressed():
	_on_resume_button_pressed()

func _on_resume_button_pressed():
	hide()
	get_tree().paused = false

func _on_options_button_pressed():
	options_scene.show()
	hide()

func _on_main_menu_button_pressed():
	#TODO ask if player want to save
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")

func _on_save_button_pressed():
	#TODO save option
	pass

func _on_quit_button_pressed():
	#TODO poput asking if player is sure about eqiting/ want to save
	get_tree().quit()
