extends Node3D

const acc = 0.5
const grav = 0.5
const jmpAcc = 0.2
const rot = 10

@export var floorC:RayCast3D = null

var input = Vector3.ZERO
var dir = Vector3.ZERO
var vel = Vector3.ZERO
var isOnFloor = false
var xForm = null

func _physics_process(delta):
	_inputHandler()
	
	dir = global_transform.basis
	if(floorC.is_colliding()):
		isOnFloor = true
	else:
		isOnFloor =false
		
	if(isOnFloor):
		xForm = global_transform.basis
		global_transform.basis = lerp(xForm,_groundAlign(xForm, floorC.get_collision_normal()),  delta * 30)
		#killing vertical velocity when grounded
		vel += Vector3.UP * vel.dot(Vector3.DOWN)
		#rotation input
		if input .x != 0:
			rotate_y(input.x * rot * delta * 0.1)
		#acceleration input and friction
		if(input.y != 0):
			vel += xForm.z * input.y * delta * acc
		else:
			vel *= 0.95
		
		#jumping handling
		if(input.z):
			vel += Vector3.UP * jmpAcc
				#killing vertical velocity, when grounded
		
		vel = _killOrthogonalVelocity(xForm, vel)
	
	else:
		#rotation input while flying
		if input .x != 0:
			rotate_y(input.x * rot * delta)
		vel += Vector3.DOWN * grav * delta
		
	position += vel

func _inputHandler():
	input.x = int(Input.is_action_pressed("Left")) - int(Input.is_action_pressed("Right"))
	input.y = int(Input.is_action_pressed("Forward")) - int(Input.is_action_pressed("Backward"))
	input.z = int(Input.is_action_just_pressed("Jump"))

func _groundAlign(xform, normal):
	xform.y = normal
	xform.x = -xform.z.cross(normal)
	xform = xform.orthonormalized()
	return xform

func _killOrthogonalVelocity(xForm, vel):
	var fwdVel = xForm.z * vel.dot(xForm.z)
	var ortVel = xForm.x * vel.dot(xForm.x)
	var upVel = Vector3.UP * vel.dot(Vector3.UP)
	vel = fwdVel + ortVel * 0.95 + upVel
	return vel
