extends MeshInstance

class_name WaterSurface

class DualValue:
	var val: float
	var dval: Vector3
	
	func _init(var _val, var _dval):
		val = _val
		dval = _dval

###### hash and noise functions by Inigo Quilez, published under MIT license ######
#
# The MIT License
# Copyright © 2013 Inigo Quilez
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
func vhash(p: Vector3) -> Vector3:
	var v = Vector3(p.dot(Vector3(127.1, 311.7, 74.7)),
					p.dot(Vector3(269.5, 183.3, 246.1)),
					p.dot(Vector3(113.5, 271.9, 124.6)))
	v = Vector3(sin(v.x), sin(v.y), sin(v.z)) * 43758.5453123
	v -= v.floor()
	return 2.0 * v - Vector3(1, 1, 1)

func noise(p: Vector3) -> float:
	var i = p.floor()
	var f = p - p.floor()
	var u = Vector3(f.x * f.x * (3.0 - 2.0 * f.x), f.y * f.y * (3.0 - 2.0 * f.y), f.z * f.z * (3.0 - 2.0 * f.z))

	return lerp(lerp(lerp(vhash(i + Vector3(0.0, 0.0, 0.0)).dot(f - Vector3(0.0, 0.0, 0.0)),
						vhash(i + Vector3(1.0, 0.0, 0.0)).dot(f - Vector3(1.0, 0.0, 0.0)), u.x),
					lerp(vhash(i + Vector3(0.0, 1.0, 0.0)).dot( - Vector3(0.0, 1.0, 0.0)),
						vhash(i + Vector3(1.0, 1.0, 0.0)).dot(f - Vector3(1.0, 1.0, 0.0)), u.x), u.y),
				lerp(lerp(vhash(i + Vector3(0.0, 0.0, 1.0)).dot(f - Vector3(0.0, 0.0, 1.0)),
						vhash(i + Vector3(1.0, 0.0, 1.0)).dot(f - Vector3(1.0, 0.0, 1.0)), u.x),
					lerp(vhash(i + Vector3(0.0, 1.0, 1.0)).dot(f - Vector3(0.0, 1.0, 1.0)),
						vhash(i + Vector3(1.0, 1.0, 1.0)).dot(f - Vector3(1.0, 1.0, 1.0)), u.x), u.y), u.z)
###### 

func fbm(x: Vector3) ->float:
	var height = 0.0
	var amplitude = 0.5
	var frequency = 1.0
	for i in range(3):
		height += noise(x * frequency) * amplitude
		amplitude *= 0.5
		frequency *= 2.0
	return height


var time = 0.0
var wave_length = 10.0
var phase_speed = 1.0
var phase = 0.0
var amplitude_linear = 1.0
var amplitude_random = 1.0
var direction = Vector2(1, 0)

func _ready():
	wave_length = get_surface_material(0).get_shader_param("wave_length")
	phase_speed = get_surface_material(0).get_shader_param("phase_speed")
	phase = get_surface_material(0).get_shader_param("phase")
	amplitude_linear = get_surface_material(0).get_shader_param("amplitude_linear")
	amplitude_random = get_surface_material(0).get_shader_param("amplitude_random")
	direction = get_surface_material(0).get_shader_param("direction")
	
	get_surface_material(0).shader.custom_defines = "#define HELLO_WORLD=1"
	print(get_surface_material(0).shader.custom_defines)

func _process(delta):
	time += delta
	
	get_surface_material(0).set_shader_param("time", time)

func _waves_linear(pos: Vector2, t: float) -> float:
	var k = 2.0 * PI / wave_length * direction.normalized()
	var h = sin(k.dot(pos) - phase_speed * t + phase)
	return h

func _waves_random(pos: Vector2, t: float) -> float:
	var k = 2.0 * PI / wave_length;
	return fbm(Vector3(k * pos.x, k * pos.y, phase_speed * t + phase))

func _waves_sum(pos: Vector2, t: float) -> float:
	return amplitude_linear * _waves_linear(pos, t) + amplitude_random * _waves_random(pos, t)

#void trochoidal_wave(inout vec2 pos, float val, vec2 dval)
#{
#	float totamp = amplitude_linear + amplitude_random;
#	float nval = val / totamp;
#	vec2 ofs = dval * sqrt(1.0 - nval*nval);
#	pos -= ofs;
#}

# Returns array: [height, speed (dh/dt), normal]
func waves(pos: Vector2, t: float, dt: float):
	var eps = 0.1
	var ex = Vector2(eps, 0.0)
	var ey = Vector2(0.0, eps)

	var h = _waves_sum(pos, t)
	var dhdt = (_waves_sum(pos, t + dt) - h) / dt if dt > 0.0 else 0.0
	var dhdp = Vector2(_waves_sum(pos + ex, t) - _waves_sum(pos - ex, t), _waves_sum(pos + ey,t ) - _waves_sum(pos - ey, t)) / (2.0*eps)

#	trochoidal_wave(pos, h, dhdp)
#	dhdp = Vector2(_waves_sum(pos + e.xy, t) - _waves_sum(pos - e.xy, t), _waves_sum(pos + e.yx, t) - _waves_sum(pos - e.yx, t)) / (2.0*eps)

	var normal = Vector3(-dhdp.x, 1.0, -dhdp.y).normalized()
	return [h, dhdt, normal]

func get_plane(pos : Vector2) -> Plane:
	var res = waves(pos, time, 0.0)
	return Plane(res[1].x, res[1].y, res[1].z, res[0] * res[1].y)

func get_height(pos : Vector2) -> float:
	var res = waves(pos, time, 0.0)
	return res[0]
