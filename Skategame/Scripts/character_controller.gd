extends CharacterBody3D

#global movement constants
const ACC :float= 0.1
const JUMP_VEL :float = 5.0
const ROT :float= 2.0
const ROT_KICKTURN : float = 4.0
const ROT_JUMP :float= 7.0
const MAX_VEL :float = 12.0
const GRAVITY :float = 15.0
const BALANCE_MULTI : float= 0.5
const PIPESNAP_OFFSET :float = 0.0
const UP_ALIGN_SPEED :float = 10.0
const INTERP_SPEED: float = 10.0

#global movement variables
var xform = null
var last_ground_pos : Vector3 = Vector3.ZERO
var fall_timer : float = 0.0
var last_up_dir : Vector3 = Vector3.ZERO
var pipe_snap_flip : bool = false
var jump_timer : float = 0.0
var path_offset : float = 0.0
var path_vel : float = 0.0
var last_vel : Vector3 = Vector3.ZERO
var revert_path : bool = false
var bounce_check : bool = false
var anim_blend : Vector3 = Vector3.ZERO
var ray_forward = {}
var ray_ground = {}
var ray_path = {}

#global object references
@export var is_playing : bool = false
@onready var Char : Node3D = get_node('Char')
@onready var Anim : AnimationTree = get_node('AnimationTree')
@onready var Area: Area3D = get_node('Area3D')
@onready var Collision: CollisionShape3D = get_node('CollisionShape3D')
@export var Camera: Camera3D = null
@export var Camera_Pos: Node3D = null
@export var Ingame_Ui: Control = null

#Enums for player state and Collision detection
enum PlayerState {
	RESET, 
	GROUND, 
	PIPE, 
	PIPESNAP, 
	PIPESNAPAIR, 
	AIR, FALL, 
	GRIND, LIP, 
	MANUAL,
	}

var player_state = PlayerState.RESET
var last_player_state = PlayerState.RESET

#input variables
var input : Vector3 = Vector3.ZERO #input values
var input_tricks : Vector3 = Vector3.ZERO #input values for tricks

#grind and lip trick variables
var balance_time  : float = 1.0
var balance_angle : float = 0.0 #value between - pi and pi to balance the player on grinds, lips and manuals
var balance_dir : int = 0 #defines balance direction based on last input
var path: Path3D = null
var path_dir: int = 0
var lip_start_up: Vector3 = Vector3.ZERO
var lip_start_vel: Vector3 = Vector3.ZERO
var lip_start_dir: Vector3 = Vector3.ZERO
var curve_snap = Vector3.ZERO
var curve_tangent = Vector3.ZERO

func _ready():
	if !is_playing:
		Anim.set('parameters/conditions/is_setup', true)
		return
	_init_player()
	_reset_player(Vector3(-3.149,6.868,18.256) + Vector3.UP * 5.0)
	

func _process(delta):
	if !is_playing:
		return
	_input_handler()
	_animation_handler(delta)
	if(player_state != PlayerState.FALL):
		_lerp_vis_transform(delta, INTERP_SPEED)
	else:
		fall_timer -= delta
	if(player_state == PlayerState.GRIND):
		Char.rotation.z = -balance_angle
	if(player_state == PlayerState.LIP):
		Char.rotation.x = -balance_angle
	Camera_Pos.position = Camera_Pos.position.lerp(global_position, delta * 10)


