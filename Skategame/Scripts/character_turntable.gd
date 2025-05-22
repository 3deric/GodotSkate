extends Node3D

@onready var character: CharacterBody3D = $"../Character"

#global movement constants
const ROT :float= 2.0

#input variables
var input : Vector3 = Vector3.ZERO #input values

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_input_handler()
	_rotate(delta)


func _input_handler() -> void: 	#handles player inputs
	input.x = int(Input.is_action_pressed('Left')) - int(Input.is_action_pressed('Right'))


func _rotate(_delta) -> void:
	character.rotate_y(input.x * ROT * _delta)
