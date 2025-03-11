extends Control

@export var Player: Node3D

func _process(_delta):
	queue_redraw()

func _draw():
	#_debug_draw(Player.global_position, Player.global_position + Player.transform.basis.x, Color.GREEN, 2.0)
	#_debug_draw(Player.global_position, Player.global_position + Player.transform.basis.y, Color.RED, 2.0)
	#_debug_draw(Player.global_position, Player.global_position + Player.transform.basis.z, Color.BLUE ,2.0)
	#if (Player.player_state != Player.PlayerState.GRIND):
	#	_debug_draw(Player.global_position, Player.global_position + Player.velocity * 0.25, Color.PURPLE, 4.0)
	#else:		
	#	_debug_draw(Player.global_position, Player.global_position + Player.xform.basis.z * Player.path_vel * 0.25, Color.PURPLE, 4.0)
	#_debug_draw(Player.global_position, Player.global_position + Player.up_direction * 2, Color.PINK, 2.0)
	#_debug_draw(Player.curve_snap, Player.curve_snap + Vector3.UP * 2, Color.PINK, 2.0)
	#_debug_draw(Player.global_position, Player.last_ground_pos, Color.BLUE, 2.0)
	_debug_draw(Player.global_position, Player.global_position + Player.curve_tangent * Player.path_dir * -1, Color.BLUE, 2.0)
	
func _debug_draw(from, to, col, thickness):
	draw_line(Player.Camera.unproject_position(from), Player.Camera.unproject_position(to), col, thickness)
