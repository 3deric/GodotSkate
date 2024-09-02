@tool
extends EditorScript

func _run():
	var nodes: Array = get_editor_interface().get_selection().get_selected_nodes()[0].get_children()
	for node in nodes:
		if node is Path3D:
			var csg: CSGPolygon3D = CSGPolygon3D.new()
			var path : Path3D = node
			var parent : Node = path.get_parent()
			
			parent.remove_child(node)
