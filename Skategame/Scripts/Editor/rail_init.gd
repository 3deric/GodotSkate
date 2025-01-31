extends CSGPolygon3D


# Called when the node enters the scene tree for the first time.
func _ready():
	path_node = get_parent().get_path()
