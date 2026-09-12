class_name CustomizationManager
extends Node

static var instance: CustomizationManager

signal color_updated(part: CustomizationPart.Part, sub: String, color: Color)
signal decal_updated(part: CustomizationPart.Part, index: int)
signal mesh_updated(part: CustomizationPart.Part, index: int)
signal float_updated(part: CustomizationPart.Part, sub: String, value: float)
signal customization_updated()

#var resources : Array[CustomizationAsset] = []
var resources : Dictionary = {}

var character_data : CharacterData

func _ready() -> void:
	instance = self
	_preload_customization_assets()
	character_data = CharacterData.new()


func reset_character() -> void:
	character_data = CharacterData.new()
	customization_updated.emit()


func update_color(part: CustomizationPart.Part,sub: String, color: Color ) -> void:
	character_data.customization_data[part][sub] = color
	color_updated.emit(part, sub, color)
	#customization_updated.emit()
	

func update_mesh(part: CustomizationPart.Part, index: int) -> void:
	character_data.customization_data[part]["mesh"] = index
	mesh_updated.emit(part, index)
	#customization_updated.emit()
	

func update_decal(part: CustomizationPart.Part, decal_part : CustomizationPart.Part, index: int) -> void:
	character_data.customization_data[part]["decal"] = index
	decal_updated.emit(part, decal_part, index)
	#customization_updated.emit()


func update_float(part: CustomizationPart.Part, sub : String ,value: float) -> void:
	character_data.customization_data[part][sub] = value
	float_updated.emit(part, sub, value)
	#customization_updated.emit()
		
func _preload_customization_assets() -> void:
	var dir = DirAccess.open("res://Assets/Characters/Customization")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource : CustomizationAsset = load("res://Assets/Characters/Customization/" + file_name) as CustomizationAsset
			if resource:
				if not resources.has(resource.part):
					resources[resource.part] = []
				resources[resource.part].append(resource)
		file_name = dir.get_next()
	dir.list_dir_end()
	for key in resources:
		resources[key].sort_custom(func(a, b):
			return a.resource_path.get_file().to_lower() < b.resource_path.get_file().to_lower()
)