func _physics_process(delta):
	if !is_playing:
		return
	xform = global_transform
	_debug_player_state()
	_surface_check()
	_jump_timer(delta)
	_player_state()
	match player_state:
		PlayerState.FALL:
			return
		PlayerState.GROUND, PlayerState.PIPE:
			#_check_bounce()
			_check_reverse_motion()
			_ground_movement(delta)
		PlayerState.AIR:
			#_check_bounce()
			_air_movement(delta)
		PlayerState.PIPESNAP:
			_check_bounce_path(true)
			_pipe_snap_movement(delta)
		PlayerState.PIPESNAPAIR:
			#_check_bounce()
			_pipe_snap_air_movement(delta)
		PlayerState.GRIND:
			_check_bounce_path(false)
			_grind_movement(delta)
		PlayerState.LIP:
			_lip_movement(delta)
	global_transform = _align(global_transform, up_direction)
	last_up_dir = up_direction
	last_vel = velocity
	_set_up_direction()
	move_and_slide()
	_fall_check()
	#if jump_timer < 0.1 and ray_ground != {}:
	if jump_timer < 0.1 and player_state == PlayerState.GROUND:
		apply_floor_snap() #todo, only snap to floor objects, not walls, wrap in function
		

func _player_state():
	if (player_state == PlayerState.FALL):	#dont change the state if fallen
		return
	
	
	if(player_state == PlayerState.GRIND or player_state == PlayerState.LIP):
		Ingame_Ui.set_balance_view(true)
		#Collision.disabled = true
		if path == null:
			player_state = PlayerState.AIR
			return
		if !_get_stick_curve(path,  path_offset):
			velocity = xform.basis.z * path_vel * path_dir
			print("losing pipe")
			player_state = PlayerState.AIR
			return
		return
	else:
		Ingame_Ui.set_balance_view(false)
		#Collision.disabled = false
		
	if(player_state == PlayerState.PIPESNAP):
		if !_get_stick_curve(path,  path_offset):
			player_state = PlayerState.PIPESNAPAIR
			var newUpDir : Vector3 = Vector3.UP.cross(curve_tangent)
			if pipe_snap_flip:
				newUpDir*=-1
			if(newUpDir != Vector3.ZERO):
				up_direction = newUpDir
			else:
				up_direction = last_up_dir
			return
	
	var _closest_path : Path3D = null
	var pathDist : float = 10000.0
	if (player_state != PlayerState.GRIND and player_state != PlayerState.LIP):
		for body in Area.get_overlapping_bodies():
			if(body.is_in_group('rampRail')):
				var currentPath : Path3D = body.get_node(body.get_path_node())
				var currentOffset : float = _get_closest_curve_offset(currentPath, position)
				var closestPos : Vector3 = _get_position_on_curve(currentPath, currentOffset)
				var closestDist : float = position.distance_to(closestPos)
				if(closestDist < pathDist):
					pathDist = closestDist
					_closest_path = currentPath
		
	if _closest_path != null:
		path = _closest_path
		if input_tricks.x == 1 and player_state != PlayerState.GRIND:
			path_offset = path.curve.get_closest_offset(position * path.global_transform)
			curve_tangent = _get_path_tangent(path, path_offset)
			path_dir = _get_path_dir(curve_tangent, 0.25)
			if(curve_tangent == Vector3.ZERO):
				return
			_randomize_balance()
			if(path_dir != 0):
				print(path_offset)
				path_vel = velocity.project(curve_tangent).length() * path_dir
				player_state = PlayerState.GRIND
				return
			if(path_dir == 0 and player_state != PlayerState.PIPESNAP):
				player_state = PlayerState.LIP
				path_offset = path.curve.get_closest_offset(position * path.global_transform)
				print(path_offset)
				lip_start_up = up_direction
				lip_start_vel = velocity
				curve_tangent = _get_path_tangent(path, path_offset)
				var dir : Vector3 = curve_tangent.cross(Vector3(0,1,0))
				if(xform.basis.y.dot(dir) > 0):
					dir *= Vector3(-1,-1,-1)
				lip_start_dir = dir
				return
	if ray_ground == {}:	#behavior while in air, or sticked to a pipe
		if(last_player_state == PlayerState.PIPE and input_tricks.z == 0 and input.y == 0):
			if path != null:
				print(path)
				path_offset = path.curve.get_closest_offset(position * path.global_transform)
				print(path_offset)
				curve_tangent = _get_path_tangent(path, path_offset)
				path_dir = _get_path_dir(curve_tangent, 0.1)
				path_vel = velocity.project(curve_tangent * Vector3(1,0,1)).length() * path_dir
				print(path_vel)
				var dir : Vector3 = curve_tangent.cross(Vector3(0,1,0))
				if(xform.basis.y.dot(dir) > 0):
					pipe_snap_flip = true
				else:
					pipe_snap_flip = false
				if _get_stick_curve(path, path_offset):
					player_state = PlayerState.PIPESNAP
					return
		if(player_state != PlayerState.PIPESNAP and player_state != PlayerState.PIPESNAPAIR):
			player_state = PlayerState.AIR	
			
	#if is_on_floor():
	if ray_ground != {}:
		var _coll_info = null
		_coll_info = ray_ground["collider"]
		#print(ray_ground["normal"].dot(xform.basis.y))
		if ray_ground["normal"].dot(xform.basis.y) < 0.5:
			return
		if _coll_info.is_in_group('pipe'):
			player_state = PlayerState.PIPE
			path = null
			return
		if _coll_info.is_in_group('floor'):
			player_state = PlayerState.GROUND
			path = null
			return


