class_name CustomizationMenu
extends Control

@onready var h_slider_skin_color: HSlider = %HSlider_Skin_Color
@onready var color_picker_button_eye_color: ColorPickerButton = %ColorPickerButton_Eye_Color
@onready var color_picker_button_top_base: ColorPickerButton = %ColorPickerButton_Top_Base
@onready var color_picker_button_top_accent: ColorPickerButton = %ColorPickerButton_Top_Accent
@onready var color_picker_button_top_detail: ColorPickerButton = %ColorPickerButton_Top_Detail
@onready var color_picker_button_bottom_base: ColorPickerButton = %ColorPickerButton_Bottom_Base
@onready var color_picker_button_bottom_accent: ColorPickerButton = %ColorPickerButton_Bottom_Accent
@onready var color_picker_button_bottom_detail: ColorPickerButton = %ColorPickerButton_Bottom_Detail
@onready var color_picker_button_shoes_base: ColorPickerButton = %ColorPickerButton_Shoes_Base
@onready var color_picker_button_shoes_accent: ColorPickerButton = %ColorPickerButton_Shoes_Accent
@onready var color_picker_button_shoes_detail: ColorPickerButton = %ColorPickerButton_Shoes_Detail
@onready var color_picker_button_wheels: ColorPickerButton = %ColorPickerButton_Wheels
@onready var color_picker_button_details: ColorPickerButton = %ColorPickerButton_Details
@onready var color_picker_button_metal: ColorPickerButton = %ColorPickerButton_Metal
@onready var option_button_deck: OptionButton = %OptionButton_Deck
@onready var option_button_top_decal: OptionButton = %OptionButton_Top_Decal
@onready var color_picker_button_hair_color: ColorPickerButton = %ColorPickerButton_Hair_Color
@onready var option_button_hair: OptionButton = %OptionButton_Hair
@onready var option_button_top_style: OptionButton = %OptionButton_Top_Style
@onready var option_button_bottom_style: OptionButton = %OptionButton_Bottom_Style
@onready var option_button_shoes_style: OptionButton = %OptionButton_Shoes_Style
@onready var h_slider_size: HSlider = %HSlider_Size
@onready var check_button_gender: CheckButton = %CheckButton_Gender
@onready var option_button_helmet_style : OptionButton = %OptionButton_Helmet_Style
@onready var option_button_glasses_style : OptionButton = %OptionButton_Glasses_Style

func _ready() -> void:
	_setup_buttons()
	_setup_options()
	CustomizationManager.instance.customization_updated.connect(_update_ui_from_data)


func _setup_buttons() -> void:
	h_slider_size.value_changed.connect(_on_h_slider_size_value_changed)
	h_slider_skin_color.value_changed.connect(_on_h_slider_skin_color_value_changed)
	color_picker_button_eye_color.color_changed.connect(_on_color_picker_button_eye_color_color_changed)
	option_button_hair.item_selected.connect(_on_option_button_hair_item_selected)
	color_picker_button_hair_color.color_changed.connect(_on_color_picker_button_hair_color_color_changed)
	option_button_top_style.item_selected.connect(_on_option_button_top_style_item_selected)
	option_button_top_decal.item_selected.connect(_on_option_button_top_decal_item_selected)
	color_picker_button_top_base.color_changed.connect(_on_color_picker_button_top_base_color_changed)
	color_picker_button_top_accent.color_changed.connect(_on_color_picker_button_top_accent_color_changed)
	color_picker_button_top_detail.color_changed.connect(_on_color_picker_button_top_detail_color_changed)
	option_button_bottom_style.item_selected.connect(_on_option_button_bottom_style_item_selected)
	color_picker_button_bottom_base.color_changed.connect(_on_color_picker_button_bottom_base_color_changed)
	color_picker_button_bottom_accent.color_changed.connect(_on_color_picker_button_bottom_accent_color_changed)
	color_picker_button_bottom_detail.color_changed.connect(_on_color_picker_button_bottom_detail_color_changed)
	option_button_shoes_style.item_selected.connect(_on_option_button_shoes_style_item_selected)
	color_picker_button_shoes_base.color_changed.connect(_on_color_picker_button_shoes_base_color_changed)
	color_picker_button_shoes_accent.color_changed.connect(_on_color_picker_button_shoes_accent_color_changed)
	color_picker_button_shoes_detail.color_changed.connect(_on_color_picker_button_shoes_detail_color_changed)
	option_button_deck.item_selected.connect(_on_option_button_deck_item_selected)
	color_picker_button_wheels.color_changed.connect(_on_color_picker_button_wheels_color_changed)
	color_picker_button_metal.color_changed.connect(_on_color_picker_button_metal_color_changed)
	color_picker_button_details.color_changed.connect(_on_color_picker_button_details_color_changed)
	check_button_gender.toggled.connect(_on_check_button_gender_toggled)
	option_button_helmet_style.item_selected.connect(_on_option_button_helmet_style_item_selected)
	option_button_glasses_style.item_selected.connect(_on_option_button_glasses_style_item_selected)


