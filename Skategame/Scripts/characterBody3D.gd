extends CharacterBody3D


const acc = 0.5
const jumpVel = 4.5

var input = Vector3.ZERO
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var vel = Vector3.ZERO


func _physics_process(delta):
	#get inputs
	_inputHandler()
	print(velocity)
	#gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		global_transform.basis = lerp(global_transform.basis, _groundAlign(get_global_transform().basis, get_floor_normal()), delta* 20)
		
	# jump input
	if input.z and is_on_floor():
		velocity.y = jumpVel
	
	#accelerate with forward input
	if input.y != 0 and is_on_floor():
		velocity += global_transform.basis.z * input.y * acc
		
	#decelerate when no forward input
	if input.y == 0 and is_on_floor():
		velocity *= 0.95
	
	if input .x != 0:
		rotate_y(input.x * 0.1)
		
	velocity = _killOrthogonalVelocity(velocity)
		
	move_and_slide()
	

func _inputHandler():
	input.x = int(Input.is_action_pressed("Left")) - int(Input.is_action_pressed("Right"))
	input.y = int(Input.is_action_pressed("Forward")) - int(Input.is_action_pressed("Backward"))
	input.z = int(Input.is_action_just_pressed("Jump"))
	
func _killOrthogonalVelocity(velocity):
	var fwdVel = get_global_transform().basis.z * velocity.dot(get_global_transform().basis.z)
	var ortVel = get_global_transform().basis.x * velocity.dot(get_global_transform().basis.x)
	var upVel = Vector3.UP * velocity.dot(Vector3.UP)
	#print(Vector3.UP * velocity.dot(Vector3.UP))
	velocity = fwdVel + ortVel * 0.25 + upVel
	return velocity
	
func _groundAlign(xform, normal):
	xform.y = normal
	xform.x = -xform.z.cross(normal)
	xform = xform.orthonormalized()
	return xform
