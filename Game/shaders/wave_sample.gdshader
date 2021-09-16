shader_type canvas_item;
render_mode blend_disabled, unshaded;

// BEGIN_IMPORT res://shaders/waves.gdshader

// hash and noise functions by Inigo Quilez, published under MIT license
// https://www.shadertoy.com/view/Xsl3Dl
//
// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

vec3 hash(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));

    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec3 p) {
  vec3 i = floor(p);
  vec3 f = fract(p);
  vec3 u = f * f * (3.0 - 2.0 * f);

  return mix(mix(mix(dot(hash(i + vec3(0.0, 0.0, 0.0)), f - vec3(0.0, 0.0, 0.0)),
                     dot(hash(i + vec3(1.0, 0.0, 0.0)), f - vec3(1.0, 0.0, 0.0)), u.x),
                 mix(dot(hash(i + vec3(0.0, 1.0, 0.0)), f - vec3(0.0, 1.0, 0.0)),
                     dot(hash(i + vec3(1.0, 1.0, 0.0)), f - vec3(1.0, 1.0, 0.0)), u.x), u.y),
             mix(mix(dot(hash(i + vec3(0.0, 0.0, 1.0)), f - vec3(0.0, 0.0, 1.0)),
                     dot(hash(i + vec3(1.0, 0.0, 1.0)), f - vec3(1.0, 0.0, 1.0)), u.x),
                 mix(dot(hash(i + vec3(0.0, 1.0, 1.0)), f - vec3(0.0, 1.0, 1.0)),
                     dot(hash(i + vec3(1.0, 1.0, 1.0)), f - vec3(1.0, 1.0, 1.0)), u.x), u.y), u.z );
}

float fbm(vec3 x) {
  float height = 0.0;
  float amplitude = 0.5;
  float frequency = 1.0;
  for (int i = 0; i < 3; i++){
    height += noise(x * frequency) * amplitude;
    amplitude *= 0.5;
    frequency *= 2.0;
  }
  return height;
}


const float PI = 3.14159265359;

uniform float wave_length = 10.0;
uniform float phase_speed = 1.0;
uniform float phase = 0.0;
uniform float amplitude_linear = 1.0;
uniform float amplitude_random = 1.0;
uniform vec2 direction = vec2(4.0, -1.0);

float waves_linear(vec2 pos, float t)
{
	vec2 k = 2.0 * PI / wave_length * normalize(direction);
	return sin(dot(k, pos) - phase_speed * t + phase);
}

float waves_random(vec2 pos, float t)
{
	float k = 2.0 * PI / wave_length;
	return fbm(vec3(k * pos, phase_speed * t + phase));
}

float waves_sum(vec2 pos, float t)
{
	return amplitude_linear * waves_linear(pos, t) + amplitude_random * waves_random(pos, t);
}

void trochoidal_wave(inout vec2 pos, float val, vec2 dval)
{
	float totamp = amplitude_linear + amplitude_random;
	float nval = val / totamp;
	vec2 ofs = dval * sqrt(1.0 - nval*nval);
	pos -= ofs;
}

void waves(vec2 pos, out vec3 vertex, out float dhdt, out vec2 dhdp, float t, float dt)
{
	float eps = 0.01;
	vec2 e = vec2(eps, 0.0);
	
	float h = waves_sum(pos, t);
	dhdt = dt > 0.0 ? (waves_sum(pos, t + dt) - h) / dt : 0.0;
	dhdp = vec2(waves_sum(pos + e.xy, t) - waves_sum(pos - e.xy, t), waves_sum(pos + e.yx, t) - waves_sum(pos - e.yx, t)) / (2.0*eps);
	
//	trochoidal_wave(pos, h, dh);
//	dh = vec2(waves_sum(pos + e.xy) - waves_sum(pos - e.xy), waves_sum(pos + e.yx) - waves_sum(pos - e.yx)) / (2.0*eps);
	
	vertex = vec3(pos.x, h, pos.y);
}

// END_IMPORT

const int PIXELS_PER_POINT = 2;

uniform float time = 0.0;
uniform float delta_time = 0.0;
uniform sampler2D positions;

void fragment()
{
	ivec2 input_uv = ivec2(int(FRAGCOORD.x) / PIXELS_PER_POINT, int(FRAGCOORD.y));
	vec4 pos = texelFetch(positions, input_uv, 0);

	vec3 wpos;
	float dhdt;
	vec2 dhdp;
	waves(pos.xy, wpos, dhdt, dhdp, time, delta_time);

	int pixel_type = int(FRAGCOORD.x) % PIXELS_PER_POINT;
	switch (pixel_type)
	{
		case 0:
			COLOR = vec4(wpos.xyz, 1.0);
			break;
		case 1:
			COLOR = vec4(dhdt, dhdp, 1.0);
			break;
	}
}





