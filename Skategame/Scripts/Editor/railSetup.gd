@tool
extends EditorScript

func _run():
	var nodes: Array = get_editor_interface().get_selection().get_selected_nodes()[0].get_children()
	for node in nodes:
		if node is Path3D:
			var name = node.name
			var csg: CSGPolygon3D = CSGPolygon3D.new()
			var path : Path3D = node
			var parent : Node = path.get_parent()
			
			
			#add csg to scene root
			#parent path to csg
			parent.remove_child(node)
			parent.add_child(csg)
			csg.set_owner(parent.get_tree().get_edited_scene_root())
			csg.add_child(path)
			path.set_owner(csg.get_tree().get_edited_scene_root())
		
			#change csg mode
			#assign path to csg
			#center extruded path and change thickness
			csg.mode = CSGPolygon3D.MODE_PATH
			csg.path_node = path.get_path()
			var offset = 0.2
			csg.polygon = PackedVector2Array([
				Vector2(-offset/2, -offset/2),
				Vector2(-offset/2, offset/2),
				Vector2(offset/2, offset/2),
   				Vector2(offset/2, -offset/2),
				])
			#add csg to rampRail group
			csg.add_to_group('rampRail', true)
