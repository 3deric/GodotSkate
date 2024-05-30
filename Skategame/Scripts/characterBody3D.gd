extends CharacterBody3D

const acc = 0.2
const jumpVel = 10.0
const rot = 2.0
const rotJump = 5.0
const maxVel = 25.0
const gravity = 20.0
const maxBounces = 5

enum PlayerState {RESET, GROUND, PIPE, PIPESNAP, AIR, FALL}

var input = Vector3.ZERO #input values
var dir = Vector3.ZERO #current direction of motion
var lastDir = Vector3.ZERO #direction of last frame for falling check
var xForm = null
var grounded = false
var right = Vector3.ZERO

var curveSnap = Vector3.ZERO

var playerState = PlayerState.RESET
var lastPlayerState = PlayerState.RESET

var rampPos = Vector3.ZERO
var groundNormal = Vector3.RIGHT

var lastCollLayer = 0

@onready var rbdBoard: RigidBody3D = get_node("RBDBoard")
@onready var rbdChar: RigidBody3D = get_node("RBDCharacter")
@export var path: Path3D = null
@onready var area: Area3D = get_node("Area3D")
@export var camera: Camera3D = null
@export var cameraPos: Node3D = null

func _ready():
	_resetPlayer(Vector3.UP * 5.0)

func _physics_process(delta):
	xForm = global_transform
	curveSnap = _getClosestCurvePoint(path, global_position)
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
	
	#behaviour while grounded
	if (playerState == PlayerState.GROUND or playerState == PlayerState.PIPE):
		
		_setUpDirection()
		
		if((input.y > 0 and velocity.length() <= maxVel) or (input.y < 0 and velocity.length() >= -maxVel)):
			velocity += xForm.basis.z * input.y * acc
		#dedeleration
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
		rampPos.x = global_position.x
		rampPos.z = global_position.z 
		input.z
		var velHor = velocity * Vector3(1,0,1)
		var velUp = velocity * Vector3.UP	
		var raycast = _raycast(rampPos, rampPos + velHor)
		if raycast:
			groundNormal = (raycast.normal * Vector3(1,0,1)).normalized()			
		up_direction = groundNormal			
		velHor = _collideAndSlide(velHor, rampPos, 0, velHor)
		velocity = velHor + velUp	
		velocity.y -= gravity * delta
		
	#align upvector with ground while grounded
	global_transform = _align(global_transform, up_direction)
	
	
	#apply movement
	lastPlayerState = playerState
	move_and_slide()


func _playerState():	
	
	
	#if(area.get_overlapping_bodies().count(0) > 0):
	print(area.get_overlapping_bodies())
	
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
		
	if(is_on_wall()):
		playerState = PlayerState.FALL
		_fall()
		return
	
	if is_on_floor():
		var fallCheck = (abs(velocity.normalized().dot(xForm.basis.z)))
		if(fallCheck < 0.5 and fallCheck != 0 and velocity.length() > 1.0):
			playerState = PlayerState.FALL
			_fall()
		else:
			if(collLayer == 1):
				playerState = PlayerState.GROUND
			if(collLayer == 3):
				playerState = PlayerState.PIPE
		if(collInfo):
			groundNormal = (collInfo.get_normal() * Vector3(1,0,1)).normalized()
	
	if !is_on_floor():
		#behavior while in air, or sticked to a pipe
		if(abs(xForm.basis.z.dot(Vector3.UP)) > 0.25 and playerState == PlayerState.PIPE and input.z == 0):
			playerState = PlayerState.PIPESNAP
			rampPos = global_position - get_last_motion() - Vector3.UP * 0.2
		if(playerState != PlayerState.PIPESNAP):
			playerState = PlayerState.AIR	
			
	#set current collision layer als last collision layer for next physics cycle	
	lastCollLayer = collLayer

func _getClosestCurvePoint(path: Path3D,global_pos: Vector3):
	var curve: Curve3D = path.curve
 	# transform the target position to local space
	var path_transform: Transform3D = path.global_transform
	var local_pos: Vector3 = global_pos * path_transform
  # get the nearest offset on the curve
	var offset: float = curve.get_closest_offset(local_pos)
  # get the local position at this offset
	var curve_pos: Vector3 = curve.sample_baked(offset, true)
  # transform it back to world space
	curve_pos = path_transform * curve_pos
	return curve_pos
		
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
	cameraPos.position = cameraPos.position.lerp(global_position, delta * 10)
				
func _fall():
	rbdChar.freeze = false
	rbdChar.apply_impulse(velocity)
	rbdBoard.freeze = false
	rbdBoard.apply_impulse(velocity)
	
func _resetPlayer(pos):
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
	
	if(input.y and playerState == PlayerState.FALL):
		_resetPlayer(global_position)

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
	
func _collideAndSlide(vel, pos, depth, velInit):
	if(depth >= maxBounces):
		return Vector3.ZERO	

	var origin = pos
	var end = (vel.normalized() * (vel.length())) + pos
	var result = _raycast(origin, end)
	#if ray hit anything calculating new position
	if(result):	
		var snapToSurface = vel.normalized() * (pos.distance_to(result.position) - 0.1)
		var leftover = vel - snapToSurface
	
		if (snapToSurface.length() <= 0.1):
			snapToSurface = Vector3.ZERO
			
		var scale = 1 - Vector3(result.normal.x, 0, result.normal.z).normalized().dot(-Vector3(velInit.x, 0, velInit.z).normalized())
		leftover = _projectAndScale(leftover, result.normal) * scale
		return 	 snapToSurface + _collideAndSlide(leftover,pos + snapToSurface , depth + 1, velInit)
	return vel
	

func _projectAndScale(leftover, normal):
	var mag = leftover.length()
	leftover = Plane(normal, Vector3.UP).project(leftover).normalized()
	leftover *= mag	
	return leftover	
