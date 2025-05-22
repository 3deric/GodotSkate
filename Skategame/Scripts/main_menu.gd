extends Control


@onready var panel_main: Panel = $"../MarginContainer/Container/PanelMain"
@onready var panel_customization: Panel = $"../MarginContainer/Container/PanelCustomization"
@onready var panel_options: Panel = $"../MarginContainer/Container/PanelOptions"


func _ready() -> void:
	pass # Replace with function body.


func _on_button_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/test_level.tscn")


func _on_button_options_pressed() -> void:
	panel_main.visible = false
	panel_customization.visible = false
	panel_options.visible = true


func _on_button_customization_pressed() -> void:
	panel_main.visible = false
	panel_customization.visible = true
	panel_options.visible = false


func _on_button_back_customization_pressed() -> void:
	panel_main.visible = true
	panel_customization.visible = false
	panel_options.visible = false


func _on_button_back_options_pressed() -> void:
	panel_main.visible = true
	panel_customization.visible = false
	panel_options.visible = false
