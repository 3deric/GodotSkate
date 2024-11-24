extends CharacterBody3D

#global movement constants
const acc :float= 0.15
const jumpVel :float = 10.0
const rot :float= 2.0
const rotKickturn : float = 4.0
const rotJump :float= 7.0
const maxVel :float = 25.0
const gravity :float = 20.0
const balanceMulti : float= 1.0
const pipesnapOffset :float = 0.025
const upAlignSpd :float = 5.0
const interpSpd: float = 15.0

#global movement variables
var xForm = null
var dir : Vector3= Vector3.ZERO #current direction of motion
var lastDir : Vector3 = Vector3.ZERO #direction of last frame for falling check
var lastGroundPos : Vector3 = Vector3.ZERO
var lastPhysicsPosition : Vector3 = Vector3.ZERO
var fallTimer : float = 0.0
var lastUpDir : Vector3 = Vector3.ZERO
var pipeSnapFlip : bool = false
var rampPos : Vector3 = Vector3.ZERO
var isOnFloor: bool = false
var isOnWall: bool = false
var jumpTimer : float = 0.0

#global object references
@onready var rbdBoard: RigidBody3D = get_node('RBDBoard')
@onready var rbdChar: RigidBody3D = get_node('RBDCharacter')
@onready var area: Area3D = get_node('Area3D')
@onready var collision: CollisionShape3D = get_node('CollisionShape3D')
@onready var raycast: RayCast3D = get_node('RayCast3D')
@export var camera: Camera3D = null
@export var cameraPos: Node3D = null
@export var ingameUI: Control = null

#Enums for player state and collision detection
enum PlayerState {RESET, GROUND, PIPE, PIPESNAP, PIPESNAPAIR, AIR, FALL, GRIND, LIP, MANUAL}
#enum CollLayer {AIR, FLOOR, PIPE}
var playerState = PlayerState.RESET
var lastPlayerState = PlayerState.RESET
#var lastCollLayer = CollLayer.AIR

#input variables
var input : Vector3 = Vector3.ZERO #input values
var inputTricks : Vector3 = Vector3.ZERO #input values for tricks

#grind and lip trick variables
var balanceTime  : float = 1.0
var balanceAngle : float = 0.0 #value between - pi and pi to balance the player on grinds, lips and manuals
var balanceDir : int = 0 #defines balance direction based on last input
var path: Path3D = null
var pathPosition: float = -1
var pathLength: float = -1
var pathDir: int = 0
var pathVelocity: Vector3 = Vector3.ZERO
var lipStartUp: Vector3 = Vector3.ZERO
var lipStartVel: Vector3 = Vector3.ZERO
var lipStartDir: Vector3 = Vector3.ZERO
var curveSnap = Vector3.ZERO
var curveTangent = Vector3.ZERO
var pathTanDir : int = 1

func _ready():
	_initPlayer()
	_resetPlayer(Vector3.UP * 5.0 + Vector3(7,0,0))

func _physics_process(delta):
	xForm = global_transform
	_debugPlayerState()
	_jumpTimer(delta)
	_surfaceCheck()
	_playerState()
	match playerState:
		PlayerState.FALL:
			return
		PlayerState.GROUND, PlayerState.PIPE:
			_groundMovement(delta)	
		PlayerState.AIR:
			_airMovement(delta)	
		PlayerState.PIPESNAP:
			_pipeSnapMovement(delta)
		PlayerState.PIPESNAPAIR:
			_pipeSnapAirMovement(delta)	
		PlayerState.GRIND:
			_grindMovement(delta)
		PlayerState.LIP:
			_lipMovement(delta)	
	global_transform = _align(global_transform, up_direction) 
	lastPhysicsPosition = global_position
	lastUpDir = up_direction
	_setUpDirection()	
	move_and_slide()
	if jumpTimer < 0.5 and raycast.is_colliding():
		apply_floor_snap()
	_fallCheck()

