shader_type canvas_item;

// hash and noise functions by Inigo Quilez, published under MIT license
// https://www.shadertoy.com/view/Xsl3Dl
//
// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

vec3 hash(vec3 p) {
	p = vec3(
		dot(p, vec3(127.1, 311.7, 74.7)),
		dot(p, vec3(269.5, 183.3, 246.1)),
		dot(p, vec3(113.5, 271.9, 124.6)));

	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);

	float d000 = dot(hash(i + vec3(0.0, 0.0, 0.0)), f - vec3(0.0, 0.0, 0.0));
	float d100 = dot(hash(i + vec3(1.0, 0.0, 0.0)), f - vec3(1.0, 0.0, 0.0));
	float d010 = dot(hash(i + vec3(0.0, 1.0, 0.0)), f - vec3(0.0, 1.0, 0.0));
	float d110 = dot(hash(i + vec3(1.0, 1.0, 0.0)), f - vec3(1.0, 1.0, 0.0));
	float d001 = dot(hash(i + vec3(0.0, 0.0, 1.0)), f - vec3(0.0, 0.0, 1.0));
	float d101 = dot(hash(i + vec3(1.0, 0.0, 1.0)), f - vec3(1.0, 0.0, 1.0));
	float d011 = dot(hash(i + vec3(0.0, 1.0, 1.0)), f - vec3(0.0, 1.0, 1.0));
	float d111 = dot(hash(i + vec3(1.0, 1.0, 1.0)), f - vec3(1.0, 1.0, 1.0));

	float m_00 = mix(d000, d100, u.x);
	float m_10 = mix(d010, d110, u.x);
	float m_01 = mix(d001, d101, u.x);
	float m_11 = mix(d011, d111, u.x);
	float m__0 = mix(m_00, m_10, u.y);
	float m__1 = mix(m_01, m_11, u.y);
	float m___ = mix(m__0, m__1, u.z);
	return m___;
}

vec3 dnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	vec3 du = 6.0 * f * (1.0 - f);

	vec3 dd000 = hash(i + vec3(0.0, 0.0, 0.0));
	vec3 dd100 = hash(i + vec3(1.0, 0.0, 0.0));
	vec3 dd010 = hash(i + vec3(0.0, 1.0, 0.0));
	vec3 dd110 = hash(i + vec3(1.0, 1.0, 0.0));
	vec3 dd001 = hash(i + vec3(0.0, 0.0, 1.0));
	vec3 dd101 = hash(i + vec3(1.0, 0.0, 1.0));
	vec3 dd011 = hash(i + vec3(0.0, 1.0, 1.0));
	vec3 dd111 = hash(i + vec3(1.0, 1.0, 1.0));

	float d000 = dot(dd000, f - vec3(0.0, 0.0, 0.0));
	float d100 = dot(dd100, f - vec3(1.0, 0.0, 0.0));
	float d010 = dot(dd010, f - vec3(0.0, 1.0, 0.0));
	float d110 = dot(dd110, f - vec3(1.0, 1.0, 0.0));
	float d001 = dot(dd001, f - vec3(0.0, 0.0, 1.0));
	float d101 = dot(dd101, f - vec3(1.0, 0.0, 1.0));
	float d011 = dot(dd011, f - vec3(0.0, 1.0, 1.0));
	float d111 = dot(dd111, f - vec3(1.0, 1.0, 1.0));

	float m_00 = mix(d000, d100, u.x);
	float m_10 = mix(d010, d110, u.x);
	float m_01 = mix(d001, d101, u.x);
	float m_11 = mix(d011, d111, u.x);
	float m__0 = mix(m_00, m_10, u.y);
	float m__1 = mix(m_01, m_11, u.y);
	float m___ = mix(m__0, m__1, u.z);

	vec3 dm_00 = mix(dd000, dd100, u.x) +  vec3((d100 - d000) * du.x, 0, 0);
	vec3 dm_10 = mix(dd010, dd110, u.x) + vec3((d110 - d010) * du.x, 0, 0);
	vec3 dm_01 = mix(dd001, dd101, u.x) + vec3((d101 - d001) * du.x, 0, 0);
	vec3 dm_11 = mix(dd011, dd111, u.x) + vec3((d111 - d011) * du.x, 0, 0);
	vec3 dm__0 = mix(dm_00, dm_10, u.y) + vec3(0, (m_10 - m_00) * du.y, 0);
	vec3 dm__1 = mix(dm_01, dm_11, u.y) + vec3(0, (m_11 - m_01) * du.y, 0);
	vec3 dm___ = mix(dm__0, dm__1, u.z) + vec3(0, 0, (m__1 - m__0) * du.z);
	return dm___;
}

