extends CharacterBody3D

#global movement constants
const acc :float= 0.1
const jumpVel :float = 5.0
const rot :float= 2.0
const rotKickturn : float = 4.0
const rotJump :float= 7.0
const maxVel :float = 12.0
const gravity :float = 15.0
const balanceMulti : float= 1.0
const pipesnapOffset :float = 0.0
const upAlignSpd :float = 10.0
const interpSpd: float = 15.0

#global movement variables
var xForm = null
var lastGroundPos : Vector3 = Vector3.ZERO
var fallTimer : float = 0.0
var lastUpDir : Vector3 = Vector3.ZERO
var pipeSnapFlip : bool = false
var jumpTimer : float = 0.0
var pathOffset : float = 0.0
var pathVel : float = 0.0
var lastVel : Vector3 = Vector3.ZERO
#global object references
@onready var rbdBoard: RigidBody3D = get_node('RBDBoard')
@onready var rbdChar: RigidBody3D = get_node('RBDCharacter')
@onready var area: Area3D = get_node('Area3D')
@onready var collision: CollisionShape3D = get_node('CollisionShape3D')
@onready var raycastGnd: RayCast3D = get_node('RayCast3DGround')
@onready var raycastFwd: RayCast3D = get_node('RayCast3DForward')
@export var camera: Camera3D = null
@export var cameraPos: Node3D = null
@export var ingameUI: Control = null

#Enums for player state and collision detection
enum PlayerState {RESET, GROUND, PIPE, PIPESNAP, PIPESNAPAIR, AIR, FALL, GRIND, LIP, MANUAL}
var playerState = PlayerState.RESET
var lastPlayerState = PlayerState.RESET

#input variables
var input : Vector3 = Vector3.ZERO #input values
var inputTricks : Vector3 = Vector3.ZERO #input values for tricks

#grind and lip trick variables
var balanceTime  : float = 1.0
var balanceAngle : float = 0.0 #value between - pi and pi to balance the player on grinds, lips and manuals
var balanceDir : int = 0 #defines balance direction based on last input
var path: Path3D = null
var pathDir: int = 0
var lipStartUp: Vector3 = Vector3.ZERO
var lipStartVel: Vector3 = Vector3.ZERO
var lipStartDir: Vector3 = Vector3.ZERO
var curveSnap = Vector3.ZERO
var curveTangent = Vector3.ZERO

func _ready():
	_initPlayer()
	_resetPlayer(Vector3(-3.149,6.868,18.256) + Vector3.UP * 5.0)

func _physics_process(delta):
	xForm = global_transform
	_debugPlayerState()
	_jumpTimer(delta)
	_playerState()
	match playerState:
		PlayerState.FALL:
			return
		PlayerState.GROUND, PlayerState.PIPE:
			_checkTurnAround()
			_checkRevertMotion()
			_groundMovement(delta)
		PlayerState.AIR:
			_checkRevertMotion()
			_airMovement(delta)
		PlayerState.PIPESNAP:
			_checkRevertMotion()
			_pipeSnapMovement(delta)
		PlayerState.PIPESNAPAIR:
			_checkRevertMotion()
			_pipeSnapAirMovement(delta)
		PlayerState.GRIND:
			_checkGrindRevertMotion()
			_grindMovement(delta)
		PlayerState.LIP:
			_lipMovement(delta)
	global_transform = _align(global_transform, up_direction)
	lastUpDir = up_direction
	lastVel = velocity
	_setUpDirection()
	move_and_slide()
	_fallCheck()
	if jumpTimer < 0.1 and raycastGnd.is_colliding():
		apply_floor_snap()