func _surface_check():
	ray_ground = _raycast(position + xform.basis.y * 0.1, xform.basis.y, -0.5)
	ray_forward = _raycast(position + xform.basis.y * 1.0, velocity.normalized(),2.5)
	ray_path = _raycast(position + xform.basis.y * 1.0, curve_tangent * path_dir, -0.5)
	#if ray_path != {}:
	#	print(ray_path["collider"].is_in_group('floor'))
	#	print(ray_path["normal"])


func _get_path_tangent(_path: Path3D, _offset: float): #returns the curve tangent
	var _lastOffset : float = _offset + 0.01
	var _curvePos : Vector3 = _path.curve.sample_baked(_offset, true)
	var _lastCurvePos : Vector3 = _path.curve.sample_baked(_lastOffset, true)
	var _tangent : Vector3 = (_curvePos - _lastCurvePos).normalized()
	return _tangent
	

func _get_path_dir(_tangent: Vector3, _treshold): #direction along curve based on start pos
	var _pathDir : float = _tangent.dot(velocity.normalized())
	if(_pathDir > _treshold):
		return  -1
	if(_pathDir < -_treshold):
		return 1
	else:
		return 0


func _get_closest_curve_point(_path: Path3D,_pos: Vector3):
	var _curve: Curve3D = _path.curve
	var _pathTransform: Transform3D = _path.global_transform  # target position to local space
	var _localPos: Vector3 = _pos * _pathTransform
	var _offset: float = _curve.get_closest_offset(_localPos)
	var _curvePos: Vector3 = _curve.sample_baked(_offset, true)
	_curvePos = _pathTransform * _curvePos   # transform back to world space
	return _curvePos


func _get_closest_curve_offset(_path: Path3D, _pos: Vector3):
	var _curve: Curve3D = _path.curve
	var _pathTransform: Transform3D = _path.global_transform
	var _localPos: Vector3 = _pos * _pathTransform
	var _offset: float = _curve.get_closest_offset(_localPos)
	return _offset
	

func _get_position_on_curve(_path: Path3D, _offset):
	var _curve: Curve3D = _path.curve
	var _curvePos: Vector3 = _curve.sample_baked(_offset, true)
	return _curvePos
	
func _get_stick_curve(_path: Path3D,_offset: float):
	var _curve: Curve3D = _path.curve
	if(_offset <= 0.1 or _offset >= _curve.get_baked_length() -.1):
		return false
	else:
		return true


func _set_up_direction():
	if ray_ground != {}:	
		up_direction = (ray_ground["normal"] + last_up_dir) / 2
	#if is_on_floor():
		#up_direction = (get_floor_normal() + last_up_dir) / 2
	else:
		up_direction = last_up_dir
		
	
func _lerp_vis_transform(delta, _speed):
	pass
	Char.global_transform = Char.global_transform.interpolate_with(global_transform, delta * _speed)
	if player_state != PlayerState.GRIND: #interpolate position to remove jitter on rails
		Char.global_position = global_position


