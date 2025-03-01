class_name CharacterData extends Resource

enum CharacterPart {Top, Bottom, Shoes, Board}
enum BoardDecal {Bare = 0, Style1 = 1, Style2 = 2}
enum TopDecal {Bare = 0, Style1 = 1, Style2 = 2}

@export var top_base_color: Color = Color(0.199,0.322,0.534,1.0)
@export var top_accent_color: Color = Color(0.199,0.322,0.534,1.0)
@export var top_detail_color: Color = Color(0.8,0.8,0.8,1.0)
@export var bottom_base_color: Color = Color(0.281,0.281,0.281,1.0)
@export var bottom_accent_color: Color = Color(0.509,0.509,0.509,1.0)
@export var bottom_detail_color: Color = Color(0.676,0.422,0.201,1.0)
@export var shoes_base_color: Color = Color(0.18,0.18,0.18,1.0)
@export var shoes_accent_color: Color = Color(0.557,0.447,0.278,1.0)
@export var shoes_detail_color: Color = Color(0.8,0.8,0.8,1.0)
@export var board_wheels_color: Color = Color(0.758,0.721,0.471,1.0)
@export var board_accent_color: Color = Color(0.354,0.95,0.45,1.0)
@export var board_metal_color: Color = Color(0.8,0.8,0.8,1.0)
@export var board_decal : int = 0
@export var top_decal : int = 0
