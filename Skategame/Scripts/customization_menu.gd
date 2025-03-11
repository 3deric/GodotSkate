extends Control

@onready var h_slider_skin_color: HSlider = $MarginContainer/HBoxContainer/Panel/TabContainer/Body/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/HSlider_Skin_Color
@onready var color_picker_button_eye_color: ColorPickerButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Body/MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/ColorPickerButton_Eye_Color
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
@onready var option_button_deck: OptionButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Board/MarginContainer/VBoxContainer/MarginContainer4/HBoxContainer/OptionButton_Deck
@onready var option_button_top_decal: OptionButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Clothes/MarginContainer/VBoxContainer/MarginContainer10/HBoxContainer/OptionButton_Top_Decal
@onready var color_picker_button_hair_color: ColorPickerButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Body/MarginContainer/VBoxContainer/MarginContainer3/HBoxContainer/ColorPickerButton_Hair_Color
@onready var option_button_hair: OptionButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Body/MarginContainer/VBoxContainer/MarginContainer6/HBoxContainer/OptionButton_Hair
@onready var option_button_top_style: OptionButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Clothes/MarginContainer/VBoxContainer/MarginContainerTopStyle/HBoxContainer/OptionButton_Top_Style
@onready var option_button_bottom_style: OptionButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Clothes/MarginContainer/VBoxContainer/MarginContainerPantsStyle/HBoxContainer/OptionButton_Bottom_Style
@onready var option_button_shoes_style: OptionButton = $MarginContainer/HBoxContainer/Panel/TabContainer/Clothes/MarginContainer/VBoxContainer/MarginContainerShoesStyle/HBoxContainer/OptionButton_Shoes_Style
@onready var h_slider_size: HSlider = $MarginContainer/HBoxContainer/Panel/TabContainer/Body/MarginContainer/VBoxContainer/MarginContainer4/HBoxContainer/HSlider_Size


func _ready() -> void:
	_setup_options()
	CustomizationManager.customization_updated.connect(_update_ui_from_data)


func _setup_options() -> void:
	var data = CustomizationManager.character_data
	option_button_deck.clear()
	option_button_deck.add_item("Wood", CharacterData.BoardDecal.Bare)
	option_button_deck.add_item("Style 1", CharacterData.BoardDecal.Style1)
	option_button_deck.add_item("Style 2", CharacterData.BoardDecal.Style2)
	option_button_top_decal.clear()
	option_button_top_decal.add_item("Empty", CharacterData.TopDecal.Bare)
	option_button_top_decal.add_item("Style 1", CharacterData.TopDecal.Style1)
	option_button_top_decal.add_item("Style 2", CharacterData.TopDecal.Style2)
	option_button_hair.clear()
	option_button_hair.add_item("Bald", CharacterData.HairMesh.Bald)
	option_button_hair.add_item("Style1", CharacterData.HairMesh.Style1)
	option_button_top_style.clear()
	option_button_top_style.add_item("Bare", CharacterData.TopMesh.Nothing)
	option_button_top_style.add_item("Hoodie", CharacterData.TopMesh.Hoodie)
	option_button_top_style.add_item("Shirt", CharacterData.TopMesh.Shirt)
	option_button_bottom_style.clear()
	option_button_bottom_style.add_item("Bare", CharacterData.BottomMesh.Nothing)
	option_button_bottom_style.add_item("Jeans", CharacterData.BottomMesh.Jeans)
	option_button_bottom_style.add_item("Shorts", CharacterData.BottomMesh.Shorts)
	option_button_shoes_style.clear()
	option_button_shoes_style.add_item("Bare", CharacterData.ShoesMesh.Nothing)
	option_button_shoes_style.add_item("Sneakers", CharacterData.ShoesMesh.Sneakers)
	option_button_shoes_style.add_item("Shoes Flat", CharacterData.ShoesMesh.FlatShoes)
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
	option_button_deck.selected = data.board_decal
	option_button_top_decal.selected = data.top_decal
	color_picker_button_eye_color.color = data.eye_color
	h_slider_skin_color.value = data.skin_color
	color_picker_button_hair_color.color = data.hair_color
	option_button_hair.selected = data.hair_mesh
	option_button_top_style.selected = data.top_mesh
	option_button_bottom_style.selected = data.bottom_mesh
	option_button_shoes_style.selected = data.shoes_mesh
	h_slider_size.value = data.size
	
	
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
	option_button_deck.selected = data.board_decal
	option_button_top_decal.selected = data.top_decal
	color_picker_button_eye_color.color = data.eye_color
	h_slider_skin_color.value = data.skin_color
	color_picker_button_hair_color.color = data.hair_color
	option_button_hair.selected = data.hair_mesh
	option_button_top_style.selected = data.top_mesh
	option_button_bottom_style.selected = data.bottom_mesh
	option_button_shoes_style.selected = data.shoes_mesh
	h_slider_size.value = data.size
		

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