func _fall(_fall_reason, _fall_value):
	print(_fall_reason + ": " + str(_fall_value))
	player_state = PlayerState.FALL
	Ingame_Ui.set_fail_view(true)
	fall_timer = 2.0
	

func _reset_player(_pos):
	Ingame_Ui.set_fail_view(false)
	up_direction = Vector3.UP
	velocity = Vector3.ZERO
	global_position = _pos
	global_rotation =  Vector3(0,3.14/2,0)
	player_state = PlayerState.RESET
	last_player_state = PlayerState.RESET
	balance_angle = 0.0


func _input_handler(): 	#handles player inputs
	input.x = int(Input.is_action_pressed('Left')) - int(Input.is_action_pressed('Right'))
	input.y = int(Input.is_action_pressed('Forward')) - int(Input.is_action_pressed('Backward'))
	input.z = int(Input.is_action_pressed('Jump'))
	input_tricks.x = int(Input.is_action_pressed('Grind'))
	input_tricks.y = int(Input.is_action_pressed('Revert'))
	input_tricks.z = int(Input.is_action_just_released('Jump'))
	if(input.y and player_state == PlayerState.FALL and fall_timer < 0.1):
		_reset_player(last_ground_pos + Vector3.UP * 5.0)


func _animation_handler(delta):
	anim_blend = anim_blend.lerp(input, delta * INTERP_SPEED)
	match player_state:
		PlayerState.FALL:
			return
		PlayerState.GROUND, PlayerState.PIPE:	
			Anim.set('parameters/conditions/is_stopped', true)
			Anim.set('parameters/conditions/is_air',false)
			Anim.set('parameters/conditions/is_grind', false)
			Anim.set('parameters/conditions/is_lip', false)
			if velocity.length() > 0.25:
				Anim.set('parameters/conditions/is_riding', true)
				Anim.set('parameters/conditions/is_stopped', false)
			else:
				Anim.set('parameters/conditions/is_riding', false)
				Anim.set('parameters/conditions/is_stopped', true)
			Anim.set('parameters/Ground/blend_position', anim_blend)
		PlayerState.AIR, PlayerState.PIPESNAP, PlayerState.PIPESNAPAIR:
			Anim.set('parameters/conditions/is_riding', false)
			Anim.set('parameters/conditions/is_stopped', false)
			Anim.set('parameters/conditions/is_air', true)
			Anim.set('parameters/conditions/is_grind', false)
			Anim.set('parameters/conditions/is_lip', false)
			Anim.set('parameters/Air/blend_position', anim_blend)
		PlayerState.GRIND:
			Anim.set('parameters/conditions/is_riding', false)
			Anim.set('parameters/conditions/is_stopped', false)
			Anim.set('parameters/conditions/is_air', false)
			Anim.set('parameters/conditions/is_grind', true)
			Anim.set('parameters/conditions/is_lip', false)
			Anim.set('parameters/Grind/blend_position', anim_blend)
		PlayerState.LIP:
			Anim.set('parameters/conditions/is_riding', false)
			Anim.set('parameters/conditions/is_stopped', false)
			Anim.set('parameters/conditions/is_air', false)
			Anim.set('parameters/conditions/is_grind', false)
			Anim.set('parameters/conditions/is_lip', true)
			Anim.set('parameters/Lip/blend_position', anim_blend)


func _kill_orthogonal_velocity(_xForm : Transform3D, _vel: Vector3): 	#remove orthogonal component of velocity
	var _fwdVel : Vector3 = _xForm.basis.z * _vel.dot(_xForm.basis.z)
	var _ortVel : Vector3 = _xForm.basis.x * _vel.dot(_xForm.basis.x)
	var _upVel : Vector3 = _xForm.basis.y  * _vel.dot(_xForm.basis.y)
	var _velocity :Vector3 = _fwdVel + _ortVel * 0.1 + _upVel
	return _velocity


