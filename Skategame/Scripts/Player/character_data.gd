class_name CharacterData 
extends Resource

#@export var top_base_color: Color = Color("5d7937")
#@export var top_accent_color: Color = Color("5d7937")
#@export var top_detail_color: Color = Color("adaca0")
#@export var bottom_base_color: Color = Color("826a4a")
#@export var bottom_accent_color: Color = Color("b7b7b7")
#@export var bottom_detail_color: Color = Color("e9a174")
#@export var shoes_base_color: Color = Color("323232")
#@export var shoes_accent_color: Color = Color("8e7247")
#@export var shoes_detail_color: Color = Color("9e9e9e")
#@export var board_wheels_color: Color = Color(0.758,0.721,0.471,1.0)
#@export var board_accent_color: Color = Color(0.354,0.95,0.45,1.0)
#@export var board_metal_color: Color = Color(0.8,0.8,0.8,1.0)
#@export var hair_color : Color = Color(0.555,0.465,0.351,1.0)
#@export var skin_color : float = 0.25
#@export var eye_color : Color = Color(0.356,0.425,0.583,1.0)
#@export var size : float = 1.0
#@export var board_decal : int = 1
#@export var top_decal : int = 0
#@export var hair_mesh : int = 1
#@export var top_mesh : int = 1
#@export var bottom_mesh : int = 1
#@export var shoes_mesh : int = 1
#@export var helmet_mesh : int = 0
#@export var glasses_mesh : int = 0
#@export var gender : float = 0
@export var customization_data = {
	CustomizationPart.Part.BODY : {"gender" : 0.0,
									"size" :  1.0,
									"color" : 0.5,
									"eyes": Color(0.356,0.425,0.583,1.0)
	},
	CustomizationPart.Part.TOP : {	"mesh" : 1,
									"base":  Color("5d7937"),
									"accent": Color("5d7937"),
									"detail": Color("adaca0"),
									CustomizationPart.Part.DECAL_TOP : 0
								},
	CustomizationPart.Part.BOTTOM : { "mesh" : 1,
									"base": Color("826a4a"),
									"accent" : Color("b7b7b7"),
									"detail" : Color("e9a174")
									},
	CustomizationPart.Part.SHOES : { "mesh" : 1,
									"base" : Color("323232"),
									"accent" : Color("8e7247"),
									"detail" : Color("9e9e9e")
									},
	CustomizationPart.Part.BOARD : {#"mesh": 0, add adjustable board meshes later
									"base" :Color(0.758,0.721,0.471,1.0),
									"accent": Color(0.354,0.95,0.45,1.0),
									"detail": Color(0.8,0.8,0.8,1.0),
									CustomizationPart.Part.DECAL_BOARD : 1
									},
	CustomizationPart.Part.HAIR : {"mesh": 1,
									"base" : Color(0.555,0.465,0.351,1.0)
									},
	CustomizationPart.Part.HELMET : {"mesh" : 0},
	CustomizationPart.Part.GLASSES : {"mesh" : 0}
}
