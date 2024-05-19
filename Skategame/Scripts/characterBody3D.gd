extends CharacterBody3D

const acc = 0.2
const jumpVel = 5.0
const rot = 2.0
const rotJump = 5.0
const maxVel = 20.0
const gravity = 10.0

enum PlayerState {RESET, GROUND, AIR, FALL}

var input = Vector3.ZERO #input values
var dir = Vector3.ZERO #current direction of motion
var lastDir = Vector3.ZERO #direction of last frame for falling check
var xForm = null
var grounded = false
var right = Vector3.ZERO

var playerState = PlayerState.RESET

var rampPos = Vector3.ZERO
var rampDir = Vector3.ZERO
@onready var rbdBoard: RigidBody3D = get_node("RBDBoard")
@onready var rbdChar: RigidBody3D = get_node("RBDCharacter")
var fallen = false

func _ready():
	_resetPlayer(Vector3.UP * 5.0)

func _physics_process(delta):
	xForm = global_transform
	

	#print(abs(velocity.normalized().dot(Vector3.UP)) )
	#check if player is falling	
	_inputHandler()	
	_playerState()
	
	if (playerState == PlayerState.FALL):
		velocity = Vector3.ZERO
		return
	
	#behaviour while grounded
	if (playerState == PlayerState.GROUND):
		
		_setUpDirection()
		
		#acceleration
		velocity += xForm.basis.z * input.y * acc
		
		#jump acceleration
		velocity += xForm.basis.y * input.z * jumpVel
	
		rotate_object_local(Vector3.UP, input.x * rot * delta)

		#apply gravity
		velocity.y -= gravity * delta
		
		_killOrthogonalVelocity(xForm, velocity)
	
	#movement while not grounded
	else:
		rotate_object_local(Vector3.UP, input.x * rotJump * delta)
		velocity.y -= gravity * delta
		up_direction = Vector3.UP
		
	#align upvector with ground while grounded
	global_transform = _align(global_transform, up_direction)
	
	
	#apply movement

	move_and_slide()


func _playerState():
	if (playerState == PlayerState.FALL):
		return
	
	if is_on_floor():
		var fallCheck = (abs(velocity.normalized().dot(xForm.basis.z)))
		if(fallCheck < 0.5 and fallCheck != 0 and velocity.length() > 1.0):
			playerState = PlayerState.FALL
			_fall()
		else:
			playerState = PlayerState.GROUND
	else:
		playerState = PlayerState.AIR
		
func _setUpDirection():
	#raycast to define new up direction based on the ground
	var raycast = _raycast(global_position, global_position - up_direction)
	if raycast:
		up_direction = raycast.normal
	else:
		up_direction = Vector3.UP

func _process(delta):
	#to do
	#interpolate rotation to get smoother motion on slopes
	if(playerState != PlayerState.FALL):
		rbdChar.global_transform = global_transform
		rbdBoard.global_transform = global_transform
		
func _rampSnap():
	#to do
	#check if player is going vertial
	#set new state to ramp
	#store last grounded position to cast a ray that snaps to the ramp
	#move the ray on the height of the ramp to slide the player along the ramp
	var collisionInfo = get_last_slide_collision()
	if collisionInfo:
		var collider = collisionInfo.get_collider()
		if(collider.collision_layer == 2):
			#collisionInfo.
			rampPos = collisionInfo.get_position()
			rampDir = up_direction
			
			pass
		#if (!get_slide_collision(0) and collider.collision_layer == 2):
		#	print("from ramp!")
	pass
		
func _fall():
	rbdChar.freeze = false
	rbdChar.apply_impulse(velocity)
	rbdBoard.freeze = false
	rbdBoard.apply_impulse(velocity)
	
func _resetPlayer(pos):
	up_direction = Vector3.UP
	velocity = Vector3.ZERO
	lastDir = global_transform.basis.x.cross(up_direction)
	global_position = pos
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
	xform.basis.x = -xform.basis.z.cross(newUp)
	xform.basis = xform.basis.orthonormalized()
	return xform