func _playerState():
	if (playerState == PlayerState.FALL):	#dont change the state if fallen
		return
	
	if(playerState == PlayerState.GRIND or playerState == PlayerState.LIP):
		ingameUI._setBalanceView(true)
		#collision.disabled = true
		if path == null:
			playerState = PlayerState.AIR
			return
		if !_getStickCurve(path,  pathOffset):
			velocity = xForm.basis.z * pathVel * pathDir
			print("losing pipe")
			playerState = PlayerState.AIR
			return
		return
	else:
		ingameUI._setBalanceView(false)
		#collision.disabled = false
		
	if(playerState == PlayerState.PIPESNAP):
		if !_getStickCurve(path,  pathOffset):
			playerState = PlayerState.PIPESNAPAIR
			var newUpDir = Vector3.UP.cross(curveTangent)
			if pipeSnapFlip:
				newUpDir*=-1
			if(newUpDir != Vector3.ZERO):
				up_direction = newUpDir
			else:
				up_direction = lastUpDir
			return
	
	var closestPath = null
	var pathDist = 10000
	if (playerState != PlayerState.GRIND and playerState != PlayerState.LIP):
		for body in area.get_overlapping_bodies():
			if(body.is_in_group('rampRail')):
				var currentPath = body.get_node(body.get_path_node())
				var currentOffset = _getClosestCurveOffset(currentPath, position)
				var closestPos = _getPositionOnCurve(currentPath, currentOffset)
				var closestDist = position.distance_to(closestPos)
				if(closestDist < pathDist):
					pathDist = closestDist
					closestPath = currentPath
		
	if closestPath != null:
		path = closestPath
		if inputTricks.x == 1 and playerState != PlayerState.GRIND:
			pathOffset = path.curve.get_closest_offset(position * path.global_transform)
			curveTangent = _getPathTangent(path, pathOffset)
			pathDir = _getPathDir(curveTangent, 0.25)
			if(curveTangent == Vector3.ZERO):
				return
			_randomizeBalance()
			if(pathDir != 0):
				print(pathOffset)
				pathVel = velocity.project(curveTangent).length() * pathDir
				playerState = PlayerState.GRIND
				return
			if(pathDir == 0 and playerState != PlayerState.PIPESNAP):
				playerState = PlayerState.LIP
				pathOffset = path.curve.get_closest_offset(position * path.global_transform)
				print(pathOffset)
				lipStartUp = up_direction
				lipStartVel = velocity
				curveTangent = _getPathTangent(path, pathOffset)
				var dir = curveTangent.cross(Vector3(0,1,0))
				if(xForm.basis.y.dot(dir) > 0):
					dir *= Vector3(-1,-1,-1)
				lipStartDir = dir
				return
	if !raycastGnd.is_colliding():	#behavior while in air, or sticked to a pipe
		if(lastPlayerState == PlayerState.PIPE and inputTricks.z == 0 and input.y == 0):
			if path != null:
				print(path)
				pathOffset = path.curve.get_closest_offset(position * path.global_transform)
				print(pathOffset)
				curveTangent = _getPathTangent(path, pathOffset)
				pathDir = _getPathDir(curveTangent, 0.1)
				pathVel = velocity.project(curveTangent * Vector3(1,0,1)).length() * pathDir
				print(pathVel)
				var dir = curveTangent.cross(Vector3(0,1,0))
				if(xForm.basis.y.dot(dir) > 0):
					pipeSnapFlip = true
				else:
					pipeSnapFlip = false
				if _getStickCurve(path, pathOffset):
					playerState = PlayerState.PIPESNAP
					return
		if(playerState != PlayerState.PIPESNAP and playerState != PlayerState.PIPESNAPAIR):
			playerState = PlayerState.AIR	
			
	if is_on_floor():
		var _collInfo = null
		_collInfo = raycastGnd.get_collider()
		_collInfo = get_last_slide_collision()
		if _collInfo:
			if _collInfo.get_collider().is_in_group('pipe'):
				playerState = PlayerState.PIPE
				path = null
				return
			else:
				playerState = PlayerState.GROUND
				path = null
				return

func _surfaceCheck():
	#if playerState == PlayerState.FALL:
	#	return
	#raycastDist = global_position.distance_to(raycast.get_collision_point())
	#if raycastDist < 0.25:
	#	isOnFloor = true
	#else:
	#	isOnFloor = false
	#isOnFloor = raycast.is_colliding() and is_on_floor()
	#isOnWall = is_on_wall() or is_on_ceiling()
	pass