func _setup_options() -> void:
	_set_option_button(option_button_top_style, CustomizationPart.Part.TOP)
	_set_option_button(option_button_bottom_style, CustomizationPart.Part.BOTTOM)
	_set_option_button(option_button_shoes_style, CustomizationPart.Part.SHOES)
	_set_option_button(option_button_helmet_style, CustomizationPart.Part.HELMET)
	_set_option_button(option_button_glasses_style, CustomizationPart.Part.GLASSES)
	_set_option_button(option_button_hair, CustomizationPart.Part.HAIR)
	_set_option_button(option_button_top_decal, CustomizationPart.Part.DECAL_TOP)
	_set_option_button(option_button_deck, CustomizationPart.Part.DECAL_BOARD)
	
	_update_ui_from_data()
	
func _update_ui_from_data() -> void:
	var data = CustomizationManager.instance.character_data
	color_picker_button_top_base.color = data.customization_data[CustomizationPart.Part.TOP]["base"]
	color_picker_button_top_accent.color = data.customization_data[CustomizationPart.Part.TOP]["accent"]
	color_picker_button_top_detail.color = data.customization_data[CustomizationPart.Part.TOP]["detail"]
	color_picker_button_bottom_base.color = data.customization_data[CustomizationPart.Part.BOTTOM]["base"]
	color_picker_button_bottom_accent.color = data.customization_data[CustomizationPart.Part.BOTTOM]["accent"]
	color_picker_button_bottom_detail.color = data.customization_data[CustomizationPart.Part.BOTTOM]["detail"]
	color_picker_button_shoes_base.color = data.customization_data[CustomizationPart.Part.SHOES]["base"]
	color_picker_button_shoes_accent.color = data.customization_data[CustomizationPart.Part.SHOES]["accent"]
	color_picker_button_shoes_detail.color = data.customization_data[CustomizationPart.Part.SHOES]["detail"]
	color_picker_button_wheels.color = data.customization_data[CustomizationPart.Part.BOARD]["base"]
	color_picker_button_details.color = data.customization_data[CustomizationPart.Part.BOARD]["accent"]
	color_picker_button_metal.color = data.customization_data[CustomizationPart.Part.BOARD]["detail"]
	option_button_deck.selected = data.customization_data[CustomizationPart.Part.BOARD][CustomizationPart.Part.DECAL_BOARD]
	option_button_top_decal.selected = data.customization_data[CustomizationPart.Part.TOP][CustomizationPart.Part.DECAL_TOP]
	color_picker_button_eye_color.color = data.customization_data[CustomizationPart.Part.BODY]["eyes"]
	h_slider_skin_color.value = data.customization_data[CustomizationPart.Part.BODY]["color"]
	color_picker_button_hair_color.color = data.customization_data[CustomizationPart.Part.HAIR]["base"]
	option_button_hair.selected = data.customization_data[CustomizationPart.Part.HAIR]["mesh"]
	option_button_top_style.selected = data.customization_data[CustomizationPart.Part.TOP]["mesh"]
	option_button_bottom_style.selected = data.customization_data[CustomizationPart.Part.BOTTOM]["mesh"]
	option_button_shoes_style.selected = data.customization_data[CustomizationPart.Part.SHOES]["mesh"]
	h_slider_size.value = data.customization_data[CustomizationPart.Part.BODY]["size"]
	check_button_gender.button_pressed = bool(data.customization_data[CustomizationPart.Part.BODY]["gender"])
	option_button_helmet_style.selected = data.customization_data[CustomizationPart.Part.HELMET]["mesh"]
	option_button_glasses_style.selected = data.customization_data[CustomizationPart.Part.GLASSES]["mesh"]	

func _on_color_picker_button_top_base_color_changed(color: Color) -> void:
	CustomizationManager.instance.update_color(CustomizationPart.Part.TOP, 'base', color)


func _on_color_picker_button_top_accent_color_changed(color: Color) -> void:
	CustomizationManager.instance.update_color(CustomizationPart.Part.TOP, 'accent', color)


func _on_color_picker_button_top_detail_color_changed(color: Color) -> void:
	CustomizationManager.instance.update_color(CustomizationPart.Part.TOP, 'detail', color)


func _on_color_picker_button_bottom_base_color_changed(color: Color) -> void:
	CustomizationManager.instance.update_color(CustomizationPart.Part.BOTTOM, 'base', color)
		

func _on_color_picker_button_bottom_accent_color_changed(color: Color) -> void:
	CustomizationManager.instance.update_color(CustomizationPart.Part.BOTTOM, 'accent', color)


func _on_color_picker_button_bottom_detail_color_changed(color: Color) -> void:
	CustomizationManager.instance.update_color(CustomizationPart.Part.BOTTOM, 'detail', color)


func _on_color_picker_button_shoes_base_color_changed(color: Color) -> void:
	CustomizationManager.instance.update_color(CustomizationPart.Part.SHOES, 'base', color)


func _on_color_picker_button_shoes_accent_color_changed(color: Color) -> void:
	CustomizationManager.instance.update_color(CustomizationPart.Part.SHOES, 'accent', color)
	

