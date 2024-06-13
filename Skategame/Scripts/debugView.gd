extends Control

#@export var camera: Camera3D
@export var player: Node3D

func _process(delta):
	queue_redraw()

func _draw():
	_debugDraw(player.global_position, player.global_position + player.transform.basis.x, Color.GREEN)
	_debugDraw(player.global_position, player.global_position + player.transform.basis.y, Color.RED)
	_debugDraw(player.global_position, player.global_position + player.transform.basis.z, Color.BLUE)
	_debugDraw(player.global_position, player.global_position + player.velocity * 0.25, Color.PURPLE)
	_debugDraw(player.global_position, player.global_position + player.up_direction * 2, Color.PINK)
	_debugDraw(player.curveSnap, player.curveSnap + Vector3.UP * 2, Color.PINK)
	_debugDraw(player.global_position, player.global_position + player.curveTangent * 2, Color.BLUE)
	
func _debugDraw(from, to, col):
	draw_line(player.camera.unproject_position(from), player.camera.unproject_position(to), col, 2.0)