func _on_option_button_deck_item_selected(index: int) -> void:
	CustomizationManager.update_decal(CharacterData.CharacterPart.Board, index)


func _on_option_button_top_decal_item_selected(index: int) -> void:
	CustomizationManager.update_decal(CharacterData.CharacterPart.Top, index)


func _on_h_slider_skin_color_value_changed(value: float) -> void:
	CustomizationManager.update_float(CharacterData.CharacterPart.Body, 'skin_color', value)


func _on_color_picker_button_eye_color_color_changed(color: Color) -> void:
	CustomizationManager.update_color(CharacterData.CharacterPart.Body, 'eyes', color)


func _on_color_picker_button_hair_color_color_changed(color: Color) -> void:
	CustomizationManager.update_color(CharacterData.CharacterPart.Hair, 'color', color)


func _on_option_button_hair_item_selected(index: int) -> void:
	CustomizationManager.update_mesh(CharacterData.CharacterPart.Hair, index)
	CustomizationManager.update_color(CharacterData.CharacterPart.Hair, 'color', color_picker_button_hair_color.color)


func _on_option_button_top_style_item_selected(index: int) -> void:
	CustomizationManager.update_mesh(CharacterData.CharacterPart.Top, index)
	CustomizationManager.update_color(CharacterData.CharacterPart.Top, 'base', color_picker_button_top_base.color)
	CustomizationManager.update_color(CharacterData.CharacterPart.Top, 'accent', color_picker_button_top_accent.color)
	CustomizationManager.update_color(CharacterData.CharacterPart.Top, 'detail', color_picker_button_top_detail.color)
	CustomizationManager.update_decal(CharacterData.CharacterPart.Top, option_button_top_decal.selected)


func _on_option_button_bottom_style_item_selected(index: int) -> void:
	CustomizationManager.update_mesh(CharacterData.CharacterPart.Bottom, index)
	CustomizationManager.update_color(CharacterData.CharacterPart.Bottom, 'base', color_picker_button_bottom_base.color)
	CustomizationManager.update_color(CharacterData.CharacterPart.Bottom, 'accent', color_picker_button_bottom_accent.color)
	CustomizationManager.update_color(CharacterData.CharacterPart.Bottom, 'detail', color_picker_button_bottom_detail.color)


func _on_option_button_shoes_style_item_selected(index: int) -> void:
	CustomizationManager.update_mesh(CharacterData.CharacterPart.Shoes, index)
	CustomizationManager.update_color(CharacterData.CharacterPart.Shoes, 'base', color_picker_button_shoes_base.color)
	CustomizationManager.update_color(CharacterData.CharacterPart.Shoes, 'accent', color_picker_button_shoes_accent.color)
	CustomizationManager.update_color(CharacterData.CharacterPart.Shoes, 'detail', color_picker_button_shoes_detail.color)


func _on_h_slider_size_value_changed(value: float) -> void:
	CustomizationManager.update_float(CharacterData.CharacterPart.Body, 'size', value)
