@tool
extends CSGPolygon3D

@export var offset = 2.0:
	set(new_offset):
		offset = new_offset
		print(offset)
		var width = offset;
		var height = offset;
		polygon = PackedVector2Array([
			Vector2(-width/2, -height/2),
			Vector2(-width/2, height/2),
			Vector2(width/2, height/2),
   			Vector2(width/2, -height/2),
			])
