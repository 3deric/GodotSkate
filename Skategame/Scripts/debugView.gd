extends Control

@export var camera: Camera3D
@export var player: Node3D

func _process(delta):
	queue_redraw()

func _draw():	
	_debugDraw(player.global_position, player.global_position + player.velocity * 0.25, Color.PURPLE)
	_debugDraw(player.global_position, player.global_position + Vector3.UP, Color.RED)
	_debugDraw(player.global_position, player.global_position + player.transform.basis.z, Color.GREEN)
	_debugDraw(player.global_position, player.global_position + player.transform.basis.y, Color.RED)
	_debugDraw(player.global_position, player.global_position + player.up_direction, Color.ORANGE)
	#_debugDraw(player.global_position, player.global_position + player.transform.basis.x, Color.BLUE)
	pass
	
func _debugDraw(from, to, col):
	draw_line(camera.unproject_position(from), camera.unproject_position(to), col, 2.0)




