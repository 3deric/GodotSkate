extends Node3D

signal color_updated(part: CharacterData.CharacterPart, sub: String, color: Color)
signal decal_updated(part: CharacterData.CharacterPart, index: int)
signal mesh_updated(part: CharacterData.CharacterPart, index: int)
signal float_updated(part: CharacterData.CharacterPart, sub: String, value: float)
signal customization_updated()

var character_data : CharacterData

var board_decals = [
	preload ("res://Assets/Characters/Textures/T_decal_empty.png"),
	preload ("res://Assets/Characters/Textures/T_skateboard_deck.png"),
	preload ("res://Assets/Characters/Textures/T_skateboard_deck_cat.png")
]

var top_decals = [
	preload ("res://Assets/Characters/Textures/T_decal_empty.png"),
	preload ("res://Assets/Characters/Textures/T_decal_captain_bavaria.png"),
	preload ("res://Assets/Characters/Textures/T_decal_test.png")
]

var hair_meshes_male = [
	preload ("res://Assets/Characters/Meshes/SK_male_hair_short.res")
]

var top_meshes_male = [
	preload ("res://Assets/Characters/Meshes/SK_male_hoodie.res")
]

var bottom_meshes_male = [
	preload("res://Assets/Characters/Meshes/SK_male_jeans.res")
]

var shoe_meshes_male = [
	preload("res://Assets/Characters/Meshes/SK_male_sneakers.res")
]

func _ready() -> void:
	character_data = CharacterData.new()


func reset_character() -> void:
	character_data = CharacterData.new()
	customization_updated.emit()


func update_color(part: CharacterData.CharacterPart,sub: String, color: Color ) -> void:
	match part:
		CharacterData.CharacterPart.Body:
			match sub: 
				'eyes':
					character_data.eye_color = color
		CharacterData.CharacterPart.Hair:
			match sub:
				'color':
					character_data.hair_color = color
		CharacterData.CharacterPart.Top:
			match sub:
				'base':
					character_data.top_base_color = color
				'accent':
					character_data.top_accent_color = color
				'detail':
					character_data.top_detail_color = color
		CharacterData.CharacterPart.Bottom:
			match sub:
				'base':
					character_data.bottom_base_color = color
				'accent':
					character_data.bottom_accent_color = color
				'detail':
					character_data.bottom_detail_color = color
		CharacterData.CharacterPart.Shoes:
			match sub:
				'base':
					character_data.shoes_base_color = color
				'accent':
					character_data.shoes_accent_color = color
				'detail':
					character_data.shoes_detail_color = color
		CharacterData.CharacterPart.Board:
			match sub:
				'wheels':
					character_data.board_wheels_color = color
				'accent':
					character_data.board_accent_color = color
				'metal':
					character_data.board_metal_color= color

	color_updated.emit(part, sub, color)
	#customization_updated.emit()
	

func update_mesh(part: CharacterData.CharacterPart, index: int) -> void:
	match part:
		CharacterData.CharacterPart.Hair:
			character_data.hair_mesh = index
		CharacterData.CharacterPart.Top:
			character_data.top_mesh = index
		CharacterData.CharacterPart.Bottom:
			character_data.bottom_mesh = index
		CharacterData.CharacterPart.Shoes:
			character_data.shoes_mesh = index
	mesh_updated.emit(part, index)
	#customization_updated.emit()
	

func update_decal(part: CharacterData.CharacterPart, index: int) -> void:
	match part:
		CharacterData.CharacterPart.Top:
			character_data.top_decal = index
		CharacterData.CharacterPart.Board:
			character_data.board_decal = index
	decal_updated.emit(part, index)
	#customization_updated.emit()


func update_float(part: CharacterData.CharacterPart, sub : String ,value: float) -> void:
	match part:
		CharacterData.CharacterPart.Body:
			match sub:
				'size':
					character_data.size = value
				'skin_color':
					character_data.skin_color = value
	float_updated.emit(part, sub, value)
	#customization_updated.emit()
		