func _playerState():	
	if (playerState == PlayerState.FALL):	#dont change the state if fallen
		return
	
	if(playerState == PlayerState.GRIND or playerState == PlayerState.LIP):
		ingameUI._setBalanceView(true)
		collision.disabled = true
		if !_getStickCurve(path,  global_position):
			playerState = PlayerState.AIR
			return
		return
	else:
		ingameUI._setBalanceView(false)
		collision.disabled = false
		
	if(playerState == PlayerState.PIPESNAP):
		if !_getStickCurve(path,  global_position):
			playerState = PlayerState.PIPESNAPAIR
			curveSnap = _getClosestCurvePoint(path, global_position)
			curveTangent = _getPathTangent(path, global_position)
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
		pathLength = path.curve.get_baked_length()
		if inputTricks.x == 1 and playerState != PlayerState.GRIND:
			pathPosition = _getClosestCurveOffset(path, position)
			curveTangent = _getPathTangent(path, position)
			if(curveTangent == Vector3.ZERO):
				return
			pathDir = _getPathDir(curveTangent)
			_randomizeBalance()
			if(pathDir != 0):
				playerState = PlayerState.GRIND		
				return
			if(pathDir == 0 and playerState != PlayerState.PIPESNAP):
				playerState = PlayerState.LIP
				lipStartUp = up_direction
				lipStartVel = velocity
				var tangent = _getPathTangent(path, global_position)
				var dir = tangent.cross(Vector3(0,1,0))
				var dirCheck = (_getClosestCurvePoint(path, position) - lastGroundPos).normalized()
				if(dirCheck.dot(dir) < 0):
					dir*=-1
				lipStartDir = dir
				return
		
	var collInfo = null
	if raycast.is_colliding():
		collInfo = raycast.get_collider()
	if (playerState != PlayerState.GRIND and playerState != PlayerState.LIP):
		if isOnFloor:
			if collInfo:
				if collInfo.is_in_group('pipe'):
					playerState = PlayerState.PIPE	
				else:
					playerState = PlayerState.GROUND
					lastGroundPos = global_position
					path = null	
				return
	if !isOnFloor:	#behavior while in air, or sticked to a pipe
		if(abs(xForm.basis.z.dot(Vector3.UP)) > 0.5 and playerState == PlayerState.PIPE and inputTricks.z == 0):
			if path != null:
				playerState = PlayerState.PIPESNAP
				var curveTangent = _getPathTangent(path, global_position)
				var dir = curveTangent.cross(Vector3(0,1,0))
				var dirCheck = (_getClosestCurvePoint(path, position) - lastGroundPos).normalized()
				if(dirCheck.dot(dir) < 0):
					pipeSnapFlip = true
				else:
					pipeSnapFlip = false		
				rampPos = global_position - get_last_motion() - Vector3.UP * 0.2
		if(playerState != PlayerState.PIPESNAP and playerState != PlayerState.PIPESNAPAIR):
			playerState = PlayerState.AIR				
	
func _getPathTangent(path: Path3D, pos: Vector3): #returns the curve tangent
	var curve: Curve3D = path.curve	
	var pathTransform: Transform3D = path.global_transform 
	var lastLocalPos: Vector3 = lastPhysicsPosition * pathTransform
	var lastOffset: float = curve.get_closest_offset(lastLocalPos)
	var lastCurvePos: Vector3 = curve.sample_baked(lastOffset, true)
	lastCurvePos = pathTransform * lastCurvePos
	var localPos: Vector3 = pos * pathTransform
	var offset: float = curve.get_closest_offset(localPos)
	var curvePos: Vector3 = curve.sample_baked(offset, true)
	curvePos = pathTransform * curvePos
	var tangent = (curvePos - lastCurvePos).normalized()
	if(offset - lastOffset < 0):
		tangent *= Vector3(-1,-1,-1)
	return tangent
	
func _getPathDir(tangent: Vector3): #direction along curve based on start pos
	var dir = tangent.dot(velocity.normalized())
	var treshold = 0.2
	if(dir > treshold):
		return  -1
	if(dir < -treshold):
		return 1
	else:
		return 0

func _getClosestCurvePoint(path: Path3D,pos: Vector3):
	var curve: Curve3D = path.curve
	var pathTransform: Transform3D = path.global_transform  # target position to local space
	var localPos: Vector3 = pos * pathTransform
	var offset: float = curve.get_closest_offset(localPos)
	var curvePos: Vector3 = curve.sample_baked(offset, true)
	curvePos = pathTransform * curvePos   # transform back to world space
	return curvePos

