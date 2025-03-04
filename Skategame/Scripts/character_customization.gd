extends Node3D

@onready var body_mesh : MeshInstance3D = get_node('../SK_char_male/Skeleton3D/char_male_body')
@onready var top_mesh : MeshInstance3D = get_node('../SK_char_male/Skeleton3D/char_male_top')
@onready var bottom_mesh : MeshInstance3D = get_node('../SK_char_male/Skeleton3D/char_male_bottom')
@onready var shoes_mesh : MeshInstance3D = get_node('../SK_char_male/Skeleton3D/char_male_shoes')
@onready var board_mesh : MeshInstance3D = get_node('../SK_char_male/Skeleton3D/char_skateboard')
@onready var hair_mesh : MeshInstance3D = get_node('../SK_char_male/Skeleton3D/char_male_hair')


func _ready() -> void:
	_init()
	_connect_signals()
	_update_from_data()

	
func _init() -> void:
	pass


func _connect_signals() -> void:
	if not CustomizationManager.color_updated.is_connected(_on_color_updated):
		CustomizationManager.color_updated.connect(_on_color_updated)
	if not CustomizationManager.decal_updated.is_connected(_on_decal_updated):
		CustomizationManager.decal_updated.connect(_on_decal_updated)
	if not CustomizationManager.customization_updated.is_connected(_on_customization_updated):
		CustomizationManager.customization_updated.connect(_on_customization_updated)
	if not CustomizationManager.mesh_updated.is_connected(_on_mesh_updated):
		CustomizationManager.mesh_updated.connect(_on_mesh_updated)

func _on_color_updated(part: CharacterData.CharacterPart, sub: String, color :Color) -> void:
	match part:
		CharacterData.CharacterPart.Body:
			match sub:
				'eyes':
					_update_body_eyes_color(color)
				'skin':
					_update_body_skin_color(color)
		CharacterData.CharacterPart.Hair:
			match sub:
				'color':
					_update_hair_color(color)
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


func _on_mesh_updated(part: CharacterData.CharacterPart, index : int) -> void:
	match part:
		CharacterData.CharacterPart.Hair:
			_update_hair_mesh(index)
		CharacterData.CharacterPart.Top:
			_update_top_mesh(index)
		CharacterData.CharacterPart.Bottom:
			_update_bottom_mesh(index)
		CharacterData.CharacterPart.Shoes:
			_update_shoes_mesh(index)


func _on_decal_updated(part: CharacterData.CharacterPart, index :int) -> void:
	match part:
		CharacterData.CharacterPart.Top:
			_update_top_decal(index)
		CharacterData.CharacterPart.Board:
			_update_board_decal(index)


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
	_update_board_decal(data.board_decal)
	_update_top_decal(data.top_decal)
	_update_hair_color(data.hair_color)
	_update_body_skin_color(data.skin_color)
	_update_body_eyes_color(data.eye_color)
	_update_hair_mesh(data.hair_mesh)
	_update_top_mesh(data.top_mesh)
	_update_bottom_mesh(data.bottom_mesh)
	_update_shoes_mesh(data.shoes_mesh)
	
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


func _update_board_decal(index: int) -> void:
	board_mesh.get_active_material(0).set_shader_parameter('decal', CustomizationManager.board_decals[index])


func _update_top_decal(index: int) -> void:
	top_mesh.get_active_material(0).set_shader_parameter('decal', CustomizationManager.top_decals[index])


func _update_body_eyes_color(color: Color) -> void:
	body_mesh.get_active_material(0).set_shader_parameter('eyes_color', color)


func _update_body_skin_color(color: Color) -> void:
	body_mesh.get_active_material(0).set_shader_parameter('skin_color', color.r)


func _update_hair_color(color: Color) -> void:
	hair_mesh.get_active_material(0).set_shader_parameter('hair_color', color)
	
func _update_hair_mesh(index :int) -> void:
	if index == 0:
		hair_mesh.hide()
	else:
		hair_mesh.show()
		hair_mesh.mesh = CustomizationManager.hair_meshes_male[index -1]
		
func _update_top_mesh(index :int) -> void:
	if index == 0:
		top_mesh.hide()
	else:
		top_mesh.show()
		top_mesh.mesh = CustomizationManager.top_meshes_male[index -1]
		
func _update_bottom_mesh(index :int) -> void:
	if index == 0:
		bottom_mesh.hide()
	else:
		bottom_mesh.show()
		bottom_mesh.mesh = CustomizationManager.bottom_meshes_male[index -1]
		
func _update_shoes_mesh(index :int) -> void:
	if index == 0:
		shoes_mesh.hide()
	else:
		shoes_mesh.show()
		shoes_mesh.mesh = CustomizationManager.shoe_meshes_male[index -1]
