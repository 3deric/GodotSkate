extends CharacterBody3D

#global movement constants
const acc :float= 0.2
const jumpVel :float = 10.0
const rot :float= 2.0
const rotJump :float= 7.0
const maxVel :float = 25.0
const gravity :float = 25.0
const balanceMulti : float= 1.0
const pipesnapOffset :float = 0.15
const upAlignSpd :float = 5.0

#global movement variables
var xForm = null
var dir : Vector3= Vector3.ZERO #current direction of motion
var lastDir : Vector3 = Vector3.ZERO #direction of last frame for falling check
var lastGroundPos : Vector3 = Vector3.ZERO
var lastPhysicsPosition : Vector3 = Vector3.ZERO
var fallTimer : float = 0.0
var lastUpDir : Vector3 = Vector3.ZERO
var lastVel : Vector3 = Vector3.ZERO
var pipeSnapFlip : bool = false
var rampPos : Vector3 = Vector3.ZERO
var groundNormal : Vector3 = Vector3.RIGHT

#global object references
@onready var raycast : RayCast3D = get_node('RayCast3D')
@onready var rbdBoard: RigidBody3D = get_node('RBDBoard')
@onready var rbdChar: RigidBody3D = get_node('RBDCharacter')
@onready var area: Area3D = get_node('Area3D')
@onready var collision: CollisionShape3D = get_node('CollisionShape3D')
@export var camera: Camera3D = null
@export var cameraPos: Node3D = null
@export var ingameUI: Control = null

#Enums for player state and collision detection
enum PlayerState {RESET, GROUND, PIPE, PIPESNAP, PIPESNAPAIR, AIR, FALL, GRIND, LIP, MANUAL}
enum CollLayer {AIR, FLOOR, PIPE}
var playerState = PlayerState.RESET
var lastPlayerState = PlayerState.RESET
var lastCollLayer = CollLayer.AIR

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
	_resetPlayer(Vector3.UP * 5.0)

func _physics_process(delta):
	xForm = global_transform
	_debugPlayerState()
	_inputHandler()	
	_playerState()
	match playerState:
		PlayerState.FALL:
			#dont execute any movement logic if player has fallen
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
	#align upvector
	global_transform = _align(global_transform, up_direction) 
	#set player parameters for next physics iteration
	lastPhysicsPosition = global_position
	lastUpDir = up_direction
	lastVel = velocity
	_limitVelocity()
	move_and_slide()

func _playerState():	
	if (playerState == PlayerState.FALL):
		#dont change the state if player is fallen
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
			#get closest ramp or rail
			#loop through all ramps / rails
			#check which distance is the lowest
			#use the ramp / rail with the lowest distance
			#usally there should not be more then 2 ramps / rails in close proximity
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
	if get_slide_collision_count() != 0:
		collInfo = get_slide_collision(0)
	var collLayer = CollLayer.AIR
		
	
	if (playerState != PlayerState.GRIND and playerState != PlayerState.LIP):
		if is_on_floor():
			path = null
			var fallCheck = (abs(velocity.normalized().dot(xForm.basis.z)))
			if(fallCheck < 0.75 and fallCheck != 0 and velocity.length() > 1.0):
				_fall("floor fall", fallCheck)
				return
			if collInfo:
				if collInfo.get_collider(0).is_in_group('floor'):
					playerState = PlayerState.GROUND
					lastGroundPos = global_position
				if collInfo.get_collider(0).is_in_group('pipe'):
					playerState = PlayerState.PIPE
				groundNormal = (collInfo.get_normal() * Vector3(1,0,1)).normalized()			
			
		if is_on_wall():
			if(lastVel.length() > 10):
				playerState = PlayerState.FALL
				_fall("hit the wall", lastVel)
				return
	
	if !is_on_floor():	
		#behavior while in air, or sticked to a pipe
		if(abs(xForm.basis.z.dot(Vector3.UP)) > 0.5 and playerState == PlayerState.PIPE and inputTricks.z == 0):
			if path != null:
				playerState = PlayerState.PIPESNAP
				var tangent = _getPathTangent(path, global_position)
				var dir = tangent.cross(Vector3(0,1,0))
				var dirCheck = (_getClosestCurvePoint(path, position) - lastGroundPos).normalized()
				if(dirCheck.dot(dir) < 0):
					pipeSnapFlip = true
				else:
					pipeSnapFlip = false
				
				rampPos = global_position - get_last_motion() - Vector3.UP * 0.2
		if(playerState != PlayerState.PIPESNAP and playerState != PlayerState.PIPESNAPAIR):
			playerState = PlayerState.AIR			
	#set current collision layer als last collision layer for next physics cycle	
	lastCollLayer = collLayer
	
