extends CanvasLayer

enum TreesTypes {OAK, PRIMAL_OAK, SPRUCE, PRIMAL_SPRUCE}

var cross = load("res://assets/CrossCursor.png")

signal chosen_tree_changed
signal destroy_mode_changed


func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		chosen_tree_changed.emit(null)
		deactivate_destroy()
		$PanelContainer/HBoxContainer/PrimalOakButton.release_focus()
		$PanelContainer/HBoxContainer/OakButton.release_focus()
		$PanelContainer/HBoxContainer/SpruceButton.release_focus()
		$PanelContainer/HBoxContainer/PrimalSpruceButton.release_focus()
		$PanelContainer/HBoxContainer/DestroyButton.release_focus()

func change_progress_bar_value(value):
	$ProgressBar.value = value

func change_currency_amout(value):
	$ColorRect/NaturePoints/NaturePointsAmount.text = str(value)


func _on_primal_oak_button_pressed():
	chosen_tree_changed.emit(TreesTypes.PRIMAL_OAK)
	deactivate_destroy()


func _on_oak_button_pressed():
	chosen_tree_changed.emit(TreesTypes.OAK)
	deactivate_destroy()


func _on_spruce_button_pressed():
	chosen_tree_changed.emit(TreesTypes.SPRUCE)
	deactivate_destroy()


func _on_primal_spruce_button_pressed():
	chosen_tree_changed.emit(TreesTypes.PRIMAL_SPRUCE)
	deactivate_destroy()

func deactivate_destroy():
	destroy_mode_changed.emit(false)
	Input.set_custom_mouse_cursor(null)

func _on_destroy_button_pressed():
	Input.set_custom_mouse_cursor(cross, Input.CURSOR_ARROW, Vector2(16,16))
	destroy_mode_changed.emit(true)