func _getClosestCurveOffset(path: Path3D, pos: Vector3):
	var curve: Curve3D = path.curve
	var pathTransform: Transform3D = path.global_transform
	var localPos: Vector3 = pos * pathTransform
	var offset: float = curve.get_closest_offset(localPos)
	return offset
	
func _getPositionOnCurve(path: Path3D, offset):
	var curve: Curve3D = path.curve
	var curvePos: Vector3 = curve.sample_baked(offset, true)
	return curvePos
	
func _getStickCurve(path: Path3D,pos: Vector3):
	var curve: Curve3D = path.curve
	var pathTransform: Transform3D = path.global_transform
	var localPos: Vector3 = pos * pathTransform
	var offset: float = curve.get_closest_offset(localPos)
	if(offset <= 0.1 or offset >= curve.get_baked_length() -.1):
		return false
	else:
		return true
		
func _setUpDirection():
	if isOnFloor:
		up_direction = raycast.get_collision_normal()
	else:
		up_direction = lastUpDir	
	if playerState == PlayerState.AIR:
		up_direction = Vector3.UP
		
func _surfaceCheck():
	if playerState == PlayerState.FALL:
		return
	isOnFloor = is_on_floor()
	isOnWall = is_on_wall() or is_on_ceiling()

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
	isOnFloor = false
	isOnWall = false
	up_direction = Vector3.UP
	velocity = Vector3.ZERO
	global_position = pos
	global_rotation =  Vector3(0,3.14/2,0)
	rbdChar.freeze = true
	rbdBoard.freeze = true
	playerState = PlayerState.RESET
	balanceAngle = 0.0

func _inputHandler(): 	#handles player inputs
	input.x = int(Input.is_action_pressed('Left')) - int(Input.is_action_pressed('Right'))
	input.y = int(Input.is_action_pressed('Forward')) - int(Input.is_action_pressed('Backward'))
	input.z = int(Input.is_action_pressed('Jump'))
	inputTricks.x = int(Input.is_action_just_pressed('Grind'))
	inputTricks.y = int(Input.is_action_pressed('Revert'))
	inputTricks.z = int(Input.is_action_just_released('Jump'))
	if(input.y and playerState == PlayerState.FALL):
		_resetPlayer(Vector3.UP * 5.0 + Vector3(7,0,0))

func _killOrthogonalVelocity(xForm : Transform3D, vel: Vector3): 	#remove orthogonal component of velocity
	var fwdVel = xForm.basis.z * vel.dot(xForm.basis.z)
	var ortVel = xForm.basis.x * vel.dot(xForm.basis.x)
	var upVel = xForm.basis.y  * vel.dot(xForm.basis.y)
	velocity = fwdVel + ortVel * 0.25 + upVel
	return velocity
	
func _killPipeOrthogonalVelocity(vel: Vector3, tangent: Vector3):
	var newVel = vel.dot(tangent) * tangent
	newVel.y = vel.y
	velocity = newVel
	return velocity

func _align(xform, newUp): 	#align xform to up vector
	xform.basis.y = newUp
	xform.basis.x = -xform.basis.z.cross(newUp)
	xform.basis = xform.basis.orthonormalized()
	return xform

func _limitVelocity():
	if velocity.length() > maxVel:
		velocity = velocity.normalized() * maxVel
	
func _revertMotion():
	rotate_object_local(Vector3.UP, PI)

func _groundMovement(delta): 	#movement while grounded
	_checkRevertMotion()
	#global_position = raycast.get_collision_point()
	if input.y < 0:
		velocity *= 0.95
		rotate_object_local(Vector3.UP, input.x * rotKickturn * delta)
	else:
		rotate_object_local(Vector3.UP, input.x * rot * delta)
	if input.y >= 0 and velocity.length() < maxVel/8:
		velocity +=xForm.basis.z * acc * 0.25
	if((input.z > 0 and velocity.length() <= maxVel and input.y != -1) or (input.z < 0 and velocity.length() >= -maxVel)):
		velocity += xForm.basis.z * input.z * acc
	if inputTricks.z > 0:
		velocity += xForm.basis.y * jumpVel
		jumpTimer = 1.0
	velocity.y -= gravity * delta
	_killOrthogonalVelocity(xForm, velocity)