func _getPathTangent(path: Path3D, pos: Vector3):
	#returns the curve tangent
	#interpolates between two close points on the curve to generate tangent direction
	var curve: Curve3D = path.curve	
	#sample curve for last physics iteration
	var pathTransform: Transform3D = path.global_transform
	var lastLocalPos: Vector3 = lastPhysicsPosition * pathTransform
  	# get the nearest offset on the curve
	var lastOffset: float = curve.get_closest_offset(lastLocalPos)
  	# get the local position at this offset
	var lastCurvePos: Vector3 = curve.sample_baked(lastOffset, true)
  	# transform it back to world space
	lastCurvePos = pathTransform * lastCurvePos
	#sample curve for current physics iteraiton
	var localPos: Vector3 = pos * pathTransform
  	# get the nearest offset on the curve
	var offset: float = curve.get_closest_offset(localPos)
  	# get the local position at this offset
	var curvePos: Vector3 = curve.sample_baked(offset, true)
  	# transform it back to world space
	curvePos = pathTransform * curvePos
	var tangent = (curvePos - lastCurvePos).normalized()
	if(offset - lastOffset < 0):
		tangent *= Vector3(-1,-1,-1)
	return tangent
	
func _getPathDir(tangent: Vector3):
	#function to get direction along the curve, based on the starting direction
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
 	# transform the target position to local space
	var pathTransform: Transform3D = path.global_transform
	var localPos: Vector3 = pos * pathTransform
  # get the nearest offset on the curve
	var offset: float = curve.get_closest_offset(localPos)
  # get the local position at this offset
	var curvePos: Vector3 = curve.sample_baked(offset, true)
  # transform it back to world space
	curvePos = pathTransform * curvePos
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
	if is_on_floor():
		up_direction = raycast.get_collision_normal()
	else:
		up_direction = lastUpDir		
	if playerState == PlayerState.AIR:
		up_direction = Vector3.UP

func _process(delta):
	#to do: interpolate rotation to get smoother motion on slopesm, while player is grounded
	if(playerState != PlayerState.FALL):
		rbdChar.global_transform = global_transform
		rbdBoard.global_transform = global_transform
		#rbdChar.rotation.x = lerpf(rbdChar.rotation.x, rotation.x, delta)
		#rbdBoard.rotation.x = lerpf(rbdBoard.rotation.x, rotation.x, delta)
	else:
		fallTimer -= delta
	if(playerState == PlayerState.GRIND):
		rbdChar.rotation.z = -balanceAngle
		rbdBoard.rotation.z = -balanceAngle
		
	if(playerState == PlayerState.LIP):
		rbdChar.rotation.x = -balanceAngle
		rbdBoard.rotation.x = -balanceAngle
		
	cameraPos.position = cameraPos.position.lerp(global_position, delta * 10)
				
func _fall(fallReason, fallValue):
	print(fallReason + ": " + str(fallValue))
	playerState = PlayerState.FALL
	lastVel = Vector3.ZERO
	ingameUI._setFailView(true)
	fallTimer = 2.0
	rbdChar.freeze = false
	rbdChar.apply_impulse(velocity)
	rbdBoard.freeze = false
	rbdBoard.apply_impulse(velocity)
	
func _resetPlayer(pos):
	if fallTimer > 0:
		return
	ingameUI._setFailView(false)
	up_direction = Vector3.UP
	velocity = Vector3.ZERO
	global_position = pos + Vector3.UP
	rbdChar.freeze = true
	rbdBoard.freeze = true
	playerState = PlayerState.RESET
	balanceAngle = 0.0

func _inputHandler():
	#handles player inputs
	#resetting of player happens by moving forward when fallen
	#todo: add more trick inputs
	input.x = int(Input.is_action_pressed('Left')) - int(Input.is_action_pressed('Right'))
	input.y = int(Input.is_action_pressed('Forward')) - int(Input.is_action_pressed('Backward'))
	input.z = int(Input.is_action_pressed('Jump'))
	inputTricks.x = int(Input.is_action_pressed('Grind'))
	inputTricks.y = int(Input.is_action_pressed('Revert'))
	inputTricks.z = int(Input.is_action_just_released('Jump'))
	if(input.z and playerState == PlayerState.FALL):
		_resetPlayer(lastGroundPos)