func _getPathTangent(_path: Path3D, _offset: float): #returns the curve tangent
	var _lastOffset = _offset + 0.01
	var _curvePos = _path.curve.sample_baked(_offset, true)
	var _lastCurvePos = _path.curve.sample_baked(_lastOffset, true)
	var _tangent = (_curvePos - _lastCurvePos).normalized()
	return _tangent
	
func _getPathDir(_tangent: Vector3, _treshold): #direction along curve based on start pos
	var _pathDir = _tangent.dot(velocity.normalized())
	if(_pathDir > _treshold):
		return  -1
	if(_pathDir < -_treshold):
		return 1
	else:
		return 0

func _getClosestCurvePoint(_path: Path3D,_pos: Vector3):
	var _curve: Curve3D = _path.curve
	var _pathTransform: Transform3D = _path.global_transform  # target position to local space
	var _localPos: Vector3 = _pos * _pathTransform
	var _offset: float = _curve.get_closest_offset(_localPos)
	var _curvePos: Vector3 = _curve.sample_baked(_offset, true)
	_curvePos = _pathTransform * _curvePos   # transform back to world space
	return _curvePos

func _getClosestCurveOffset(_path: Path3D, _pos: Vector3):
	var _curve: Curve3D = _path.curve
	var _pathTransform: Transform3D = _path.global_transform
	var _localPos: Vector3 = _pos * _pathTransform
	var _offset: float = _curve.get_closest_offset(_localPos)
	return _offset
	
func _getPositionOnCurve(_path: Path3D, _offset):
	var _curve: Curve3D = _path.curve
	var _curvePos: Vector3 = _curve.sample_baked(_offset, true)
	return _curvePos
	
func _getStickCurve(_path: Path3D,_offset: float):
	var _curve: Curve3D = _path.curve
	if(_offset <= 0.1 or _offset >= _curve.get_baked_length() -.1):
		return false
	else:
		return true
		
func _setUpDirection():
	if is_on_floor() and raycastGnd.is_colliding():
		up_direction = (raycastGnd.get_collision_normal() + lastUpDir) / 2
	else:
		up_direction = lastUpDir
		
func _process(delta):
	_inputHandler()
	if(playerState != PlayerState.FALL):
		_lerpVisTransform(delta, interpSpd)
	else:
		fallTimer -= delta
	if(playerState == PlayerState.GRIND):
		rbdChar.rotation.z = -balanceAngle
		rbdBoard.rotation.z = -balanceAngle
	if(playerState == PlayerState.LIP):
		rbdChar.rotation.x = -balanceAngle
		rbdBoard.rotation.x = -balanceAngle
	cameraPos.position = cameraPos.position.lerp(global_position, delta * 10)
	
func _lerpVisTransform(delta, speed):
	rbdChar.global_transform = rbdChar.transform.interpolate_with(global_transform, delta * speed)
	rbdChar.global_position = global_position
	rbdBoard.global_transform = rbdChar.global_transform
				
func _fall(fallReason, fallValue):
	print(fallReason + ": " + str(fallValue))
	playerState = PlayerState.FALL
	ingameUI._setFailView(true)
	fallTimer = 2.0
	rbdChar.freeze = false
	rbdChar.apply_impulse(velocity)
	rbdBoard.freeze = false
	rbdBoard.apply_impulse(velocity)
	
func _resetPlayer(pos):
	ingameUI._setFailView(false)
	up_direction = Vector3.UP
	velocity = Vector3.ZERO
	global_position = pos
	global_rotation =  Vector3(0,3.14/2,0)
	rbdChar.freeze = true
	rbdBoard.freeze = true
	playerState = PlayerState.RESET
	lastPlayerState = PlayerState.RESET
	balanceAngle = 0.0

