@tool
extends EditorScript

const OFFSET : float = 0.05
const PATH_INTERVAL : float = 0.25

func _run():
	var nodes: Array = get_editor_interface().get_selection().get_selected_nodes()[0].get_children()
	for node in nodes:
		##get rails of park element
		##elements are from type MeshInstance3D
		var name = node.name
		var parent : Node = node.get_parent()
		if name.split('_')[1] == 'Rail':		
			print(name)
			var _csg: CSGPolygon3D = CSGPolygon3D.new()
			var _mesh = node.get_mesh()
			var _mesh_arrays = _mesh.surface_get_arrays(0)
			var _path : Path3D = Path3D.new()
			var _curve: Curve3D = Curve3D.new()
			for i in len(_mesh_arrays[0]):
				#add points with parent offset
				var _pos : Vector3 = _mesh_arrays[0][i]
				var _t : Transform3D = parent.transform.affine_inverse()
				_pos *= _t
				_curve.add_point(_pos)
			_path.curve = _curve
			#add _csg and _path to the scene, _csg is a child of the _path
			parent.add_child(_path)
			#parent.get_tree().get_edited_scene_root().add_child(_path)
			_path.set_owner(parent.get_tree().get_edited_scene_root())
			_path.add_child(_csg)
			_csg.set_owner(_path.get_tree().get_edited_scene_root())
			#offset _path to the scene orgin
			_path.global_position = Vector3.ZERO
			_path.global_rotation = Vector3.ZERO
			#set names for _path and _csg
			_path.name = name + "_Path"
			_csg.name = name + "_CSG"
			#change _csg mode
			#assign _path to _csg
			#center extruded _path and change thickness
			_csg.mode = CSGPolygon3D.MODE_PATH
			_csg.path_interval = PATH_INTERVAL
			_csg.path_node = _path.get_path()
			_csg.polygon = PackedVector2Array([
				Vector2(-OFFSET/2, -OFFSET/2),
				Vector2(-OFFSET/2, OFFSET/2),
				Vector2(OFFSET/2, OFFSET/2),
				   Vector2(OFFSET/2, -OFFSET/2),
				])
			#add _csg to rampRail group
			_csg.add_to_group('rampRail', true)
			#enable collision
			_csg.use_collision = true
			#set collision layer
			_csg.set_collision_layer_value(1,false)
			_csg.set_collision_layer_value(4,true)
			#turn off shadow casting
			_csg.cast_shadow = 0
			#set material
			_csg.material = load('res://Assets/Materials/M_path.tres')
			_csg.set_script(load('res://Scripts/Editor/rail_init.gd'))
		##generate colliders
		if name.split('_')[1] == 'Col':
			print(name)
			var _mesh_instance : MeshInstance3D = MeshInstance3D.new()
			_mesh_instance.name = name + '_col_mesh'
			_mesh_instance.mesh = node.mesh
			_mesh_instance.visible = false	
			parent.add_child(_mesh_instance)
			_mesh_instance.set_owner(parent.get_tree().get_edited_scene_root())
			_mesh_instance.create_trimesh_collision()
			var col = _mesh_instance.get_child(0)
			match name.split('_')[2]:
				'Floor':
					col.add_to_group('floor', true)
				'Wall':
					col.add_to_group('wall', true)
				'Pipe':
					col.add_to_group('pipe', true)
