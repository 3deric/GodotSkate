extends Control

#@export var camera: Camera3D
@export var Player: Node3D

func _process(_delta):
	queue_redraw()

func draw():
	_debug_draw(Player.global_position, Player.global_position + Player.transform.basis.x, Color.GREEN, 2.0)
	_debug_draw(Player.global_position, Player.global_position + Player.transform.basis.y, Color.RED, 2.0)
	_debug_draw(Player.global_position, Player.global_position + Player.transform.basis.z, Color.BLUE ,2.0)
	if (Player.playerState != Player.PlayerState.GRIND):
		_debug_draw(Player.global_position, Player.global_position + Player.velocity * 0.25, Color.PURPLE, 4.0)
	else:		
		_debug_draw(Player.global_position, Player.global_position + Player.xForm.basis.z * Player.pathVel * 0.25, Color.PURPLE, 4.0)
	_debug_draw(Player.global_position, Player.global_position + Player.up_direction * 2, Color.PINK, 2.0)
	_debug_draw(Player.curveSnap, Player.curveSnap + Vector3.UP * 2, Color.PINK, 2.0)
	_debug_draw(Player.global_position, Player.lastGroundPos, Color.BLUE, 2.0)
	
func _debug_draw(from, to, col, thickness):
	draw_line(Player.camera.unproject_position(from), Player.camera.unproject_position(to), col, thickness)