func _inputHandler(): 	#handles player inputs
	input.x = int(Input.is_action_pressed('Left')) - int(Input.is_action_pressed('Right'))
	input.y = int(Input.is_action_pressed('Forward')) - int(Input.is_action_pressed('Backward'))
	input.z = int(Input.is_action_pressed('Jump'))
	inputTricks.x = int(Input.is_action_pressed('Grind'))
	inputTricks.y = int(Input.is_action_pressed('Revert'))
	inputTricks.z = int(Input.is_action_just_released('Jump'))
	if(input.y and playerState == PlayerState.FALL and fallTimer < 0.1):
		_resetPlayer(lastGroundPos + Vector3.UP * 5.0)

func _killOrthogonalVelocity(_xForm : Transform3D, _vel: Vector3): 	#remove orthogonal component of velocity
	var _fwdVel = _xForm.basis.z * _vel.dot(_xForm.basis.z)
	var _ortVel = _xForm.basis.x * _vel.dot(_xForm.basis.x)
	var _upVel = _xForm.basis.y  * _vel.dot(_xForm.basis.y)
	var _velocity = _fwdVel + _ortVel * 0.1 + _upVel
	return _velocity
	
func _killPipeOrthogonalVelocity(_vel: Vector3, _tangent: Vector3):
	var _newVel = _vel.dot(_tangent) * _tangent
	_newVel.y = _vel.y
	var _velocity = _newVel
	return _velocity

func _align(_xForm, _newUp): 	#align xform to up vector
	_xForm.basis.y = _newUp
	_xForm.basis.x = _xForm.basis.z.cross(-_newUp)
	_xForm.basis = _xForm.basis.orthonormalized()
	return _xForm

func _limitVelocity():
	if velocity.length() > maxVel:
		velocity = velocity.normalized() * maxVel
	
func _turnAround():
	global_rotate(xForm.basis.y, PI)
	
func _revertMotion(_normal):
	global_rotate(xForm.basis.y, PI)
	var _reflected = velocity.reflect(_normal)
	velocity = Vector3(_reflected.x, velocity.y, _reflected.z)
	
func _grindRevertMotion():
	pathDir *= -1
	pathVel *= -1

func _groundMovement(delta): 	#movement while grounded
	if playerState == PlayerState.GROUND:
		lastGroundPos = global_position
	if input.y < 0:
		velocity *= 0.95
		global_rotate(xForm.basis.y, input.x * rotKickturn * delta)
	else:
		global_rotate(xForm.basis.y, input.x * rot * delta)
	if input.y >= 0 and velocity.length() < maxVel/8:
		velocity +=xForm.basis.z * acc * 0.25
	if((input.z > 0 and velocity.length() <= maxVel and input.y != -1) or (input.z < 0 and velocity.length() >= -maxVel)):
		velocity += xForm.basis.z * input.z * acc
	if inputTricks.z > 0:
		velocity += Vector3.UP * jumpVel
		jumpTimer = 1.0
	velocity.y -= gravity * delta
	velocity = _killOrthogonalVelocity(xForm, velocity)

func _airMovement(delta): 	#movement while in air
	global_rotate(xForm.basis.y, input.x * rotJump * delta)
	velocity.y -= gravity * delta
	up_direction = lerp(up_direction,Vector3.UP, delta * upAlignSpd)
	
func _pipeSnapMovement(delta): 	#movement while snapped to a pipe
	global_rotate(xForm.basis.y, input.x * rotJump * delta)
	curveSnap = path.curve.sample_baked(pathOffset, true)
	pathOffset += pathVel * delta
	curveTangent = (_getPathTangent(path, pathOffset) * Vector3(1,0,1)).normalized()
	up_direction = _pipeSnapUpDir(curveTangent)
	position = Vector3(curveSnap.x, position.y, curveSnap.z)
	velocity.y -= gravity * delta
	velocity = _killPipeOrthogonalVelocity(velocity, curveTangent)
		