func _on_color_picker_button_shoes_detail_color_changed(color: Color) -> void:
	CustomizationManager.instance.update_color(CustomizationPart.Part.SHOES, 'detail', color)


func _on_color_picker_button_wheels_color_changed(color: Color) -> void:
	CustomizationManager.instance.update_color(CustomizationPart.Part.BOARD, 'wheels', color)


func _on_color_picker_button_details_color_changed(color: Color) -> void:
	CustomizationManager.instance.update_color(CustomizationPart.Part.BOARD, 'accent', color)


func _on_color_picker_button_metal_color_changed(color: Color) -> void:
	CustomizationManager.instance.update_color(CustomizationPart.Part.BOARD, 'metal', color)


func _on_option_button_deck_item_selected(index: int) -> void:
	CustomizationManager.instance.update_decal(CustomizationPart.Part.BOARD, CustomizationPart.Part.DECAL_BOARD, index)


func _on_option_button_top_decal_item_selected(index: int) -> void:
	CustomizationManager.instance.update_decal(CustomizationPart.Part.TOP, CustomizationPart.Part.DECAL_TOP, index)


func _on_h_slider_skin_color_value_changed(value: float) -> void:
	CustomizationManager.instance.update_float(CustomizationPart.Part.BODY, 'color', value)


func _on_color_picker_button_eye_color_color_changed(color: Color) -> void:
	CustomizationManager.instance.update_color(CustomizationPart.Part.BODY, 'eyes', color)


func _on_color_picker_button_hair_color_color_changed(color: Color) -> void:
	CustomizationManager.instance.update_color(CustomizationPart.Part.HAIR, 'base', color)


func _on_option_button_hair_item_selected(index: int) -> void:
	CustomizationManager.instance.update_mesh(CustomizationPart.Part.HAIR, index)
	CustomizationManager.instance.update_color(CustomizationPart.Part.HAIR, 'color', color_picker_button_hair_color.color)


func _on_option_button_top_style_item_selected(index: int) -> void:
	CustomizationManager.instance.update_mesh(CustomizationPart.Part.TOP, index)
	CustomizationManager.instance.update_color(CustomizationPart.Part.TOP, 'base', color_picker_button_top_base.color)
	CustomizationManager.instance.update_color(CustomizationPart.Part.TOP, 'accent', color_picker_button_top_accent.color)
	CustomizationManager.instance.update_color(CustomizationPart.Part.TOP, 'detail', color_picker_button_top_detail.color)
	CustomizationManager.instance.update_decal(CustomizationPart.Part.TOP, CustomizationPart.Part.DECAL_TOP,option_button_top_decal.selected)
	CustomizationManager.instance.update_float(CustomizationPart.Part.BOTTOM, 'gender', float(check_button_gender.button_pressed))


func _on_option_button_bottom_style_item_selected(index: int) -> void:
	CustomizationManager.instance.update_mesh(CustomizationPart.Part.BOTTOM, index)
	CustomizationManager.instance.update_color(CustomizationPart.Part.BOTTOM, 'base', color_picker_button_bottom_base.color)
	CustomizationManager.instance.update_color(CustomizationPart.Part.BOTTOM, 'accent', color_picker_button_bottom_accent.color)
	CustomizationManager.instance.update_color(CustomizationPart.Part.BOTTOM, 'detail', color_picker_button_bottom_detail.color)
	CustomizationManager.instance.update_float(CustomizationPart.Part.BOTTOM, 'gender', float(check_button_gender.button_pressed))


func _on_option_button_shoes_style_item_selected(index: int) -> void:
	CustomizationManager.instance.update_mesh(CustomizationPart.Part.SHOES, index)
	CustomizationManager.instance.update_color(CustomizationPart.Part.SHOES, 'base', color_picker_button_shoes_base.color)
	CustomizationManager.instance.update_color(CustomizationPart.Part.SHOES, 'accent', color_picker_button_shoes_accent.color)
	CustomizationManager.instance.update_color(CustomizationPart.Part.SHOES, 'detail', color_picker_button_shoes_detail.color)

func _on_option_button_helmet_style_item_selected(index: int) -> void:
	CustomizationManager.instance.update_mesh(CustomizationPart.Part.HELMET, index)

func _on_option_button_glasses_style_item_selected(index: int) -> void:
	CustomizationManager.instance.update_mesh(CustomizationPart.Part.GLASSES, index)
	
func _on_h_slider_size_value_changed(value: float) -> void:
	CustomizationManager.instance.update_float(CustomizationPart.Part.BODY, 'size', value)


func _on_check_button_gender_toggled(toggled_on: bool) -> void:
	CustomizationManager.instance.update_float(CustomizationPart.Part.BODY, 'gender', float(toggled_on))

func _set_option_button(_button : OptionButton, _part : CustomizationPart.Part) -> void:
	_button.clear()
	if !CustomizationManager.instance.resources.has(_part):
		return
	for res in CustomizationManager.instance.resources[_part]:
		_button.add_item(res.display_name)
