extends CharacterBody3D


const acc = 10.0
const jumpVel = 7.0
const rot = 5.0
const maxVel = 20.0

var input = Vector3.ZERO
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var vel = Vector3.ZERO

var grounded = false


var visuals = null

func _ready():
	visuals = get_node("Visuals")


func _physics_process(delta):
	#get inputs
	_inputHandler()	
	grounded = is_on_floor()
	#gravity
	if grounded:
		up_direction = get_floor_normal()	
	else:
		velocity.y -= gravity * delta
		up_direction = Vector3.UP
	# jump input
	if input.z and is_on_floor():
		velocity.y = jumpVel
	#accelerate with forward input
	if input.y != 0 and is_on_floor() and velocity.length() < maxVel:
		velocity += global_transform.basis.z * input.y * acc * delta	
	#decelerate when no forward input
	if input.y == 0 and is_on_floor():
		velocity *= 0.95
	velocity.y -= gravity * delta
	if input .x != 0:
		rotate_y(input.x * rot * delta)
	
	if grounded:
		velocity = _killOrthogonalVelocity(velocity)
	#print(get_slide_collision(0))
	move_and_slide()
	
	var collision = get_slide_collision(0)
	if collision != null:
		var collider = collision.get_collider().get_collision_layer()
		print(collider)
		#if is_instance_valid(collider):
   	 	#	if collider.get_collision_layer_bit(3):
		#		print("layer")
	
func _process(delta):
	var xForm = visuals.global_transform.basis
	visuals.global_transform.basis = _align(xForm, up_direction, transform.basis.z)


func _inputHandler():
	input.x = int(Input.is_action_pressed("Left")) - int(Input.is_action_pressed("Right"))
	input.y = int(Input.is_action_pressed("Forward")) - int(Input.is_action_pressed("Backward"))
	input.z = int(Input.is_action_pressed("Jump"))
	
func _killOrthogonalVelocity(velocity):
	var fwdVel = get_global_transform().basis.z * velocity.dot(get_global_transform().basis.z)
	var ortVel = get_global_transform().basis.x * velocity.dot(get_global_transform().basis.x)
	var upVel = Vector3.UP  * velocity.dot(Vector3.UP)
	velocity = fwdVel + ortVel * 0.25 + upVel
	return velocity
	
func _align(xform, normal, fwd):
	xform.y = normal
	xform.z = fwd
	xform.x = -xform.z.cross(normal)
	xform = xform.orthonormalized()
	return xform
