extends Control

enum TreesTypes {OAK, PRIMAL_OAK}
signal chosen_tree_changed
func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		chosen_tree_changed.emit(null)
		$PanelContainer/HBoxContainer/PrimalOakButton.release_focus()
		$PanelContainer/HBoxContainer/OakButton.release_focus()

func change_progress_bar_value(value):
	$ProgressBar.value = value

func change_currency_amout(value):
	$ColorRect/NaturePoints/NaturePointsAmount.text = str(value)


func _on_primal_oak_button_pressed():
	chosen_tree_changed.emit(TreesTypes.PRIMAL_OAK)


func _on_oak_button_pressed():
	chosen_tree_changed.emit(TreesTypes.OAK)
