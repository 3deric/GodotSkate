extends Control

#@export var camera: Camera3D
@export var player: Node3D

func _process(delta):
	queue_redraw()

func _draw():
	_debugDraw(player.global_position, player.global_position + player.transform.basis.x, Color.GREEN, 2.0)
	_debugDraw(player.global_position, player.global_position + player.transform.basis.y, Color.RED, 2.0)
	_debugDraw(player.global_position, player.global_position + player.transform.basis.z, Color.BLUE ,2.0)
	if (player.playerState != player.PlayerState.GRIND):
		_debugDraw(player.global_position, player.global_position + player.velocity * 0.25, Color.PURPLE, 4.0)
	else:
		_debugDraw(player.global_position, player.global_position + player.pathVelocity * 0.25, Color.PURPLE, 4.0)
	_debugDraw(player.global_position, player.global_position + player.up_direction * 2, Color.PINK, 2.0)
	#_debugDraw(player.curveSnap, player.curveSnap + Vector3.UP * 2, Color.PINK, 2.0)
	_debugDraw(player.global_position, player.lastGroundPos, Color.BLUE, 2.0)
	
func _debugDraw(from, to, col, thickness):
	draw_line(player.camera.unproject_position(from), player.camera.unproject_position(to), col, thickness)




