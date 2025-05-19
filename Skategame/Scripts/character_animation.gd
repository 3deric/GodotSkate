extends Node3D

#controls the animtree of the character_controller
@onready var anim_tree: AnimationTree = $"../AnimationTree"
@onready var character_controller: CharacterBody3D = $".."
@onready var Char : Node3D = $"../Char/SK_char_male"


var anim_blend : Vector3 = Vector3.ZERO #blendvector for animations
var ANIM_INTERP_SPEED : float = 5.0 #interpolation speed between anim states
var INTERP_SPEED : float = 10.0 #interpolation speed of the visual character


func _ready() -> void:
	if !character_controller.is_playing:
		anim_tree.set('parameters/conditions/is_setup', true)
	else:
		Char.top_level = true


func _process(delta: float) -> void:
	_animation_handler(delta)
	_lerp_vis_transform(delta, INTERP_SPEED)
	if character_controller.player_state == character_controller.PlayerState.GRIND:
		Char.rotation.z = -character_controller.balance_angle * 0.5
	if character_controller.player_state == character_controller.PlayerState.LIP:
		Char.rotation.x = -character_controller.balance_angle * 0.5	


func _lerp_vis_transform(_delta, _speed):
	Char.global_transform = Char.global_transform.interpolate_with(character_controller.global_transform, _delta * _speed)
	if character_controller.player_state != character_controller.PlayerState.GRIND:
		#interpolate player location only while grinding to achieve a smooth motion
		Char.global_position = character_controller.global_position


func _animation_handler(delta):
	anim_blend = anim_blend.lerp(character_controller.input, delta * ANIM_INTERP_SPEED)
	match character_controller.player_state:
		character_controller.PlayerState.FALL:
			return
		character_controller.PlayerState.GROUND, character_controller.PlayerState.PIPE:	
			anim_tree.set('parameters/conditions/is_stopped', true)
			anim_tree.set('parameters/conditions/is_air',false)
			anim_tree.set('parameters/conditions/is_grind', false)
			anim_tree.set('parameters/conditions/is_lip', false)
			if character_controller.velocity.length() > 0.25:
				anim_tree.set('parameters/conditions/is_riding', true)
				anim_tree.set('parameters/conditions/is_stopped', false)
			else:
				anim_tree.set('parameters/conditions/is_riding', false)
				anim_tree.set('parameters/conditions/is_stopped', true)
			anim_tree.set('parameters/Ground/blend_position', anim_blend)
		character_controller.PlayerState.AIR, character_controller.PlayerState.PIPESNAP, character_controller.PlayerState.PIPESNAPAIR:
			anim_tree.set('parameters/conditions/is_riding', false)
			anim_tree.set('parameters/conditions/is_stopped', false)
			anim_tree.set('parameters/conditions/is_air', true)
			anim_tree.set('parameters/conditions/is_grind', false)
			anim_tree.set('parameters/conditions/is_lip', false)
			anim_tree.set('parameters/Air/blend_position', anim_blend)
		character_controller.PlayerState.GRIND:
			anim_tree.set('parameters/conditions/is_riding', false)
			anim_tree.set('parameters/conditions/is_stopped', false)
			anim_tree.set('parameters/conditions/is_air', false)
			anim_tree.set('parameters/conditions/is_grind', true)
			anim_tree.set('parameters/conditions/is_lip', false)
			anim_tree.set('parameters/Grind/blend_position', anim_blend)
		character_controller.PlayerState.LIP:
			anim_tree.set('parameters/conditions/is_riding', false)
			anim_tree.set('parameters/conditions/is_stopped', false)
			anim_tree.set('parameters/conditions/is_air', false)
			anim_tree.set('parameters/conditions/is_grind', false)
			anim_tree.set('parameters/conditions/is_lip', true)
			anim_tree.set('parameters/Lip/blend_position', anim_blend)
