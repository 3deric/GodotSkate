extends CharacterBody3D

const acc = 0.2
const jumpVel = 10.0
const rot = 2.0
const rotJump = 7.0
const maxVel = 25.0
const gravity = 25.0
const maxBounces = 5

enum PlayerState {RESET, GROUND, PIPE, PIPESNAP, AIR, FALL, GRIND}

var input = Vector3.ZERO #input values
var inputTricks = Vector3.ZERO #input values for tricks
var dir = Vector3.ZERO #current direction of motion
var lastDir = Vector3.ZERO #direction of last frame for falling check
var xForm = null

var fallTimer = 0.0

var lastPhysicsPosition = Vector3.ZERO

var curveSnap = Vector3.ZERO
var curveTangent = Vector3.ZERO

var playerState = PlayerState.RESET
var lastPlayerState = PlayerState.RESET
var lastGroundPos = Vector3.ZERO

var rampPos = Vector3.ZERO
var groundNormal = Vector3.RIGHT

var lastCollLayer = 0

var path: Path3D = null
var pathPosition: float = -1
var pathLength: float = -1
var pathDir: int = 0
var pathVelocity: Vector3 = Vector3.ZERO

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
		curveTangent = _alignToCurve(path, global_position)
		up_direction = Vector3.UP.cross(curveTangent)
		position = Vector3(curveSnap.x, position.y, curveSnap.z) + up_direction * 0.25
		velocity.y -= gravity * delta
		if (!_getStickCurve(path, global_position)):
			playerState = PlayerState.AIR		
	
	if (playerState == PlayerState.GRIND):
		collision.disabled = true
		var grindVel = velocity.length() * 0.99
		up_direction = Vector3.UP
		pathPosition -= grindVel * pathDir * delta
		
		position = _getPositionOnCurve(path, pathPosition) + up_direction * 0.25
		curveTangent = _alignToCurve(path, global_position) * -pathDir
		pathVelocity = curveTangent  * grindVel
		rotation.y = atan2(curveTangent.x,curveTangent.z)
		if(input.z):
			velocity = curveTangent * grindVel
			velocity += xForm.basis.y * input.z * jumpVel
			playerState = PlayerState.AIR
		if (!_getStickCurve(path, global_position)):
			velocity = curveTangent  * grindVel
			playerState = PlayerState.AIR
	else:
		collision.disabled = false
	
	#align upvector with ground while grounded
	global_transform = _align(global_transform, up_direction)
	#set player parameters for next physics iteration
	lastPlayerState = playerState
	lastPhysicsPosition = global_position
	if velocity.length() > maxVel:
		velocity = velocity.normalized() * maxVel * 0.99
	#apply movement
	move_and_slide()

func _playerState():
	
	for body in area.get_overlapping_bodies():
		if(body.is_in_group("rampRail")):
			path = body.get_child(0)
			pathLength = path.curve.get_baked_length()
			if inputTricks.x == 1:
				pathDir = _getCurveDir(path, position)
				pathPosition = _getClosestCurveOffset(path, position)
				playerState = PlayerState.GRIND
			#print(body.get_path_node())
			#todo, get the path by the node and not by the child
		
	var collInfo = null
	if get_slide_collision_count() != 0:
		collInfo = get_slide_collision(0)
	var collLayer = 0
	if collInfo:
		collLayer = collInfo.get_collider(0).get_collision_layer()
	else:
		collLayer = 0

	#setting player states	
	if (playerState == PlayerState.FALL):
		return
		
	if(playerState == PlayerState.GRIND):
		return
	
	if is_on_floor():
		var fallCheck = (abs(velocity.normalized().dot(xForm.basis.z)))
		if(fallCheck < 0.75 and fallCheck != 0 and velocity.length() > 1.0):
			playerState = PlayerState.FALL
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
		#playerState = PlayerState.FALL
		#_fall()
		pass
	
	if !is_on_floor():
		#behavior while in air, or sticked to a pipe
		if(abs(xForm.basis.z.dot(Vector3.UP)) > 0.25 and playerState == PlayerState.PIPE and input.z == 0):
			playerState = PlayerState.PIPESNAP
			rampPos = global_position - get_last_motion() - Vector3.UP * 0.2
		if(playerState != PlayerState.PIPESNAP):
			playerState = PlayerState.AIR			
	#set current collision layer als last collision layer for next physics cycle	
	lastCollLayer = collLayer
	
func _alignToCurve(path: Path3D, pos: Vector3):
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
	
func _getCurveDir(path: Path3D, pos: Vector3):
	#function to get direction along the curve, based on the starting direction
	var curve: Curve3D = path.curve	
	var currentPoint =  _getClosestCurvePoint(path, pos)
	var nextPoint = _getClosestCurvePoint(path, pos + velocity)
	var dir = curve.get_closest_offset(currentPoint) - curve.get_closest_offset(nextPoint)
	if(dir > 0.1):
		return  1
	if(dir < -0.1):
		return -1
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
	#print(offset)
	if(offset <= 0.1 or offset >= curve.get_baked_length() -.1):
		return false
	else:
		return true
		
func _setUpDirection():
	#raycast to define new up direction based on the ground
	var raycast = _raycast(global_position, global_position - up_direction)
	if raycast:
		up_direction = raycast.normal
	if (playerState == PlayerState.AIR):
		up_direction = Vector3.UP

func _process(delta):
	#to do: interpolate rotation to get smoother motion on slopes
	if(playerState != PlayerState.FALL):
		rbdChar.global_transform = global_transform
		rbdBoard.global_transform = global_transform
	else:
		fallTimer -= delta
	cameraPos.position = cameraPos.position.lerp(global_position, delta * 10)
				
func _fall():
	ingameUI.visible = true
	fallTimer = 2.0
	rbdChar.freeze = false
	rbdChar.apply_impulse(velocity)
	rbdBoard.freeze = false
	rbdBoard.apply_impulse(velocity)
	
func _resetPlayer(pos):
	if fallTimer > 0:
		return
	ingameUI.visible = false
	up_direction = Vector3.UP
	velocity = Vector3.ZERO
	#lastDir = global_transform.basis.x.cross(up_direction)
	global_position = pos + Vector3.UP
	rbdChar.freeze = true
	rbdBoard.freeze = true
	playerState = PlayerState.RESET

func _inputHandler():
	input.x = int(Input.is_action_pressed("Left")) - int(Input.is_action_pressed("Right"))
	input.y = int(Input.is_action_pressed("Forward")) - int(Input.is_action_pressed("Backward"))
	input.z = int(Input.is_action_pressed("Jump"))
	
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
	#print(newUp)
	xform.basis.x = -xform.basis.z.cross(newUp)
	xform.basis = xform.basis.orthonormalized()
	return xform
	
