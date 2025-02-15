extends Control


func _ready() -> void:
	_set_icons()
	
	
func _set_icons():
	var _container : TabContainer = $HBoxContainer/TabContainer
	_container.set_tab_icon(0, load("res://Assets/UI/T_ui_icon_character.png"))
	_container.set_tab_icon(1, load("res://Assets/UI/T_ui_icon_clothes.png"))
	_container.set_tab_icon(2, load("res://Assets/UI/T_ui_icon_board.png"))