func _killOrthogonalVelocity(xForm, vel):
	#remove orthogonal component of velocity
	var fwdVel = xForm.basis.z * vel.dot(xForm.basis.z)
	var ortVel = xForm.basis.x * vel.dot(xForm.basis.x)
	var upVel = xForm.basis.y  * vel.dot(xForm.basis.y)
	velocity = fwdVel + ortVel * 0.25 + upVel
	return velocity
	
func _killPipeOrthogonalVelocity(vel, tangent):
	var newVel = vel.dot(tangent) * tangent
	newVel.y = vel.y
	velocity = newVel
	return velocity

func _align(xform, newUp):
	#align xform to up vector
	xform.basis.y = newUp
	xform.basis.x = -xform.basis.z.cross(newUp)
	xform.basis = xform.basis.orthonormalized()
	return xform

func _limitVelocity():
	if velocity.length() > maxVel:
		velocity = velocity.normalized() * maxVel
	
func _revertMotion():
	#revert logic
	#rotation.y = atan2(-velocity.normalized().x,-velocity.normalized().z)
	pass

func _groundMovement(delta):
	#movement while grounded
	_setUpDirection()		
	if((input.z > 0 and velocity.length() <= maxVel) or (input.z < 0 and velocity.length() >= -maxVel)):
		velocity += xForm.basis.z * input.z * acc
		#deceleration
	else:
		velocity *= 0.98	
		#jump acceleration
	
	if(inputTricks.y >0):
		_revertMotion()
	
	velocity += xForm.basis.y * inputTricks.z * jumpVel
	rotate_object_local(Vector3.UP, input.x * rot * delta)
	#apply gravity
	velocity.y -= gravity * delta	
	_killOrthogonalVelocity(xForm, velocity)

func _airMovement(delta):
	#movement while in air
	rotate_object_local(Vector3.UP, input.x * rotJump * delta)
	velocity.y -= gravity * delta
	up_direction = lerp(up_direction,Vector3.UP, delta * upAlignSpd)
	
func _pipeSnapMovement(delta):
	#movement while snapped to a pipe
	rotate_object_local(Vector3.UP, input.x * rotJump * delta)
	curveSnap = _getClosestCurvePoint(path, global_position)
	curveTangent = _getPathTangent(path, global_position)
	var newUpDir = Vector3.UP.cross(curveTangent)
	if pipeSnapFlip:
		newUpDir *= -1
	if(newUpDir != Vector3.ZERO):
		up_direction = newUpDir
	else:
		up_direction = lastUpDir
	position = Vector3(curveSnap.x, position.y, curveSnap.z) + up_direction * pipesnapOffset
	velocity.y -= gravity * delta
	velocity = _killPipeOrthogonalVelocity(velocity, curveTangent)
	if (!_getStickCurve(path, global_position)):
		pass

func _pipeSnapAirMovement(delta):
	#movement when snapped pipe is left in air
	rotate_object_local(Vector3.UP, input.x * rotJump * delta)
	velocity.y -= gravity * delta

func _grindMovement(delta):
	#movement logic while grinding a rail
	#disable collision detection while grinding
	collision.disabled = true
	var grindVel = velocity.length() * 0.99
	up_direction = Vector3.UP
	pathPosition -= grindVel * pathDir * delta
	position = _getPositionOnCurve(path, pathPosition) + up_direction * 0.0
	curveTangent = _getPathTangent(path, global_position) * -pathDir
	pathVelocity = curveTangent  * grindVel
	rotation.y = atan2(curveTangent.x,curveTangent.z)
	if(inputTricks.z):
		velocity = curveTangent * grindVel
		velocity += xForm.basis.y * inputTricks.z * jumpVel
		playerState = PlayerState.AIR
	if (!_getStickCurve(path, global_position)):
		velocity = curveTangent  * grindVel
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
	#Lip Logic
	#disable collision detection while grinding
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
	#balance logic
	balanceTime += 0.05 * delta
	balanceAngle += balanceMulti * delta * balanceDir * balanceTime
	if(input.y != 0):
		balanceDir = -input.y
		#to do fix updirection and alignment after lip trick is done
	ingameUI._setBalanceValue(-balanceAngle)
	if (balanceAngle > PI /4 or balanceAngle < -PI /4):
		#velocity = Vector3.DOWN
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
		#reset balance angle once grind or lip starts
		balanceAngle = 0

func _initPlayer():
	raycast = $RayCast3D
		
func _debugPlayerState():
	#debug logic to print the player state only on change
	if(playerState != lastPlayerState):
		print(PlayerState.find_key(playerState))
	lastPlayerState = playerState	