func _pipeSnapUpDir(_curveTangent): #calculate upvector while snapped to a pipe
	var _newUpDir = Vector3.UP.cross(_curveTangent)
	var _lastUpDir = lastUpDir
	if pipeSnapFlip:
		_newUpDir *= -1
	if(_newUpDir != Vector3.ZERO):
		return _newUpDir
	else:
		return _lastUpDir

func _pipeSnapAirMovement(delta):	#movement when snapped pipe is left in air
	global_rotate(xForm.basis.y, input.x * rotJump * delta)
	velocity.y -= gravity * delta

func _grindMovement(delta): 	#movement logic while grinding a rail
	#collision.disabled = true
	curveSnap = path.curve.sample_baked(pathOffset, true)
	pathOffset += pathVel * delta
	curveTangent = _getPathTangent(path, pathOffset)
	position = curveSnap
	up_direction = path.curve.sample_baked_up_vector(pathOffset)
	#rotation.y = atan2(curveTangent.x,curveTangent.z)
	look_at(global_position + curveTangent * pathDir, up_direction)
	if inputTricks.z:
		velocity = xForm.basis.z * abs(pathVel)
		velocity += Vector3.UP * inputTricks.z * jumpVel
		path = null
		return
	#balance logic
	balanceTime += 0.05 * delta
	balanceAngle += balanceMulti * delta * balanceDir * balanceTime
	velocity = xForm.basis.z * pathVel
	if(input.x != 0):
		balanceDir = int(input.x)
	ingameUI._setBalanceValue(-balanceAngle)

func _lipMovement(delta):
	#collision.disabled = true
	position = path.curve.sample_baked(pathOffset)
	up_direction = path.curve.sample_baked_up_vector(pathOffset)
	rotation.y = atan2(lipStartDir.x,lipStartDir.z)
	if(inputTricks.z):
		velocity = velocity.normalized() * -1
		playerState = PlayerState.AIR
		position += lipStartUp + Vector3.UP -lipStartDir * Vector3(1,0,1) * 0.1
		velocity = lipStartVel.normalized() * -1
		up_direction = Vector3.UP
		rotation.y = atan2(-lipStartDir.x,-lipStartDir.z)
	balanceTime += 0.05 * delta
	balanceAngle += balanceMulti * delta * balanceDir * balanceTime
	if(input.y != 0):
		balanceDir = int(-input.y)
	ingameUI._setBalanceValue(-balanceAngle)

func _randomizeBalance():
	balanceTime = 1.0
	balanceAngle = 0.0
	var rand = randf()
	if (rand >= 0.5):
		balanceDir = 1
	else:
		balanceDir = -1
		balanceAngle = 0

func _initPlayer():
	pass
	
func _checkTurnAround():
	if _forwardVelocity().length() < 1.0:
		return
	var revertCheck = velocity.normalized().dot(xForm.basis.z)
	if revertCheck < 0:
		_turnAround()

func _checkRevertMotion():
	if raycastFwd.is_colliding():
		_revertMotion(raycastFwd.get_collision_normal())
	pass

func _checkGrindRevertMotion():
	if raycastFwd.is_colliding():
		_grindRevertMotion()
	pass
		
func _debugPlayerState():
	#debug logic to print the player state only on change
	if(playerState != lastPlayerState):
		print(PlayerState.find_key(playerState))
	lastPlayerState = playerState

func _jumpTimer(delta):
	if jumpTimer > 0:
		jumpTimer -= delta
		
func _forwardVelocity():
	return velocity.slide(up_direction)
	
func _fallCheck():
	if playerState == PlayerState.GRIND or playerState == PlayerState.LIP:
		if (balanceAngle > PI /4 or balanceAngle < -PI /4):
			_fall("balance issues", balanceAngle)
			return
	#if is_on_floor():
	#	var _check = abs(_forwardVelocity().normalized().dot(xForm.basis.z))
	#	if _check < 0.25 and _check != 0 and abs(_forwardVelocity().length()) > 1:
	#		_fall("Ground", _check)
	#		return
	#if is_on_wall():
	#	if lastVel.length() > 10:
	#		_fall("Wall", lastVel.length())
	#		return
	
