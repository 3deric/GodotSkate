extends Node3D

const maxVel = 5.0
const acc = 35.0
const rot = 1.0
const jump = 7.0
const maxBounces = 8
const skinWidth = 0.01
const maxSlopeAngle = 55

const gravity = Vector3.DOWN * 0.1

var input = Vector3.ZERO
var jumping = false

var shapeCast: ShapeCast3D
var fwdRay: RayCast3D
@export var debugView: Control

var tempVector = Vector3.ZERO
var vel = Vector3.ZERO
var xForm = null
var spd = 0.0

func _ready():
	shapeCast = get_node("ShapeCast3D")
	fwdRay = get_node("RayCast3DFwd")
	xForm = global_transform.basis

func _physics_process(delta):
	xForm = global_transform.basis
	vel = xForm.z	* spd
	spd += input.y * 0.01
	_inputHandler()
	rotate_y(input.x * 5.0 * delta)
	tempVector = _move(xForm.z * spd * delta)	
	global_position += _move(xForm.z * spd * delta)	
	
func _collideAndSlide(vel, pos, depth, gravityPass, velInit):
	if(depth >= maxBounces):
		return Vector3.ZERO	
	#var dist = vel.length() + skinWidth
	#raycasting logic
	var space_state = get_world_3d().direct_space_state
	var origin = pos
	var end = (vel.normalized() * (vel.length())) + pos
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	#if ray hit anything calculating new position
	if(result):	
		var snapToSurface = vel.normalized() * (pos.distance_to(result.position) - skinWidth)
		var leftover = vel - snapToSurface
		
		var angle = Vector3.UP.angle_to(result.normal)
		
		if (snapToSurface.length() <= skinWidth):
			snapToSurface = Vector3.ZERO
		#on normal ground
		if (angle <= maxSlopeAngle):
			if(gravityPass):
				return snapToSurface #todo, fix gravity!
			leftover = _projectAndScale(leftover, result.normal)
		#wall or steep slope
		else:
			var scale = 1 - Vector3(result.normal.x, 0, result.normal.z).normalized().dot(-Vector3(velInit.x, 0, velInit.z).normalized())
			leftover = _projectAndScale(leftover, result.normal) * scale
		#return snapToSurface + leftover	
		return 	 snapToSurface + _collideAndSlide(leftover,pos + snapToSurface , depth + 1, gravityPass, velInit)
	return vel
	
func _move(velocity):
	velocity = _collideAndSlide(velocity, global_position, 0, false, velocity)
	velocity += _collideAndSlide(gravity, global_position + velocity, 0, true, gravity)
	return velocity

func _projectAndScale(leftover, normal):
	var mag = leftover.length()
	leftover = Plane(normal, Vector3.UP).project(leftover).normalized()
	leftover *= mag	
	return leftover	

func _inputHandler():
	input.x = int(Input.is_action_pressed("Left")) - int(Input.is_action_pressed("Right"))
	input.y = int(Input.is_action_pressed("Forward")) - int(Input.is_action_pressed("Backward"))
	input.z = int(Input.is_action_just_pressed("Jump"))
	
func _killOrthogonalVelocity(xform, vel):
	var fwd_vel =xform.z * vel.dot(xform.basis.z)
	var ort_vel = xform.x * vel.dot(xform.basis.x)
	var up_vel = Vector3.UP * vel.dot(xform.basis.y)
	vel = fwd_vel + ort_vel * 0.75 + up_vel
	return vel
	
func _isGrounded():
	pass

func _groundAlign(xform, normal):
	xform.y = normal
	xform.x = -xform.z.cross(normal)
	xform = xform.orthonormalized()
	return xform