func _kill_pipe_orthogonal_velocity(_vel: Vector3, _tangent: Vector3):
	var _newVel : Vector3 = _vel.dot(_tangent) * _tangent
	_newVel.y = _vel.y
	var _velocity : Vector3 = _newVel
	return _velocity


func _align(_xForm, _newUp): 	#align xform to up vector
	_xForm.basis.y = _newUp
	_xForm.basis.x = _xForm.basis.z.cross(-_newUp)
	_xForm.basis = _xForm.basis.orthonormalized()
	return _xForm


func _limit_velocity():
	if velocity.length() > MAX_VEL:
		velocity = velocity.normalized() * MAX_VEL


func _revert_motion():
	global_rotate(xform.basis.y, PI)


func _ground_movement(delta): 	#movement while grounded
	if player_state == PlayerState.GROUND:
		last_ground_pos = global_position
	if input.y < 0:
		velocity *= 0.95
		global_rotate(xform.basis.y, input.x * ROT_KICKTURN * delta)
	else:
		global_rotate(xform.basis.y, input.x * ROT * delta)
	if input.y >= 0 and velocity.length() < MAX_VEL/8 and _forward_velocity().length() > 0.1 or input.y > 0:
		velocity +=xform.basis.z * ACC * 0.25
	if((input.z > 0 and velocity.length() <= MAX_VEL and input.y != -1) or (input.z < 0 and velocity.length() >= -MAX_VEL)):
		velocity += xform.basis.z * input.z * ACC
	if input_tricks.z > 0:
		velocity += Vector3.UP * JUMP_VEL
		jump_timer = 1.0
	velocity.y -= GRAVITY * delta
	velocity = _kill_orthogonal_velocity(xform, velocity)


func _air_movement(delta): 	#movement while in air
	global_rotate(xform.basis.y, input.x * ROT_JUMP * delta)
	velocity.y -= GRAVITY * delta
	up_direction = lerp(up_direction,Vector3.UP, delta * UP_ALIGN_SPEED)
	

func _pipe_snap_movement(delta): 	#movement while snapped to a pipe
	global_rotate(xform.basis.y, input.x * ROT_JUMP * delta)
	curve_snap = path.curve.sample_baked(path_offset, true)
	path_offset += path_vel * delta
	curve_tangent = (_get_path_tangent(path, path_offset) * Vector3(1,0,1)).normalized()
	up_direction = _pipe_snap_up_dir(curve_tangent)
	position = Vector3(curve_snap.x, position.y, curve_snap.z) + up_direction * PIPESNAP_OFFSET
	velocity.y -= GRAVITY * delta
	velocity = _kill_pipe_orthogonal_velocity(velocity, curve_tangent)


func _pipe_snap_up_dir(_curveTangent): #calculate upvector while snapped to a pipe
	var _newUpDir : Vector3 = Vector3.UP.cross(_curveTangent)
	var _last_up_dir : Vector3 = last_up_dir
	if pipe_snap_flip:
		_newUpDir *= -1
	if(_newUpDir != Vector3.ZERO):
		return _newUpDir
	else:
		return _last_up_dir


func _pipe_snap_air_movement(delta):	#movement when snapped pipe is left in air
	global_rotate(xform.basis.y, input.x * ROT_JUMP * delta)
	velocity.y -= GRAVITY * delta


func _grind_movement(delta) -> void: 	#movement logic while grinding a rail
	curve_snap = path.curve.sample_baked(path_offset, true)
	path_offset += path_vel * delta
	curve_tangent = _get_path_tangent(path, path_offset)
	position = curve_snap
	up_direction = path.curve.sample_baked_up_vector(path_offset)
	#if revert_path:
	#	look_at(global_position + curve_tangent * -path_dir, up_direction)
	#else:
	look_at(global_position + curve_tangent * path_dir, up_direction)
	velocity = xform.basis.z * path_vel * path_dir
	if input_tricks.z:
		velocity = xform.basis.z * abs(path_vel)
		velocity += Vector3.UP * input_tricks.z * JUMP_VEL
		velocity += xform.basis.x * balance_dir
		path = null
		return
	#balance logic
	balance_time += 0.05 * delta
	balance_angle += BALANCE_MULTI * delta * balance_dir * balance_time
	if(input.x != 0):
		balance_dir = int(input.x)
	Ingame_Ui.set_balance_value(-balance_angle)


