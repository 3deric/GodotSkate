extends RigidBody3D

const maxVel = 5.0
const acc = 35.0
const rot = 1.0
const jump = 7.0

var input = Vector3.ZERO
var dir = Vector3.ZERO
var floorDist = 10.0
var fwdVel = 0.0
var up =  Vector3.UP

var jumping = false

var wheelFR = null
var wheelFL = null
var wheelRL = null
var wheelRR = null

var cameraArm = null

@export var debugView: Control

# Called when the node enters the scene tree for the first time.
func _ready():
	wheelFR = get_node("wheelFR") 
	wheelFL = get_node("wheelFL") 
	wheelRL = get_node("wheelRL") 
	wheelRR = get_node("wheelRR") 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	_inputHandler()
	dir = get_global_transform().basis.z	
	fwdVel = _getFwdVelocity(linear_velocity)
	#floorDist = floorDetector.global_transform.origin.distance_to(floorDetector.get_collision_point())
	var rotationOffset = 0.0
	
	floorDist = _floorDist()
	
	if (_isGrounded()):	
		#up = lerp(up,_getUpVector(), delta * 10.0)
		up = _getUpVector()
		global_transform.basis = _groundAlign(get_global_transform().basis, up)
		linear_velocity = _killOrthogonalVelocity(linear_velocity)
		apply_central_force(dir * acc * input.y)
		apply_impulse(Vector3.UP * jump * input.z)
		rotationOffset = remap(clamp(linear_velocity.length(), 0, 25), 0.0, 25.0,0.025, 0.05)
	else:
		rotationOffset = 0.1
	
	rotate_y(input.x * rot  * rotationOffset)
	
	debugView._debugDraw(Vector3.ZERO, Vector3.UP, Color.GREEN)

func _floorDist():
	var distFR = wheelFR.global_transform.origin.distance_to(wheelFR.get_collision_point())
	var distFL = wheelFL.global_transform.origin.distance_to(wheelFL.get_collision_point())
	var distRL = wheelRL.global_transform.origin.distance_to(wheelRL.get_collision_point())
	var distRR = wheelRR.global_transform.origin.distance_to(wheelRR.get_collision_point())
	var floorDist = (distFR + distFL  + distRL + distRR) / 4
	return floorDist	
	
func _getUpVector():
	var up = (wheelFR.get_collision_normal()+wheelFL.get_collision_normal()+wheelRL.get_collision_normal()+wheelRR.get_collision_normal()) / 4
	return up.normalized()

func _inputHandler():
	input.x = int(Input.is_action_pressed("Left")) - int(Input.is_action_pressed("Right"))
	input.y = int(Input.is_action_pressed("Forward")) - int(Input.is_action_pressed("Backward"))
	input.z = int(Input.is_action_just_pressed("Jump"))
	
func _killOrthogonalVelocity(velocity):
	var fwd_vel = get_global_transform().basis.z * velocity.dot(get_global_transform().basis.z)
	var ort_vel = get_global_transform().basis.x * velocity.dot(get_global_transform().basis.x)
	var up_vel = Vector3.UP * velocity.dot(get_global_transform().basis.y)
	velocity = fwd_vel + ort_vel * 0.75 + up_vel
	return velocity
	
func _isGrounded():
	var grounded = false
	if (floorDist < 0.5):
		grounded = true
	return grounded
	
func _getFwdVelocity(velocity):
	return (get_global_transform().basis.z * velocity.dot(get_global_transform().basis.z)).length()
	
func _groundAlign(xform, normal):
	xform.y = normal
	xform.x = -xform.z.cross(normal)
	xform = xform.orthonormalized()
	return xform

