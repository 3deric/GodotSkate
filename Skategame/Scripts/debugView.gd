extends Control

@export var camera: Camera3D
@export var player: Node3D

func _process(delta):
	queue_redraw()

func _draw():	
	#player.global_position+ player.global_transform.basis.z
	_debugDraw(player.global_position , player.global_position + player.vel , Color.GREEN)
	_debugDraw(player.global_position , player.global_position + player.tempVector * 50, Color.RED)
	#_debugDraw(player.global_position, player.global_position + Vector3.UP, Color.RED)
	#_debugDraw(player.global_position, player.global_position + player.transform.basis.y, Color.RED)
	#_debugDraw(player.global_position, player.global_position - player.transform.basis.y, Color.ORANGE)
	#_debugDraw(player.global_position, player.global_position + player.transform.basis.x, Color.BLUE)
	pass
	
func _debugDraw(from, to, col):
	draw_line(camera.unproject_position(from), camera.unproject_position(to), col, 4.0)




