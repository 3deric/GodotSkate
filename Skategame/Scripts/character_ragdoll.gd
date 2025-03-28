extends Node3D

@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $"../Char/SK_char_male/Skeleton3D/PhysicalBoneSimulator3D"


func set_start_simulation() -> void:
	print("start ragdoll physics")
	physical_bone_simulator_3d.active = true
	physical_bone_simulator_3d.physical_bones_start_simulation()
	
	
func set_end_simulation() -> void:
	print("end ragdoll physics")
	physical_bone_simulator_3d.active = false
	physical_bone_simulator_3d.physical_bones_stop_simulation()
