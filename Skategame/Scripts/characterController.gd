extends RigidBody3D

const maxVel = 5.0
const acc = 25.0
const rot = 1.0
const jump = 5.0

var input = Vector3.ZERO
var dir = Vector3.ZERO
var floorDist = 10.0
var fwdVel = 0.0
var up =  Vector3.UP

var floorDetector = null

# Called when the node enters the scene tree for the first time.
func _ready():
	floorDetector = get_node("CharacterFloorRaycast") 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	_inputHandler()
	dir = get_global_transform().basis.z	
	fwdVel = _getFwdVelocity(linear_velocity)
	floorDist = floorDetector.global_transform.origin.distance_to(floorDetector.get_collision_point())
	if (_isGrounded()):
		up = floorDetector.get_collision_normal()
		global_transform.basis = _groundAlign(get_global_transform().basis, up)
		linear_velocity = _killOrthogonalVelocity(linear_velocity)
		apply_central_force(dir * acc * input.y)
		apply_central_impulse(get_global_transform().basis.y * jump * input.z)

	rotate_y(input.x * rot  * 0.1)
	
func _inputHandler():
	input.x = int(Input.is_action_pressed("Left")) - int(Input.is_action_pressed("Right"))
	input.y = int(Input.is_action_pressed("Forward")) - int(Input.is_action_pressed("Backward"))
	input.z = int(Input.is_action_just_released("Jump"))
	
func _killOrthogonalVelocity(velocity):
	var fwd_vel = get_global_transform().basis.z * velocity.dot(get_global_transform().basis.z)
	var ort_vel = get_global_transform().basis.x * velocity.dot(get_global_transform().basis.x)
	var up_vel = up * velocity.dot(Vector3.UP)
	velocity = fwd_vel + ort_vel * 0.5 + up_vel
	return velocity
	
func _isGrounded():
	var grounded = false
	if (floorDist < 0.25):
		grounded = true
	return grounded
	
func _getFwdVelocity(velocity):
	return (get_global_transform().basis.z * velocity.dot(get_global_transform().basis.z)).length()
	
func _groundAlign(xform, normal):
	xform.y = normal
	xform.x = -xform.z.cross(normal)
	xform = xform.orthonormalized()
	return xform
