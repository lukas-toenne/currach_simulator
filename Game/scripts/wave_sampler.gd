extends Node

class_name WaveSampler

# Wave sampler has early priority so wave samples are available during _process.
const WAVE_SAMPLER_PROCESS_PRIORITY = -1000

@export var shader : Shader = preload("res://shaders/wave_sample.gdshader")

var time = 0.0

var viewport: Viewport
var rect: ColorRect

var points: PackedVector2Array
var points_updated: bool = false

const pos_format = Image.FORMAT_RGF
var pos_image: Image
var pos_tex: ImageTexture

var image: Image
var image_updated = false

# Allocate enough pixels to store all output data.
const PIXELS_PER_POINT = 2

## Maximum width of a data texture, rows can be partially filled.
#const tex_width = 1024
## Allocation size when the texture is growing, should be multiple of tex_width.
#const block_size = 4096
## Allowed slack size when the texture is shrinking, should be multiple of tex_width.
#const slack_size = 16384
# Maximum width of a data texture, rows can be partially filled.
const tex_width = 16
# Allocation size when the texture is growing, should be multiple of tex_width.
const block_size = 64
# Allowed slack size when the texture is shrinking, should be multiple of tex_width.
const slack_size = 256
const slack_rows = int((slack_size + tex_width - 1) / tex_width)

func _init():
	pos_image = Image.new()
	pos_tex = ImageTexture.new()

func _create_viewport():
	var viewport = Viewport.new()
	viewport.size = Vector2(2, 2)
	# Needs to be 3D_NO_EFFECTS usage and hdr=true, to enable full range float output
	viewport.usage = Viewport.USAGE_3D_NO_EFFECTS
	viewport.hdr = true
	# Disable sRGB transform on output colors
	viewport.keep_3d_linear = true
	viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
#	viewport.render_target_clear_mode = Viewport.CLEAR_MODE_NEVER
	return viewport

func _create_rect():
	var rect = ColorRect.new()
	rect.anchor_left = 0
	rect.anchor_top = 0
	rect.anchor_right = 1
	rect.anchor_bottom = 1
	rect.margin_left = 0
	rect.margin_top = 0
	rect.margin_right = 0
	rect.margin_bottom = 0
	rect.rect_size = Vector2(2, 2)
	rect.material = ShaderMaterial.new()
	rect.material.shader = shader
	rect.material.set_shader_param("positions", pos_tex)
	return rect

func _enter_tree():
	viewport = _create_viewport()
	rect = _create_rect()
	add_child(viewport)
	viewport.add_child(rect)

func _exit_tree():
	remove_child(viewport)
	viewport.free()
	viewport = null

# Ensure the image buffer is allocated and sufficiently large.
# Returns true if the image has been reallocated and the texture needs to call create_from_image.
# See comment here: https://docs.godotengine.org/en/stable/classes/class_imagetexture.html#class-imagetexture-method-set-data
func _ensure_image_size(image: Image, size: int, format) -> bool:
	size = max(size, 1)
	var tex_height = int((size + tex_width - 1) / tex_width)

	var aligned_size = int((size + block_size - 1) / block_size) * block_size
	var aligned_height = int((aligned_size + tex_width - 1) / tex_width)
	
	var realloc
	if image.is_empty() or image.get_format() != format or image.has_mipmaps():
		realloc = true
	elif image.get_height() < tex_height:
		realloc = true
	elif image.get_height() > tex_height + slack_rows:
		realloc = true
	else:
		realloc = false
	
	if realloc:
		image.create(tex_width, aligned_height, false, format)
	
	return realloc

func _update_positions():
	var old_size = pos_image.get_size()
	var realloc_pos = _ensure_image_size(pos_image, points.size(), pos_format)
	
	pos_image.lock()
	for i in range(points.size()):
		var x = i % tex_width
		var y = int(i / tex_width)
		var pt = points[i]
		pos_image.set_pixel(x, y, Color(pt.x, pt.y, 0.0))
	pos_image.unlock()
	
	var resize_viewport = false
	if realloc_pos:
		pos_tex.create_from_image(pos_image)
		resize_viewport = true
	else:
		pos_tex.set_data(pos_image)
		resize_viewport = (pos_image.get_size() != old_size)
	
	if resize_viewport:
		# Multiple pixels per point to store all output values.
		var output_size = Vector2(pos_image.get_width() * PIXELS_PER_POINT, pos_image.get_height())
		viewport.size = output_size
		rect.rect_size = output_size

func _ready():
	RenderingServer.frame_pre_draw.connect(_on_VisualServer_pre_draw)
	RenderingServer.frame_post_draw.connect(_on_VisualServer_post_draw)

func _on_VisualServer_pre_draw():
	if points_updated:
		_update_positions()
		points.resize(0)
		points_updated = false

		image_updated = true

func _on_VisualServer_post_draw():
	if image_updated:
		image = viewport.get_texture().get_data()
		image_updated = false

func _process(delta):
	time += delta
	rect.material.set_shader_param("time", time)
	rect.material.set_shader_param("delta_time", delta)

func add_point(position: Vector2) -> int:
	points.push_back(position)
	points_updated = true
	return points.size() - 1

# Returns array: [position, speed (dh/dt), derivative (dh/dx, dh/dz)]
func get_wave(index: int):
	if image:
		var x = index % tex_width
		var y = int(index / tex_width)
		if x >= 0 and y >= 0:
			image.lock()
			var col1 = image.get_pixel(x * PIXELS_PER_POINT + 0, y)
			var col2 = image.get_pixel(x * PIXELS_PER_POINT + 1, y)
			image.unlock()
			return [Vector3(col1.r, col1.g, col1.b), col2.r, Vector2(col2.g, col2.b)]
	return [Vector3(0, 0, 0), 0.0, Vector2(0, 0)]
