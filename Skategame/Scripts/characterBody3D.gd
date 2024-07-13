extends CharacterBody3D

const acc = 0.2
const jumpVel = 10.0
const rot = 2.0
const rotJump = 7.0
const maxVel = 25.0
const gravity = 25.0
const maxBounces = 5
const balanceMulti= 1.0

enum PlayerState {RESET, GROUND, PIPE, PIPESNAP, AIR, FALL, GRIND, LIP, MANUAL}

var input = Vector3.ZERO #input values
var inputTricks = Vector3.ZERO #input values for tricks
var dir = Vector3.ZERO #current direction of motion
var lastDir = Vector3.ZERO #direction of last frame for falling check
var xForm = null
var balanceAngle = 0.0 #value between - pi and pi to balance the player on grinds, lips and manuals
var balanceDir = 0 #defines balance direction based on last input
var fallTimer = 0.0
var lastPhysicsPosition = Vector3.ZERO
var curveSnap = Vector3.ZERO
var curveTangent = Vector3.ZERO
var playerState = PlayerState.RESET
var lastPlayerState = PlayerState.RESET
var lastGroundPos = Vector3.ZERO
var lastUpDir = Vector3.ZERO
var rampPos = Vector3.ZERO
var groundNormal = Vector3.RIGHT
var lastCollLayer = 0
var path: Path3D = null
var pathPosition: float = -1
var pathLength: float = -1
var pathDir: int = 0
var pathVelocity: Vector3 = Vector3.ZERO
var lipStartUp: Vector3 = Vector3.ZERO
var lipStartPos: Vector3 = Vector3.ZERO
var lipStartVel: Vector3 = Vector3.ZERO
var lipStartDir: Vector3 = Vector3.ZERO

@onready var rbdBoard: RigidBody3D = get_node("RBDBoard")
@onready var rbdChar: RigidBody3D = get_node("RBDCharacter")
@onready var area: Area3D = get_node("Area3D")
@onready var collision: CollisionShape3D = get_node("CollisionShape3D")
@export var camera: Camera3D = null
@export var cameraPos: Node3D = null
@export var ingameUI: Control = null

func _ready():
	_resetPlayer(Vector3.UP * 5.0)

