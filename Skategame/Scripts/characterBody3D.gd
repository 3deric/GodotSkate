extends CharacterBody3D

const acc = 0.2
const jumpVel = 5.0
const rot = 1.0
const maxVel = 20.0
const gravity = 10.0

var input = Vector3.ZERO #input values
var dir = Vector3.ZERO #current direction
var xForm = null

var grounded = false
var visuals = null

func _ready():
	visuals = get_node("Visuals")

func _physics_process(delta):
	xForm = global_transform
	dir = xForm.basis.x.cross(up_direction)
	#get inputs
	_inputHandler()	
	
	#print(get_last_slide_collision())
	grounded = is_on_floor()
	if is_on_floor():
		#print(get_floor_normal())
		var raycast = _raycast(global_position, global_position - up_direction)
		if raycast:
			up_direction = raycast.normal
		if input.x:
			#rotation input
			#velocity = velocity.rotated(up_direction, input.x * rot)
			rotate_y(input.x * rot * delta)	
		if input.y:
			velocity += dir * input.y * acc
		else:
			velocity *= 0.99
		if input.z:
			velocity.y += jumpVel
	else:
		#if input.x:
		#	dir = dir.rotated(up_direction, input.x * delta * rot * 5)
		up_direction = Vector3.UP

	#apply gravity
	velocity.y -= gravity * delta
	
	velocity = _killOrthogonalVelocity(xForm, velocity)
	#apply movement
	move_and_slide()

func _process(delta):
	#to do
	#interpolate rotation to get smoother motion on slopes
	var basis = Basis(dir.cross(up_direction), up_direction, dir)
	var transform = Transform3D(basis, global_position)
	visuals.global_transform = transform

func _inputHandler():
	input.x = int(Input.is_action_pressed("Left")) - int(Input.is_action_pressed("Right"))
	input.y = int(Input.is_action_pressed("Forward")) - int(Input.is_action_pressed("Backward"))
	input.z = int(Input.is_action_pressed("Jump"))

func _killOrthogonalVelocity(xForm, velocity):
	var fwdVel = xForm.basis.z * velocity.dot(xForm.basis.z)
	var ortVel = xForm.basis.x * velocity.dot(xForm.basis.x)
	var upVel = Vector3.UP  * velocity.dot(Vector3.UP)
	velocity = fwdVel + ortVel * 0.25 + upVel
	return velocity

func _raycast(from, to):
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	return result
