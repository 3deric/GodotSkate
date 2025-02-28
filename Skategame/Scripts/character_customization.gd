extends Node3D

@onready var body_mesh : MeshInstance3D = get_node('../SK_char_male/Skeleton3D/char_male_body')
@onready var top_mesh : MeshInstance3D = get_node('../SK_char_male/Skeleton3D/char_male_top')
@onready var bottom_mesh : MeshInstance3D = get_node('../SK_char_male/Skeleton3D/char_male_bottom')
@onready var shoes_mesh : MeshInstance3D = get_node('../SK_char_male/Skeleton3D/char_male_shoes')
@onready var board_mesh : MeshInstance3D = get_node('../SK_char_male/Skeleton3D/char_skateboard')


func _ready() -> void:
	_init()
	_connect_signals()
	_update_from_data()

	
func _init() -> void:
	pass


func _connect_signals() -> void:
	if not CustomizationManager.color_updated.is_connected(_on_color_updated):
		CustomizationManager.color_updated.connect(_on_color_updated)
	if not CustomizationManager.customization_updated.is_connected(_on_customization_updated):
		CustomizationManager.customization_updated.connect(_on_customization_updated)
	

func _on_color_updated(part: CharacterData.CharacterPart, sub: String, color :Color) -> void:
	match part:
		CharacterData.CharacterPart.Top:
			match sub:
				'base':
					_update_top_base_color(color)
				'accent':
					_update_top_accent_color(color)
				'detail':
					_update_top_detail_color(color)
		CharacterData.CharacterPart.Bottom:
			match sub:
				'base':
					_update_bottom_base_color(color)
				'accent':
					_update_bottom_accent_color(color)
				'detail':
					_update_bottom_detail_color(color)
		CharacterData.CharacterPart.Shoes:
			match sub:
				'base':
					_update_shoes_base_color(color)
				'accent':
					_update_shoes_accent_color(color)
				'detail':
					_update_shoes_detail_color(color)
		CharacterData.CharacterPart.Board:
			match sub:
				'wheels':
					_update_board_wheels_color(color)
				'accent':
					_update_board_accent_color(color)
				'metal':
					_update_board_metal_color(color)

func _on_customization_updated() ->void:
	_update_from_data()

	
func _update_from_data() -> void:
	var data = CustomizationManager.character_data
	_update_top_base_color(data.top_base_color)
	_update_top_accent_color(data.top_accent_color)
	_update_top_detail_color(data.top_detail_color)
	_update_bottom_base_color(data.bottom_base_color)
	_update_bottom_accent_color(data.bottom_accent_color)
	_update_bottom_detail_color(data.bottom_detail_color)
	_update_shoes_base_color(data.shoes_base_color)
	_update_shoes_accent_color(data.shoes_accent_color)
	_update_shoes_detail_color(data.shoes_detail_color)
	_update_board_wheels_color(data.board_wheels_color)
	_update_board_accent_color(data.board_accent_color)
	_update_board_metal_color(data.board_metal_color)
	

#Top

func _update_top_base_color(color: Color) -> void:
	top_mesh.get_active_material(0).set_shader_parameter('base_color', color)
	
	
func _update_top_accent_color(color: Color) -> void:
	top_mesh.get_active_material(0).set_shader_parameter('accent_color', color)
	

func _update_top_detail_color(color: Color) -> void:
	top_mesh.get_active_material(0).set_shader_parameter('detail_color', color)
	
#Bottom

func _update_bottom_base_color(color: Color) -> void:
	bottom_mesh.get_active_material(0).set_shader_parameter('base_color', color)
	
	
func _update_bottom_accent_color(color: Color) -> void:
	bottom_mesh.get_active_material(0).set_shader_parameter('accent_color', color)
	

func _update_bottom_detail_color(color: Color) -> void:
	bottom_mesh.get_active_material(0).set_shader_parameter('detail_color', color)
	

#Shoes

func _update_shoes_base_color(color: Color) -> void:
	shoes_mesh.get_active_material(0).set_shader_parameter('base_color', color)
	
	
func _update_shoes_accent_color(color: Color) -> void:
	shoes_mesh.get_active_material(0).set_shader_parameter('accent_color', color)
	

func _update_shoes_detail_color(color: Color) -> void:
	shoes_mesh.get_active_material(0).set_shader_parameter('detail_color', color)
	
	
func _update_board_wheels_color(color: Color) -> void:
	board_mesh.get_active_material(0).set_shader_parameter('wheels_color', color)


func _update_board_accent_color(color: Color) -> void:
	board_mesh.get_active_material(0).set_shader_parameter('accent_color', color)


func _update_board_metal_color(color: Color) -> void:
	board_mesh.get_active_material(0).set_shader_parameter('metal_color', color)
