extends RigidBody

class_name Boat

export(float) var buoyancy_offset = 0.0
export(float) var buoyancy_force = 40.0
export(Vector3) var buoyancy_torque = Vector3(5.0, 0.5, 2.0)
export(Vector3) var buoyancy_linear_damp = Vector3(1.5, 5.0, 0.3)
export(float) var buoyancy_angular_damp = 1.0

var _water: WaterSurface

var _buoyX: Array
var _buoyGram: Basis

const BuoyNodes = 0
const BuoyGrid = 1
const BuoyRandom = 2

func _ready():
	_water = get_parent().get_node("WaterSurface")

	# Precompute Gram matrix for computing water normal with linear regression
	var X = []
	var mode = BuoyGrid
	if mode == BuoyNodes:
		var buoys = get_node("Buoys").get_children()
		X.resize(len(buoys))
		for i in range(len(buoys)):
			var Pi = buoys[i].transform.origin
			X[i] = Vector3(1.0, Pi.x, Pi.z)
	elif mode == BuoyGrid:
		var N = 5
		X.resize(N * N)
		for i in range(N):
			for j in range(N):
				X[i + j * N] = Vector3(1.0, 2.0 * float(i) / float(N - 1) - 1.0, 2.0 * float(j) / float(N - 1) - 1.0)
	elif mode == BuoyRandom:
		var rng = RandomNumberGenerator.new()
		rng.seed = 68342
		var N = 10
		X.resize(N)
		for i in range(N):
			X[i] = Vector3(1.0, rng.randf_range(-1, 1), rng.randf_range(-1, 1))
	_buoyX = X

	# TODO better conditioning for the inverse
	var M = Basis(Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0))
	for xi in X:
		M.x.x += xi.x * xi.x
		M.y.x += xi.y * xi.x
		M.z.x += xi.z * xi.x
		M.x.y += xi.x * xi.y
		M.y.y += xi.y * xi.y
		M.z.y += xi.z * xi.y
		M.x.z += xi.x * xi.z
		M.y.z += xi.y * xi.z
		M.z.z += xi.z * xi.z
	_buoyGram = M.inverse()

func _draw_vector(pos: Vector3, vec: Vector3, color: Color):
	DebugDraw.draw_line_3d(pos, pos + vec, color)
	DebugDraw.draw_line_3d(pos, pos + Vector3(vec.x, 0, vec.z), color)
	DebugDraw.draw_line_3d(pos + Vector3(vec.x, 0, vec.z), pos + vec, color)

func _draw_normals(state: PhysicsDirectBodyState, depth: float, hnor: Vector3, torque: Vector3):
	return
	var scale = 3.0
	var pos = state.transform.origin
	_draw_vector(pos, state.transform.basis.y * scale, Color(0, 1, 0))
	var normal_color = Color(0.4,0.4,0) if depth < 0.0 else Color(1,1,0)
	_draw_vector(pos, hnor * scale, normal_color)
	_draw_vector(pos, state.transform.basis.y.cross(hnor) * scale, Color(1, 0, 0))
#	_draw_vector(pos, torque * 10.0, Color(1, 0, 0))

func _draw_forces(state: PhysicsDirectBodyState, force: Vector3, drag: Vector3, torque: Vector3):
	return
	var offset = Vector3(0, 2, 0)
	var center = state.transform.origin + offset
	DebugDraw.draw_line_3d(center, center + force, Color(0.2, 0.9, 0))
	DebugDraw.draw_line_3d(center, center + drag, Color(0.1, 0.7, 0.9))
	DebugDraw.draw_line_3d(center, center + torque, Color(0.9, 0.4, 0))


func _integrate_forces(state):
	var b = Vector3(0, 0, 0)
	var dbdt = Vector3(0, 0, 0)
	for buoy in _buoyX:
		var pos = Vector3(buoy.y, 0.0, buoy.z) + state.transform.origin

		# Returns [h, dhdt, normal]
		var res = _water.waves(Vector2(pos.x, pos.z), _water.time, state.step)
		var h = res[0] - state.transform.origin.y - buoyancy_offset
		# Ignoring lateral velocity components
		var dhdt = res[1]
#		var hnor = res[2]
		
		b += h * buoy
		dbdt += dhdt * buoy
	
	# x=h0, y=dhdx, z=dhdz
	var hsolve = _buoyGram * b
	var h0 = hsolve.x
	var dhdx = hsolve.y
	var dhdz = hsolve.z
	var hnor = Vector3(-dhdx, 1.0, -dhdz).normalized()
	var hdist = h0 * hnor.y

	var dhdtsolve = _buoyGram * dbdt
	var dhdt = dhdtsolve.x

	var depth = h0
	if depth > 0.0:
		var rotation = Quat(state.transform.basis)

		var force = hnor * depth * buoyancy_force
		
		# Velocity relative to vertical surface movement
		var vel = state.linear_velocity - Vector3(0, dhdt, 0)
		var vel_local = rotation.inverse() * vel
		var drag_local = -vel_local * buoyancy_linear_damp
		var drag = rotation * drag_local
		state.add_central_force(force + drag)

		var torque = state.transform.basis.y.cross(hnor)
		# Apply torque scaling factors in local space
		var torque_local = rotation.inverse() * torque
		var angvel_local = rotation.inverse() * state.angular_velocity
		torque_local = torque_local * buoyancy_torque - angvel_local * buoyancy_angular_damp
		torque = rotation * torque_local
		state.add_torque(torque)
		
		_draw_forces(state, force, drag, torque)
