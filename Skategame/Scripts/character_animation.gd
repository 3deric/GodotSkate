extends Node3D

#controls the animtree of the character
@onready var anim_tree: AnimationTree = $"../../AnimationTree"
@onready var character: CharacterBody3D = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
		#Anim.set('parameters/conditions/is_setup', true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
