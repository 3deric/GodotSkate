class_name CharacterCustomization
extends Node

@onready var char_skeleton: Node3D = $"../../Character_Visual/Char_Skeleton"
const BODY_MALE : Material = preload("res://Assets/Characters/Materials/M_char_male_body_colorable.tres")
const BODY_FEMALE : Material = preload("res://Assets/Characters/Materials/M_char_female_body_colorable.tres")

@onready var character_meshes : Dictionary = {
	CustomizationPart.Part.BODY : $"../../Character_Visual/Char_Skeleton/Skeleton3D/char_body",
	CustomizationPart.Part.TOP : $"../../Character_Visual/Char_Skeleton/Skeleton3D/char_top",
	CustomizationPart.Part.BOTTOM : $"../../Character_Visual/Char_Skeleton/Skeleton3D/char_bottom",
	CustomizationPart.Part.SHOES : $"../../Character_Visual/Char_Skeleton/Skeleton3D/char_shoes",
	CustomizationPart.Part.BOARD : $"../../Character_Visual/Char_Skeleton/Skeleton3D/char_board",
	CustomizationPart.Part.HAIR : $"../../Character_Visual/Char_Skeleton/Skeleton3D/char_hair",
	CustomizationPart.Part.HELMET : $"../../Character_Visual/Char_Skeleton/Skeleton3D/char_helmet",
	CustomizationPart.Part.GLASSES : $"../../Character_Visual/Char_Skeleton/Skeleton3D/char_headwear",
}

func _ready() -> void:
	_connect_signals()
	_update_from_data()
	
func _connect_signals() -> void:
	if not CustomizationManager.instance.color_updated.is_connected(_on_color_updated):
		CustomizationManager.instance.color_updated.connect(_on_color_updated)
	if not CustomizationManager.instance.decal_updated.is_connected(_on_decal_updated):
		CustomizationManager.instance.decal_updated.connect(_on_decal_updated)
	if not CustomizationManager.instance.customization_updated.is_connected(_on_customization_updated):
		CustomizationManager.instance.customization_updated.connect(_on_customization_updated)
	if not CustomizationManager.instance.float_updated.is_connected(_on_float_updated):
		CustomizationManager.instance.float_updated.connect(_on_float_updated)
	if not CustomizationManager.instance.mesh_updated.is_connected(_on_mesh_updated):
		CustomizationManager.instance.mesh_updated.connect(_on_mesh_updated)


func _on_color_updated(part: CustomizationPart.Part, sub: String, color :Color) -> void:
	_update_color(character_meshes[part], sub + "_color", color)

func _on_mesh_updated(part: CustomizationPart.Part, index : int) -> void:
	var _mesh = character_meshes[part]
	_mesh.mesh = CustomizationManager.instance.resources[part][index].ressource
	if part != CustomizationPart.Part.SHOES:
		return
	if _mesh.mesh == null:
		character_meshes[CustomizationPart.Part.BODY].set_blend_shape_value(1,0.0)
	else:
		character_meshes[CustomizationPart.Part.BODY].set_blend_shape_value(1,1.0)	

func _on_decal_updated(part: CustomizationPart.Part, decal_part : CustomizationPart.Part, index :int) -> void:
	_update_decal(character_meshes[part], "decal", CustomizationManager.instance.resources[decal_part][index].ressource)

func _on_float_updated(part: CustomizationPart.Part, sub: String, value: float) -> void:
	match part:
		CustomizationPart.Part.BODY:
			match sub:
				'color':
					_update_body_skin_color(value)
				'size':
					char_skeleton.scale = Vector3(value, value, value)
				'gender':
					_update_gender(value)
					_update_top_gender(value)
					_update_bottom_gender(value)
					
func _on_customization_updated() ->void:
	_update_from_data()

func _update_from_data() -> void:
	var data = CustomizationManager.instance.character_data.customization_data
	for part in data:
		for customization in data[part]:
			if typeof(customization) == TYPE_STRING:
				var _type = typeof(data[part][customization])
				if customization == "mesh":
					_on_mesh_updated(part,data[part][customization])
				elif  _type == TYPE_COLOR:
					_on_color_updated(part, customization, data[part][customization])
				elif _type == TYPE_FLOAT:
					_on_float_updated(part, customization, data[part][customization])
			elif typeof(customization) == TYPE_INT:
				_on_decal_updated(part, customization, data[part][customization])

func _update_body_eyes_color(color: Color) -> void:
	_update_color(character_meshes[CustomizationPart.Part.BODY], "eyes_color", color)

func _update_body_skin_color(value: float) -> void:
	_update_float(character_meshes[CustomizationPart.Part.BODY], "skin_color", value)

func _update_gender(value : float) -> void:
	var _mesh = character_meshes[CustomizationPart.Part.BODY]
	_mesh.set_blend_shape_value(0, value)
	if value > 0.5:
		_mesh.set_surface_override_material(0, BODY_FEMALE)
	else:
		_mesh.set_surface_override_material(0, BODY_MALE)

func _update_top_gender(value : float) -> void:
	var _mesh = character_meshes[CustomizationPart.Part.TOP]
	_mesh.set_blend_shape_value(0, value)

func _update_bottom_gender(value : float) -> void:
	var _mesh = character_meshes[CustomizationPart.Part.BOTTOM]
	_mesh.set_blend_shape_value(0, value)
	
func _update_color(_mesh : MeshInstance3D, _param : String, _color : Color) -> void:
	if not _mesh:
		push_error(str(_mesh)  + " is not assigned")
		return
	var material = _mesh.get_active_material(0)
	if not material:
		push_error("No material found on " + str(_mesh))
		return
	if material is ShaderMaterial:
		material.set_shader_parameter(_param, _color)
	else:
		push_error("Unsupported material type: " + str(material.get_class()))

func _update_float(_mesh : MeshInstance3D, _param : String, _value: float) -> void:
	if not _mesh:
		push_error(str(_mesh)  + " is not assigned")
		return
	var material = _mesh.get_active_material(0)
	if not material:
		push_error("No material found on " + str(_mesh))
		return
	if material is ShaderMaterial:
		material.set_shader_parameter(_param, _value)
	else:
		push_error("Unsupported material type: " + str(material.get_class()))
		
func _update_decal(_mesh : MeshInstance3D, _param : String, _decal: CompressedTexture2D) -> void:
	if not _mesh:
		push_error(str(_mesh)  + " is not assigned")
		return
	var material = _mesh.get_active_material(0)
	if not material:
		push_error("No material found on " + str(_mesh))
		return
	if material is ShaderMaterial:
		material.set_shader_parameter(_param, _decal)
	else:
		push_error("Unsupported material type: " + str(material.get_class()))