func _physics_process(delta):
	xForm = global_transform
	_inputHandler()	
	_playerState()
	#debug logic to print the player state only on change
	if(playerState != lastPlayerState):
		print(PlayerState.find_key(playerState))
	lastPlayerState = playerState	
	if (playerState == PlayerState.FALL):
		velocity *= 0.95
		move_and_slide()
		return		
	if (playerState == PlayerState.GROUND):
		lastGroundPos = global_position	
	#behaviour while grounded
	if (playerState == PlayerState.GROUND or playerState == PlayerState.PIPE):	
		_setUpDirection()		
		if((input.y > 0 and velocity.length() <= maxVel) or (input.y < 0 and velocity.length() >= -maxVel)):
			velocity += xForm.basis.z * input.y * acc
		#deceleration
		else:
			velocity *= 0.98	
		#jump acceleration
		velocity += xForm.basis.y * input.z * jumpVel
		rotate_object_local(Vector3.UP, input.x * rot * delta)
		#apply gravity
		velocity.y -= gravity * delta	
		_killOrthogonalVelocity(xForm, velocity)
	#movement while not grounded
	if (playerState == PlayerState.AIR):
		rotate_object_local(Vector3.UP, input.x * rotJump * delta)
		velocity.y -= gravity * delta
		up_direction = Vector3.UP	
	#movement while snapped to pipe	
	if (playerState == PlayerState.PIPESNAP):
		rotate_object_local(Vector3.UP, input.x * rotJump * delta)
		curveSnap = _getClosestCurvePoint(path, global_position)
		curveTangent = _getPathTangent(path, global_position)
		var newUpDir = Vector3.UP.cross(curveTangent)
		if(newUpDir != Vector3.ZERO):
			up_direction = newUpDir
		else:
			up_direction = lastUpDir
		position = Vector3(curveSnap.x, position.y, curveSnap.z) + up_direction * 0.25
		velocity.y -= gravity * delta
		if (!_getStickCurve(path, global_position)):
			playerState = PlayerState.AIR		
	
	if (playerState == PlayerState.GRIND):
		#disable collision detection while grinding
		collision.disabled = true
		var grindVel = velocity.length() * 0.99
		up_direction = Vector3.UP
		pathPosition -= grindVel * pathDir * delta
		position = _getPositionOnCurve(path, pathPosition) + up_direction * 0.1
		curveTangent = _getPathTangent(path, global_position) * -pathDir
		pathVelocity = curveTangent  * grindVel
		rotation.y = atan2(curveTangent.x,curveTangent.z)
		if(input.z):
			velocity = curveTangent * grindVel
			velocity += xForm.basis.y * input.z * jumpVel
			playerState = PlayerState.AIR
			#collision.disabled = false
		if (!_getStickCurve(path, global_position)):
			velocity = curveTangent  * grindVel
			playerState = PlayerState.AIR
			#collision.disabled = false
		
		#balance logic
		balanceAngle += balanceMulti * delta * balanceDir
		if(input.x != 0):
			balanceDir = input.x
		ingameUI._setBalanceValue(-balanceAngle)
		if (balanceAngle > PI /2 or balanceAngle < -PI /2):
			velocity = curveTangent * grindVel
			_fall()
			return
		
	if (playerState == PlayerState.LIP):
		position = _getPositionOnCurve(path, pathPosition)
		up_direction =Vector3.UP
		curveTangent = _getPathTangent(path, global_position) * -pathDir
		rotation.y = atan2(lipStartDir.x,lipStartDir.z)
		if(input.z):
			velocity = velocity.normalized() * -1
			playerState = PlayerState.AIR	
			position += lipStartUp * 0.5
			velocity = lipStartVel.normalized() * Vector3(-1,-1,-1)		
			up_direction = Vector3.UP
			rotation.y = atan2(-lipStartDir.x,-lipStartDir.z)
		#balance logic
		balanceAngle += balanceMulti * delta * balanceDir
		if(input.y != 0):
			balanceDir = -input.y
			#to do fix updirection and alignment after lip trick is done
		ingameUI._setBalanceValue(-balanceAngle)
		if (balanceAngle > PI /2 or balanceAngle < -PI /2):
			velocity = Vector3.DOWN
			_fall()
		#return
	
	#align upvector with up_direction
	global_transform = _align(global_transform, up_direction)
	#set player parameters for next physics iteration
	lastPlayerState = playerState
	lastPhysicsPosition = global_position
	lastUpDir = up_direction
	#slow down the player if its too fast
	if velocity.length() > maxVel:
		velocity = velocity.normalized() * maxVel
	if(playerState != PlayerState.GRIND and playerState != PlayerState.LIP):
		#apply movement
		#only while not grinding or in lip mode
		#would result in jitter otherwise
		move_and_slide()

