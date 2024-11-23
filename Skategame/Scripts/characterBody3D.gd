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
const pipesnapOffset :float = 0.05
const upAlignSpd :float = 5.0
const interpSpd: float = 15.0

#global movement variables
var isOnFloor : bool = false
var isOnPipe : bool = false
var isOnWall : bool = false
var jumpTime : float = 0.0
var fallTime : float = 0.0
var xForm = null
var dir : Vector3= Vector3.ZERO 
var lastGroundPos : Vector3 = Vector3.ZERO
var lastPhysicsPosition : Vector3 = Vector3.ZERO
var lastUpDir : Vector3 = Vector3.ZERO
var hit = null
var lastVel : Vector3 = Vector3.ZERO

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
var playerState = PlayerState.RESET
var lastPlayerState = PlayerState.RESET

#input variables
var input : Vector3 = Vector3.ZERO #input values
var inputTricks : Vector3 = Vector3.ZERO #input values for tricks

func _ready():
	_initPlayer()
	_resetPlayer(Vector3.UP * 5.0 + Vector3(0,0,0))

func _physics_process(delta):
	xForm = global_transform
	_jumpTimer(delta)
	_debugPlayerState()
	_surfaceCheck()
	_playerState()
	_playerMovement(delta)
	_saveLastState()
	_setUpDirection()	
	_limitVelocity()
	move_and_slide()
	if jumpTime < 0.1:
		apply_floor_snap()

func _groundMovement(delta): #movement while on floor and pipe
	if _checkRevertMotion():
		_revertMotion()
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
		jumpTime = 1.0
		velocity += xForm.basis.y * jumpVel
		
	velocity.y -= gravity * delta	
	var fallCheck = (abs(velocity.normalized().dot(xForm.basis.z)))
	_killOrthogonalVelocity(xForm, velocity)

func _airMovement(delta): 	#movement while in air
	rotate_object_local(Vector3.UP, input.x * rotJump * delta)
	velocity.y -= gravity * delta	
	up_direction = lerp(up_direction,Vector3.UP, delta * upAlignSpd)
	
func _surfaceCheck():
	if is_on_floor():
		var collInfo = get_slide_collision(0)
		if collInfo:
			if collInfo.get_collider().is_in_group('pipe'):
				isOnPipe = true			
		isOnFloor = true
	else:
		isOnFloor = false
		isOnPipe = false
func _jumpTimer(delta):
	jumpTime -= delta

func _playerState():	
	if (playerState == PlayerState.FALL):
		return
	if isOnFloor:
		if isOnPipe:
			playerState = PlayerState.PIPE
		else:
			lastGroundPos = global_position
			isOnFloor = true;
			playerState = PlayerState.GROUND
			
	else:
		playerState = PlayerState.AIR
		
func _setUpDirection():
	if isOnFloor:
		up_direction = get_floor_normal()
		#up_direction = raycast.get_collision_normal()
	else:
		up_direction = lastUpDir	
	if playerState == PlayerState.AIR:
		up_direction = Vector3.UP
	global_transform = _align(global_transform, up_direction) 

func _process(delta):
	_inputHandler()	
	if(playerState != PlayerState.FALL):
		_lerpVisTransform(delta, interpSpd)
	else:
		fallTime -= delta
	cameraPos.position = cameraPos.position.lerp(global_position, delta * 10)

func _resetPlayer(pos):
	if fallTime > 0:
		return
	ingameUI._setFailView(false)
	up_direction = Vector3.UP
	velocity = Vector3.ZERO
	global_position = pos + Vector3.UP
	rbdChar.freeze = true
	rbdBoard.freeze = true
	playerState = PlayerState.RESET
	#balanceAngle = 0.0

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
		
func _checkRevertMotion():
	if velocity.length() < 0.5:
		return
	var revertCheck = velocity.normalized().dot(xForm.basis.z)
	if revertCheck < 0:
		return true
	return false
	
func _revertMotion():
	rotate_object_local(Vector3.UP, PI)

func _initPlayer():
	pass
	
func _playerMovement(delta):
	match playerState:
		PlayerState.FALL:
			return
		PlayerState.GROUND, PlayerState.PIPE:
			_groundMovement(delta)	
		PlayerState.AIR:
			_airMovement(delta)	
	#	PlayerState.PIPESNAP:
	#		_pipeSnapMovement(delta)
	#	PlayerState.PIPESNAPAIR:
	#		_pipeSnapAirMovement(delta)	
	#	PlayerState.GRIND:
	#		_grindMovement(delta)
	#	PlayerState.LIP:
	#		_lipMovement(delta)	

func _saveLastState():
	lastPhysicsPosition = global_position
	lastUpDir = up_direction
	lastVel = velocity
	
func _lerpVisTransform(delta, speed):
	rbdChar.global_transform = rbdChar.transform.interpolate_with(global_transform, delta * speed)
	rbdChar.global_position = global_position
	rbdBoard.global_transform = rbdChar.global_transform
	
func _fall(fallReason, fallValue):
	print(fallReason + ": " + str(fallValue))
	playerState = PlayerState.FALL
	lastVel = Vector3.ZERO
	ingameUI._setFailView(true)
	fallTime = 2.0
	rbdChar.freeze = false
	rbdChar.apply_impulse(velocity)
	rbdBoard.freeze = false
	rbdBoard.apply_impulse(velocity)
		
func _debugPlayerState():
	#debug logic to print the player state only on change
	if(playerState != lastPlayerState):
		print(PlayerState.find_key(playerState))
	lastPlayerState = playerState	
