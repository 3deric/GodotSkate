extends Node3D

signal color_updated(part: CharacterData.CharacterPart, color: Color)
signal customization_updated

var character_data : CharacterData


func _ready() -> void:
	character_data = CharacterData.new()


func update_color(part: CharacterData.CharacterPart,sub: String, color: Color ) -> void:
	match part:
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
	customization_updated.emit()


func reset_character() -> void:
	character_data = CharacterData.new()
	customization_updated.emit()


func update_part(part: CharacterData.CharacterPart, index: int) -> void:
	#match part:
	#	CharacterData.CharacterPart.Top:
	#		character_data.selected_top = index
	#customization_updated.emit()
	#change meshes of the character
	pass