func _playerState():
	#function that handles player states
	#player states mostly get set here
	#some state changes happen in physcis update
	#collision detection for ramps and rails
	#ramp and rail curves get assigned to a variable
	#curve direction is assigned to a variable
	#needs optimization to reduce the number of if statements
	for body in area.get_overlapping_bodies():
		if (playerState == PlayerState.GRIND or playerState == PlayerState.LIP):
			return
		if(body.is_in_group("rampRail")):
			#todo, get rail with tangent closest to the player velocity direction
			#pick this rail and continue, in case multiple rails are in close range	
			#usally the maximum rails close to the player should be 2 or 3
			path = body.get_node(body.get_path_node())
			pathLength = path.curve.get_baked_length()
			if inputTricks.x == 1 and playerState != PlayerState.GRIND:
				pathPosition = _getClosestCurveOffset(path, position)
				curveTangent = _getPathTangent(path, position)
				if(curveTangent == Vector3.ZERO):
					print("nope")
					return
				pathDir = _getPathDir(curveTangent)
				#randomize the balance direction
				var rand = randf()
				if (rand >= 0.5):
					balanceDir = 1
				else:
					balanceDir = -1
				#reset balance angle once grind or lip starts
				balanceAngle = 0
				if(pathDir != 0):
					playerState = PlayerState.GRIND		
				if(pathDir == 0 and playerState != PlayerState.PIPESNAP):
					playerState = PlayerState.LIP
					lipStartPos = position
					lipStartUp = up_direction
					lipStartVel = velocity
					lipStartDir = (_getClosestCurvePoint(path, position) - position ).normalized()
		
	var collInfo = null
	if get_slide_collision_count() != 0:
		collInfo = get_slide_collision(0)
	var collLayer = 0
	if collInfo:
		collLayer = collInfo.get_collider(0).get_collision_layer()
	else:
		collLayer = 0

	if (playerState == PlayerState.FALL):
		#dont change the state if player is fallen
		return
		
	if(playerState == PlayerState.GRIND or playerState == PlayerState.LIP):
		#dont change state while grinding
		ingameUI._setBalanceView(true)
		collision.disabled = true
		return
	else:
		ingameUI._setBalanceView(false)
		collision.disabled = false
	
	if(playerState == PlayerState.LIP):
		#dont change state while player is doing lip tricks
		return
	
	if is_on_floor():
		path = null
		var fallCheck = (abs(velocity.normalized().dot(xForm.basis.z)))
		if(fallCheck < 0.75 and fallCheck != 0 and velocity.length() > 1.0):
			_fall()
			pass
		else:
			if(collLayer == 1):
				playerState = PlayerState.GROUND
			if(collLayer == 3):
				playerState = PlayerState.PIPE
		if(collInfo):
			groundNormal = (collInfo.get_normal() * Vector3(1,0,1)).normalized()
	
	if is_on_wall():
		#not used at the moment
		#might be usefull to detect if a player rides against walls to fast
		#make it fall in this case
		if(velocity.length() > 5):
			_fall()
	
	if !is_on_floor():
		#behavior while in air, or sticked to a pipe
		if(abs(xForm.basis.z.dot(Vector3.UP)) > 0.75 and playerState == PlayerState.PIPE and input.z == 0):
			playerState = PlayerState.PIPESNAP
			rampPos = global_position - get_last_motion() - Vector3.UP * 0.2
		if(playerState != PlayerState.PIPESNAP):
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
	if(dir > 0.3):
		return  -1
	if(dir < -0.3):
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
		up_direction = get_floor_normal()
	else:
		up_direction = lastUpDir		
	if playerState == PlayerState.AIR:
		up_direction = Vector3.UP

func _process(delta):
	#to do: interpolate rotation to get smoother motion on slopesm, while player is grounded
	if(playerState != PlayerState.FALL):
		rbdChar.global_transform = global_transform
		rbdBoard.global_transform = global_transform
	else:
		fallTimer -= delta
	cameraPos.position = cameraPos.position.lerp(global_position, delta * 10)
				
func _fall():
	playerState = PlayerState.FALL
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

func _inputHandler():
	#handles player inputs
	#resetting of player happens by moving forward when fallen
	#todo: add more trick inputs
	input.x = int(Input.is_action_pressed("Left")) - int(Input.is_action_pressed("Right"))
	input.y = int(Input.is_action_pressed("Forward")) - int(Input.is_action_pressed("Backward"))
	input.z = int(Input.is_action_just_pressed("Jump"))
	inputTricks.x = int(Input.is_action_pressed("Grind"))
	if(input.y and playerState == PlayerState.FALL):
		_resetPlayer(lastGroundPos)

func _killOrthogonalVelocity(xForm, vel):
	var fwdVel = xForm.basis.z * vel.dot(xForm.basis.z)
	var ortVel = xForm.basis.x * vel.dot(xForm.basis.x)
	var upVel = xForm.basis.y  * vel.dot(xForm.basis.y)
	velocity = fwdVel + ortVel * 0.25 + upVel
	return velocity

func _raycast(from, to):
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	return result   

func _align(xform, newUp):
	xform.basis.y = newUp
	xform.basis.x = -xform.basis.z.cross(newUp)
	xform.basis = xform.basis.orthonormalized()
	return xform
	
