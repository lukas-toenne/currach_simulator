extends Boat

@export var oar_height_bias : float = 0.0
@export var forward_force : float = 1.0
@export var back_force : float = 1.0
@export var stop_drag : float = 1.0

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var skel: Skeleton3D = get_node("CollisionShape/skiff/SkiffRig/Skeleton")
@onready var hull: int = skel.find_bone("hull")
@onready var oar_info_l: SkiffOarInfo = SkiffOarInfo.new(self, skel, "oarlock_l", "oar_blade_l", "force_l", "OarAudioL")
@onready var oar_info_r: SkiffOarInfo = SkiffOarInfo.new(self, skel, "oarlock_r", "oar_blade_r", "force_r", "OarAudioR")

const ANIM_IDLE = 0
const ANIM_FORWARD = 1
const ANIM_BACK = 2
const ANIM_STOP = 3

class SkiffInputState:
	var forward = false
	var back = false
	var stop = false
	var _idle
	var idle:
		get:
			return !forward && !back && !stop
	var fast = false

class SkiffOarInfo:
	var bone_oarlock: int
	var bone_oarlock_parent: int
	var bone_blade: int
	var bone_force: int
	var audio_stream: AudioStreamPlayer3D

	static func _get_bone_rest_global(skeleton: Skeleton3D, bone: int):
		var rest = skeleton.get_bone_rest(bone)
		var parent = skeleton.get_bone_parent(bone)
		while parent:
			rest = skeleton.get_bone_rest(parent) * rest
			parent = skeleton.get_bone_parent(parent)
		return rest
	
	static func _get_bone_diff_rest(skeleton: Skeleton3D, bone: int, ref_bone: int):
		var diff = skeleton.get_bone_rest(bone)
		var parent = skeleton.get_bone_parent(bone)
		while parent and parent != ref_bone:
			diff = skeleton.get_bone_rest(parent) * diff
			parent = skeleton.get_bone_parent(parent)
		return diff

	static func _get_node_diff(node: Node3D, ref_node: Node3D):
		return ref_node.global_transform.inverse() * node.global_transform
	
	static func _get_bone_diff(skeleton: Skeleton3D, bone: int, ref_bone: int):
		return skeleton.get_bone_global_pose(ref_bone).inverse() * skeleton.get_bone_global_pose(bone)
	
	func _init(node: Node3D, skeleton: Skeleton3D, name_oarlock: String, name_blade: String, name_force: String, name_audio: String):
		bone_oarlock = skeleton.find_bone(name_oarlock)
		bone_oarlock_parent = skeleton.get_bone_parent(bone_oarlock)
		bone_blade = skeleton.find_bone(name_blade)
		bone_force = skeleton.find_bone(name_force)
		audio_stream = node.get_node(name_audio)
	
	func apply_anim(node: Node3D, skeleton: Skeleton3D):
		# Current rotated skeleton transform
		var skel_tfm_rest = _get_node_diff(skeleton, node)
		var skel_tfm = Transform3D(node.transform.basis) * skel_tfm_rest
		var blade_rest_pos = _get_bone_diff_rest(skeleton, bone_blade, bone_oarlock_parent).origin
		var source = skel_tfm * skeleton.get_bone_global_pose(bone_oarlock_parent) * blade_rest_pos
		var target = skel_tfm_rest * _get_bone_rest_global(skeleton, bone_blade).origin

		# Make source and target relative to the oarlock rest pose,
		# so they can be applied as a custom pose on top
		var node_to_oarlock = (skel_tfm * _get_bone_rest_global(skeleton, bone_oarlock)).inverse()
		source = node_to_oarlock * source
		target = node_to_oarlock * target

		var target_y = node.oar_height_bias + target.y
		var target_x_sqr = source.x*source.x + source.y*source.y - target_y*target_y
		if target_x_sqr > 0.0:
			var alpha = -sign(source.x) * 2.0 * atan2(-abs(source.x) + sqrt(target_x_sqr), source.y + target_y)
			assert(!is_nan(alpha))
			skeleton.set_bone_custom_pose(bone_oarlock, Transform3D(Quaternion(Vector3(0, 0, alpha))))

	func apply_force(node: Node3D, skeleton: Skeleton3D, physics_state: PhysicsDirectBodyState3D, input_state: SkiffInputState):
		var force = 0.0
		if input_state.idle:
			pass
		elif input_state.stop:
			force = -node.stop_drag * (physics_state.transform.basis.inverse() * physics_state.linear_velocity).z
		elif input_state.forward:
			force = -node.forward_force
		elif input_state.back:
			force = node.back_force
		var force_factor = skeleton.get_bone_pose(bone_force).origin.y
		force *= force_factor
		if force != 0.0:
			var skel_tfm_rest = _get_node_diff(skeleton, node)
			var skel_tfm = Transform3D(physics_state.transform.basis) * skel_tfm_rest
			var dir = skel_tfm.basis * Vector3(0, 0, 1)
			dir.y = 0.0
			dir = dir.normalized()
			force = dir * force
			
			# Offset in world space, relative to origin
			var offset = skel_tfm * skeleton.get_bone_global_pose(bone_blade).origin
			node.add_force(force, offset)
			
#			var draw_point = physics_state.transform.origin + offset + Vector3(0, 2, 0)
#			DebugDraw.draw_line_3d(draw_point, draw_point + force, Color(1, 0, 0))

	func apply_audio(node: Node3D, skeleton: Skeleton3D):
		var force_factor = skeleton.get_bone_pose(bone_force).origin.y
		audio_stream.unit_db = lerp(-2.0, 10.0, force_factor)

func _ready():
	set_process_input(true)
#	._ready()

func _get_input_state(side):
	var state = SkiffInputState.new()
	state.forward = Input.is_action_pressed("forward_" + side)
	state.back = Input.is_action_pressed("back_" + side)
	state.stop = Input.is_action_pressed("stop_" + side)
	state.fast = Input.is_action_pressed("fast_" + side)
	return state

func _anim_transition(param: String, anim: int):
	if anim_tree[param + "/current"] != anim:
		anim_tree[param + "/current"] = anim

func _apply_input_state(param: String, state: SkiffInputState):
	if state.idle:
		_anim_transition(param, ANIM_IDLE)
	elif state.stop:
		_anim_transition(param, ANIM_STOP)
	elif state.forward:
		_anim_transition(param, ANIM_FORWARD)
	elif state.back:
		_anim_transition(param, ANIM_BACK)

func _process(delta):
	oar_info_l.apply_anim(self, skel)
	oar_info_r.apply_anim(self, skel)
	
	oar_info_l.apply_audio(self, skel)
	oar_info_r.apply_audio(self, skel)
	
	var state_right = _get_input_state("right")
	var state_left = _get_input_state("left")
	
	_apply_input_state("parameters/TransitionRight", state_right)
	_apply_input_state("parameters/TransitionLeft", state_left)


#func _input(event):
#	pass

func _integrate_forces(state):
	super._integrate_forces(state)
	oar_info_l.apply_force(self, skel, state, _get_input_state("left"))
	oar_info_r.apply_force(self, skel, state, _get_input_state("right"))