func _airMovement(delta): 	#movement while in air
	rotate_object_local(Vector3.UP, input.x * rotJump * delta)
	velocity.y -= gravity * delta
	up_direction = lerp(up_direction,Vector3.UP, delta * upAlignSpd)
	
func _pipeSnapMovement(delta): 	#movement while snapped to a pipe
	rotate_object_local(Vector3.UP, input.x * rotJump * delta)
	curveSnap = _getClosestCurvePoint(path, global_position)
	curveTangent = _getPathTangent(path, global_position)
	_pipeSnapUpDir(curveTangent)
	position = Vector3(curveSnap.x, position.y, curveSnap.z) + up_direction * pipesnapOffset
	velocity.y -= gravity * delta
	velocity = _killPipeOrthogonalVelocity(velocity, curveTangent)
	if (!_getStickCurve(path, global_position)):
		pass

func _pipeSnapUpDir(curveTangent): #calculate upvector while snapped to a pipe
	var newUpDir = Vector3.UP.cross(curveTangent)
	if pipeSnapFlip:
		newUpDir *= -1
	if(newUpDir != Vector3.ZERO):
		up_direction = newUpDir
	else:
		up_direction = lastUpDir

func _pipeSnapAirMovement(delta):	#movement when snapped pipe is left in air
	rotate_object_local(Vector3.UP, input.x * rotJump * delta)
	velocity.y -= gravity * delta

func _grindMovement(delta): 	#movement logic while grinding a rail
	collision.disabled = true
	var grindVel = _forwardVelocity().length() * 0.99
	if grindVel < 0.1:
		grindVel = 1.0
	up_direction = Vector3.UP
	pathPosition -= grindVel * pathDir * delta
	position = _getPositionOnCurve(path, pathPosition) + up_direction * 0.0
	curveTangent = _getPathTangent(path, global_position) * -pathDir
	pathVelocity = curveTangent  * grindVel
	rotation.y = atan2(curveTangent.x,curveTangent.z)
	if(inputTricks.z):
		velocity = xForm.basis.z * grindVel
		velocity += xForm.basis.y * inputTricks.z * jumpVel
		playerState = PlayerState.AIR
		path = null
		return
	if (!_getStickCurve(path, global_position)):
		playerState = PlayerState.AIR
		velocity = xForm.basis.z * grindVel
		path = null
		return
	#balance logic
	balanceTime += 0.05 * delta
	balanceAngle += balanceMulti * delta * balanceDir * balanceTime
	if(input.x != 0):
		balanceDir = input.x
	ingameUI._setBalanceValue(-balanceAngle)
	if (balanceAngle > PI /4 or balanceAngle < -PI /4):
		velocity = curveTangent * grindVel
		_fall("balance issues", balanceAngle)
		return

func _lipMovement(delta): 
	collision.disabled = true
	position = _getPositionOnCurve(path, pathPosition)
	up_direction =Vector3.UP
	curveTangent = _getPathTangent(path, global_position)
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
		balanceDir = -input.y
	ingameUI._setBalanceValue(-balanceAngle)
	if (balanceAngle > PI /4 or balanceAngle < -PI /4):
		velocity = Vector3.DOWN
		_fall("balance issues", balanceAngle)
		return

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

func _checkRevertMotion():
	if velocity.length() < 0.5:
		return
	var revertCheck = velocity.normalized().dot(xForm.basis.z)
	if revertCheck < 0:
		_revertMotion()
		
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
		return
	if isOnFloor:
		var fallCheck = (abs(velocity.slide(up_direction).normalized().dot(xForm.basis.z)))
		if fallCheck < 0.5 and fallCheck != 0:
			_fall("Ground", fallCheck)
			return
	if isOnWall:
		if velocity.slide(up_direction).length() > 5:
			_fall("Wall", velocity.slide(up_direction).length())
			return
