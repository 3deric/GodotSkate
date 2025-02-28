extends Control

@onready var color_picker_button_top_base: ColorPickerButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Clothes/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ColorPickerButton_Top_Base
@onready var color_picker_button_top_accent: ColorPickerButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Clothes/MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/ColorPickerButton_Top_Accent
@onready var color_picker_button_top_detail: ColorPickerButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Clothes/MarginContainer/VBoxContainer/MarginContainer3/HBoxContainer/ColorPickerButton_Top_Detail
@onready var color_picker_button_bottom_base: ColorPickerButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Clothes/MarginContainer/VBoxContainer/MarginContainer4/HBoxContainer/ColorPickerButton_Bottom_Base
@onready var color_picker_button_bottom_accent: ColorPickerButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Clothes/MarginContainer/VBoxContainer/MarginContainer5/HBoxContainer/ColorPickerButton_Bottom_Accent
@onready var color_picker_button_bottom_detail: ColorPickerButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Clothes/MarginContainer/VBoxContainer/MarginContainer6/HBoxContainer/ColorPickerButton_Bottom_Detail
@onready var color_picker_button_shoes_base: ColorPickerButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Clothes/MarginContainer/VBoxContainer/MarginContainer7/HBoxContainer/ColorPickerButton_Shoes_Base
@onready var color_picker_button_shoes_accent: ColorPickerButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Clothes/MarginContainer/VBoxContainer/MarginContainer8/HBoxContainer/ColorPickerButton_Shoes_Accent
@onready var color_picker_button_shoes_detail: ColorPickerButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Clothes/MarginContainer/VBoxContainer/MarginContainer9/HBoxContainer/ColorPickerButton_Shoes_Detail
@onready var color_picker_button_wheels: ColorPickerButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Board/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ColorPickerButton_Wheels
@onready var color_picker_button_details: ColorPickerButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Board/MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/ColorPickerButton_Details
@onready var color_picker_button_metal: ColorPickerButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Board/MarginContainer/VBoxContainer/MarginContainer3/HBoxContainer/ColorPickerButton_Metal



func _ready() -> void:
	_setup_options()
	CustomizationManager.customization_updated.connect(_update_ui_from_data)


func _setup_options() -> void:
	var data = CustomizationManager.character_data
	color_picker_button_top_base.color = data.top_base_color
	color_picker_button_top_accent.color = data.top_accent_color
	color_picker_button_top_detail.color = data.top_detail_color
	color_picker_button_bottom_base.color = data.bottom_base_color
	color_picker_button_bottom_accent.color = data.bottom_accent_color
	color_picker_button_bottom_detail.color = data.bottom_detail_color
	color_picker_button_shoes_base.color = data.shoes_base_color
	color_picker_button_shoes_accent.color = data.shoes_accent_color
	color_picker_button_shoes_detail.color = data.shoes_detail_color
	color_picker_button_wheels.color = data.board_wheels_color
	color_picker_button_details.color = data.board_accent_color
	color_picker_button_metal.color = data.board_metal_color
	
	
func _update_ui_from_data() -> void:
	var data = CustomizationManager.character_data
	color_picker_button_top_base.color = data.top_base_color
	color_picker_button_top_accent.color = data.top_accent_color
	color_picker_button_top_detail.color = data.top_detail_color
	color_picker_button_bottom_base.color = data.bottom_base_color
	color_picker_button_bottom_accent.color = data.bottom_accent_color
	color_picker_button_bottom_detail.color = data.bottom_detail_color
	color_picker_button_shoes_base.color = data.shoes_base_color
	color_picker_button_shoes_accent.color = data.shoes_accent_color
	color_picker_button_shoes_detail.color = data.shoes_detail_color
	color_picker_button_wheels.color = data.board_wheels_color
	color_picker_button_details.color = data.board_accent_color
	color_picker_button_metal.color = data.board_metal_color
	

func _on_color_picker_button_top_base_color_changed(color: Color) -> void:
	CustomizationManager.update_color(CharacterData.CharacterPart.Top, 'base', color)


func _on_color_picker_button_top_accent_color_changed(color: Color) -> void:
	CustomizationManager.update_color(CharacterData.CharacterPart.Top, 'accent', color)


func _on_color_picker_button_top_detail_color_changed(color: Color) -> void:
	CustomizationManager.update_color(CharacterData.CharacterPart.Top, 'detail', color)


func _on_color_picker_button_bottom_base_color_changed(color: Color) -> void:
	CustomizationManager.update_color(CharacterData.CharacterPart.Bottom, 'base', color)
		

func _on_color_picker_button_bottom_accent_color_changed(color: Color) -> void:
	CustomizationManager.update_color(CharacterData.CharacterPart.Bottom, 'accent', color)


func _on_color_picker_button_bottom_detail_color_changed(color: Color) -> void:
	CustomizationManager.update_color(CharacterData.CharacterPart.Bottom, 'detail', color)


func _on_color_picker_button_shoes_base_color_changed(color: Color) -> void:
	CustomizationManager.update_color(CharacterData.CharacterPart.Shoes, 'base', color)


func _on_color_picker_button_shoes_accent_color_changed(color: Color) -> void:
	CustomizationManager.update_color(CharacterData.CharacterPart.Shoes, 'accent', color)
	

func _on_color_picker_button_shoes_detail_color_changed(color: Color) -> void:
	CustomizationManager.update_color(CharacterData.CharacterPart.Shoes, 'detail', color)



func _on_color_picker_button_wheels_color_changed(color: Color) -> void:
	CustomizationManager.update_color(CharacterData.CharacterPart.Board, 'wheels', color)


func _on_color_picker_button_details_color_changed(color: Color) -> void:
	CustomizationManager.update_color(CharacterData.CharacterPart.Board, 'accent', color)


func _on_color_picker_button_metal_color_changed(color: Color) -> void:
	CustomizationManager.update_color(CharacterData.CharacterPart.Board, 'metal', color)