func _lip_movement(delta) -> void:
	#Collision.disabled = true
	position = path.curve.sample_baked(path_offset)
	up_direction = path.curve.sample_baked_up_vector(path_offset)
	rotation.y = atan2(lip_start_dir.x,lip_start_dir.z)
	if(input_tricks.z):
		velocity = velocity.normalized() * -1
		player_state = PlayerState.AIR
		#position += lip_start_up + Vector3.UP - lip_start_dir * Vector3(1,0,1) * 0.1
		position -= lip_start_dir * balance_dir * 0.5
		velocity = lip_start_vel.normalized() * -1
		up_direction = Vector3.UP
		rotation.y = atan2(lip_start_dir.x * -balance_dir,lip_start_dir.z * -balance_dir)
	balance_time += 0.05 * delta
	balance_angle += BALANCE_MULTI * delta * balance_dir * balance_time
	if(input.y != 0):
		balance_dir = int(-input.y)
	Ingame_Ui.set_balance_value(-balance_angle)


func _randomize_balance() -> void:
	balance_time = 1.0
	balance_angle = 0.0
	var _rand : float  = randf()
	if (_rand >= 0.5):
		balance_dir = 1
	else:
		balance_dir = -1
		balance_angle = 0


func _init_player():
	pass


func _check_reverse_motion() -> void:
	if _forward_velocity().length() < 1.0:
		return
	var revertCheck : float = velocity.normalized().dot(xform.basis.z)
	if revertCheck < 0:
		_revert_motion()


func _check_bounce_path(air : bool) -> void:
	if ray_path != {} and !revert_path:
		if air:
			path_vel *= -0.1
			#add look at logic for air movement
		else: 
			path_vel *= -1.0
			look_at(global_position + curve_tangent * -path_dir, up_direction)
		path_dir *= -1
		revert_path = true
	if ray_path == {}:
		revert_path = false


func _check_bounce() -> void:
	if ray_forward != {} and !bounce_check:
		bounce_check = true
		print(ray_forward["normal"])
		var _prev_velocity = velocity.length()
		look_at(global_position + velocity.reflect(ray_forward["normal"]), up_direction)
		velocity = xform.basis.z * _prev_velocity
	if ray_forward == {} and bounce_check:
		bounce_check = false


func _debug_player_state() -> void:
	#debug logic to print the player state only on change
	if(player_state != last_player_state):
		print(PlayerState.find_key(player_state))
	last_player_state = player_state


func _jump_timer(delta) -> void:
	if jump_timer > 0:
		jump_timer -= delta


func _forward_velocity() -> Vector3:
	return velocity.slide(up_direction)
	

func _horizontal_velocity() -> Vector3:
	return velocity.slide(Vector3.UP)


func _raycast(_from: Vector3, _dir: Vector3, _len: float):
	var _spaceState : PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var _query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(_from, _from + _dir * _len)
	_query.exclude = [self]
	var _col = _spaceState.intersect_ray(_query)
	return _col
	

func _fall_check():
	if player_state == PlayerState.GRIND or player_state == PlayerState.LIP:
		if (balance_angle > PI /4 or balance_angle < -PI /4):
			_fall("balance issues", balance_angle)
			return
	#if is_on_floor():
	#	var _check = abs(_forward_velocity().normalized().dot(xform.basis.z))
	#	if _check < 0.25 and _check != 0 and abs(_forward_velocity().length()) > 1:
	#		_fall("Ground", _check)
	#		return
	#if is_on_wall():
	#	if last_vel.length() > 10:
	#		_fall("Wall", last_vel.length())
	#		return
	
