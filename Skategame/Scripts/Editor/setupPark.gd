@tool
extends EditorScript

const offset : float = 0.1

func _run():
    var nodes: Array = get_editor_interface().get_selection().get_selected_nodes()[0].get_children()
    for node in nodes:
        ##get rails of park element
        ##elements are from type MeshInstance3D
        var name = node.name
        var parent : Node = node.get_parent()
        if name.split('_')[1] == 'Rail':		
            var csg: CSGPolygon3D = CSGPolygon3D.new()
            var mesh = node.get_mesh()
            var meshArrays = mesh.surface_get_arrays(0)
            var path : Path3D = Path3D.new()
            var curve: Curve3D = Curve3D.new()
            for i in len(meshArrays[0]):
                curve.add_point(meshArrays[0][i])
            path.curve = curve
            #add csg and path to the scene, csg is a child of the path
            parent.add_child(path)
            path.set_owner(parent.get_tree().get_edited_scene_root())
            path.add_child(csg)
            csg.set_owner(path.get_tree().get_edited_scene_root())
            #set names for path and csg
            path.name = name + "_Path"
            csg.name = name + "_CSG"
            #change csg mode
            #assign path to csg
            #center extruded path and change thickness
            csg.mode = CSGPolygon3D.MODE_PATH
            csg.path_node = path.get_path()
            csg.polygon = PackedVector2Array([
                Vector2(-offset/2, -offset/2),
                Vector2(-offset/2, offset/2),
                Vector2(offset/2, offset/2),
                   Vector2(offset/2, -offset/2),
                ])
            #add csg to rampRail group
            csg.add_to_group('rampRail', true)
            #enable collision
            csg.use_collision = true
            #set collision layer
            csg.set_collision_layer_value(1,false)
            csg.set_collision_layer_value(4,true)
            #turn off shadow casting
            csg.cast_shadow = 0
            #remove offset from csg
            csg.global_position = Vector3(0,0,0)
            #set material
            csg.material = load("res://Materials/M_path.tres")
        #generate colliders
        if name.split('_')[1] == 'Col':
            var meshInstance : MeshInstance3D = MeshInstance3D.new()
            meshInstance.name = name + "_ColMesh"
            meshInstance.mesh = node.mesh
            node.visible = false
            meshInstance.visible = false
            
            parent.add_child(meshInstance)
            meshInstance.set_owner(parent.get_tree().get_edited_scene_root())
            meshInstance.create_trimesh_collision()
            var col = meshInstance.get_child(0)
            match name.split('_')[2]:
                'Floor':
                    col.add_to_group('floor', true)
                'Wall':
                    col.add_to_group('wall', true)
                'Pipe':
                    col.add_to_group('pipe', true)