float fbm(vec3 x) {
	float height = 0.0;
	float wave_amplitude = 0.5;
	float frequency = 1.0;
	for (int i = 0; i < 3; i++){
		height += noise(x * frequency) * wave_amplitude;
		wave_amplitude *= 0.5;
		frequency *= 2.0;
	}
	return height;
}

vec3 dfbm(vec3 x) {
	vec3 dheight = vec3(0);
	float wave_amplitude = 0.5;
	float frequency = 1.0;
	for (int i = 0; i < 3; i++){
		dheight += dnoise(x * frequency) * wave_amplitude * frequency;
		wave_amplitude *= 0.5;
		frequency *= 2.0;
	}
	return dheight;
}


const float PI = 3.14159265359;

float rect(float x)
{
	float ax = abs(x);
	return ax < 0.5 ? 1.0 : (ax == 0.5 ? 0.5 : 0.0);
}

// Compression for derivative colors to fit into 0..1 range.
uniform float wave_kernel_color_factor = 0.5;

void wave_kernel_normalized(vec2 p, float lambda, float dt, out vec3 X, out mat3 dXdp, out vec4 color)
{
	vec3 dist = vec3(p.x, 0, p.y);

	// Envelope
	float l = length(dist);
	vec3 dldp = normalize(dist);
	float D = 0.5 * (cos(PI * l) + 1.0) * rect(0.5 * l);
	vec3 dDdp = -0.5 * sin(PI * l) * rect(0.5 * l) * PI * dldp;
	
	vec3 dir = vec3(1, 0, 0);

	float u = dot(dist, dir);
	vec3 dudp = dir;
	float w = 2.0 * PI * u / lambda;
	vec3 dwdp = 2.0 * PI * dudp / lambda;

	vec3 L = -sin(w) * dir;
	mat3 dLdp = -cos(w) * outerProduct(dir, dwdp);
	vec3 H = vec3(0, cos(w), 0);
	mat3 dHdp = transpose(mat3(vec3(0, 0, 0), -sin(w) * dwdp, vec3(0, 0, 0)));
	
	X = (L + H) * D;
	dXdp = (dLdp + dHdp) * D + outerProduct(L + H, dDdp);
	
	float rim_thickness = 0.01;
	float rim = abs(l - 1.0 + rim_thickness) < rim_thickness ? 1.0 : 0.0;
	float arrow = p.x > -0.4 && p.y > p.x * 0.25 - 0.14 && p.y < 0.14 - p.x * 0.25 ? 1.0 : 0.0;
	color = vec4(rim, arrow, D, 1);
}

// Output types:
// 0: Position P
// 1: dP/dx * 0.25
// 2: dP/dy * 0.25
// 3: dP/dz * 0.25
// 4: Particle indicator
// 5: UV coordinates (for debugging)
// 6: Normal map (for debugging)
uniform int output_type = 0;

void fragment()
{
	float lambda = 2.0;
	
	vec2 wpos = UV * 2.0 - 1.0;
	
	vec3 ker_X;
	mat3 ker_dXdp;
	vec4 ker_color;
	wave_kernel_normalized(wpos, lambda, 0.0, ker_X, ker_dXdp, ker_color);

	switch (output_type)
	{
		case 0:
		    COLOR = vec4(ker_X * 0.5 + 0.5, 1);
			break;
		case 1:
		    COLOR = vec4(ker_dXdp[0] * 0.5 * wave_kernel_color_factor + 0.5, 1);
			break;
		case 2:
		    COLOR = vec4(ker_dXdp[1] * 0.5 * wave_kernel_color_factor + 0.5, 1);
			break;
		case 3:
		    COLOR = vec4(ker_dXdp[2] * 0.5 * wave_kernel_color_factor + 0.5, 1);
			break;
		case 4:
		    COLOR = ker_color;
			break;
		case 5:
			int res = 10;
			vec2 rpos = (wpos * 0.5 + 0.5) * float(res);
			int i = int(floor(rpos.x));
			int j = int(floor(rpos.y));
			bool checker = (i + j) % 2 == 0;
		    COLOR = checker ? vec4(floor(rpos) / float(res), 0, 1) : vec4(.5, .5, .5, 1);
			break;
		case 6:
			mat3 nortfm = transpose(inverse(mat3(1) + ker_dXdp * 0.25));
			vec3 normal = normalize(nortfm * vec3(0, 1, 0));
//			normal = vec3()
		    COLOR = vec4(normal * 0.5 + 0.5, 1);
			break;
	}
}
