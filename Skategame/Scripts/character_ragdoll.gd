extends Node3D

@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $"../Char/Char_Skeleton/Skeleton3D/PhysicalBoneSimulator3D"
@onready var physical_bone_def_hips: PhysicalBone3D = $"../Char/Char_Skeleton/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone DEF-hips"
@onready var physical_bone_def_board_root: PhysicalBone3D = $"../Char/Char_Skeleton/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone DEF-board_root"

var active : bool = false

#func _process(delta: float) -> void:
#	_debug_ragdoll()
		
		
func _debug_ragdoll() -> void:
	if Input.is_action_just_pressed("ui_accept") and !active:
		active = true
		set_start_simulation(Vector3(0,25,0))
	if Input.is_action_just_released("ui_accept") and active:
		active = false
		set_end_simulation()
	

func set_start_simulation(_impulse) -> void:
	print("start ragdoll physics")
	physical_bone_simulator_3d.active = true
	physical_bone_simulator_3d.physical_bones_start_simulation()
	physical_bone_def_hips.apply_central_impulse(_impulse)
	physical_bone_def_board_root.apply_central_impulse(_impulse)
	
	
func set_end_simulation() -> void:
	print("end ragdoll physics")
	physical_bone_simulator_3d.active = false
	physical_bone_simulator_3d.physical_bones_stop_simulation()
