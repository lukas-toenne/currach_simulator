shader_type canvas_item;

// BEGIN_IMPORT res://shaders/waves.gdshader

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

uniform float wave_amplitude = 0.1;
uniform float wave_length = 3.0;
uniform float wave_speed = 1.0;
uniform float wave_lifetime = 3.0;
uniform float wave_radius = 3.0;

uniform sampler2D u_terrain_heightmap;
uniform sampler2D u_terrain_normalmap;
uniform mat4 u_terrain_inverse_transform;
uniform mat3 u_terrain_normal_basis;
uniform float u_terrain_height_min = -1.0;
uniform float u_terrain_height_max = 1.0;

uniform sampler2D flow_map;
uniform vec2 flow_map_origin = vec2(0, 0);
uniform vec2 flow_map_scale = vec2(1, 1);
uniform int flow_samples = 20;

float cell_size()
{
	return wave_speed * wave_lifetime + wave_radius;
}

vec3 unpack_normal(vec4 rgba) {
	vec3 n = rgba.xzy * 2.0 - vec3(1.0);
	// Had to negate Z because it comes from Y in the normal map,
	// and OpenGL-style normal maps are Y-up.
	n.z *= -1.0;
	return n;
}

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

void wave_kernel(vec2 p, float A, vec2 center, vec2 travel, float lambda, float dt, out vec3 X, out vec3 dXdt, out mat3 dXdp, out float color)
{
	float r = wave_radius;
	vec3 dist = vec3(p.x - center.x, 0, p.y - center.y);

	// Envelope
	float l = length(dist) / r;
	vec3 dldp = dist / (length(dist) * r);
	float D = A * 0.5 * (cos(PI * l) + 1.0) * rect(0.5 * l);
	vec3 dDdp = -A * 0.5 * sin(PI * l) * rect(0.5 * l) * PI * dldp;
	
	vec3 dir = normalize(vec3(travel.x, 0, travel.y));

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
	
	vec3 ortho = vec3(dir.y, 0, -dir.x);
	float v = dot(dist, ortho);
	vec3 local = vec3(u, v, 0);
	
	color = 0.5 * (cos(PI * l) + 1.0) * rect(0.5 * l) * 0.2;
	if (abs(l - 1.0) < 0.01)
	{
		color = 1.0;
	}
}

float rayleigh_sample(float mean, float u)
{
	return mean * sqrt(max(-4.0 / PI * log(1.0 - u), 0.0));
}

void wave_sample(vec2 cell, int seed, float t, vec3 terrain_normal, out float amp, out vec2 start, out float dir, out float lambda, out float alpha, out vec3 color)
{
	vec3 rand1 = hash(vec3(float(seed), cell.y, cell.x)) * 0.5 + 0.5;
	float phase_shift = rand1.x;
	// XXX Precision could suffer for large t, problem?
	// Should keep a rolling value in 0..1 range incremenenting by dt,
	// but has to happen outside of the shader.
	float sample_phase = t / wave_lifetime + phase_shift;
	alpha = fract(sample_phase);
	// Derived seed value that changes with each iteration
	float nseed = float(seed) + 82.3 * floor(sample_phase);
	vec3 rand2 = hash(vec3(cell.x, cell.y, nseed)) * 0.5 + 0.5;
	vec3 rand3 = hash(vec3(cell.y, nseed, cell.x)) * 0.5 + 0.5;

	amp = wave_amplitude;
	lambda = wave_length;
//	float freq = rayleigh_sample(wave_speed / wave_length, rand2.x);
//	float freq2 = freq * freq;
//	float freq4 = freq2 * freq2;
//	float freq5 = freq4 * freq;
//	float B = 1.0;
//	amp = wave_amplitude * exp(-B / freq4) / freq5 * 1000.0;
//	lambda = wave_speed / freq;
	// Clamp wave_amplitude to avoid overlap at the crest.
	amp = min(amp, 0.5 * lambda / PI);

	start = (cell + rand3.xy) * cell_size();

// >>> FLOW METHODS
//	vec2 flow_uv = (start - flow_map_origin) / flow_map_scale;
//	vec4 flow = textureLod(flow_map, flow_uv, 0.0);
//	dir = 6.0 * PI * flow.r;

//	dir = 2.0 * PI * rand3.z;

	float terrain_dir = atan(-terrain_normal.z, -terrain_normal.x);
	dir = terrain_dir;
// <<< FLOW METHODS

	color = rand2;
}

void wave_sum(vec4 wpos, float t, float dt, out vec3 X, out vec3 dXdt, out mat3 dXdp, out vec3 particle_color)
{
	X = wpos.xyz;
	dXdp = mat3(vec3(1, 0, 0), vec3(0, 1, 0), vec3(0, 0, 1));
	dXdt = vec3(0, 0, 0);
	particle_color = vec3(0.0);

	float travel_dist = wave_speed * wave_lifetime;
	float dalpha = dt / wave_lifetime;
	
	float cx = floor(wpos.x / cell_size());
	float cy = floor(wpos.z / cell_size());

	vec2 terrain_cell_coords = (u_terrain_inverse_transform * wpos).xz / 16.0;
	// Must add a half-offset so that we sample the center of pixels,
	// otherwise bilinear filtering of the textures will give us mixed results (#183)
	terrain_cell_coords += vec2(0.5);
	// Normalized UV
	vec2 terrain_uv = terrain_cell_coords / vec2(textureSize(u_terrain_heightmap, 0));
	// Height displacement
	float terrain_height = texture(u_terrain_heightmap, terrain_uv).r;

	// TODO choose LOD for terrain normal texture such that it averages over the whole wave cell,
	// i.e. LOD = ceil(log2(wave_cell_size / terrain_cell_size)),
	// where terrain_cell_size = terrain_transform * vec3(1)
	// Ideally the wave cell size should be a multiple of the terrain cell size!

	// Need to use u_terrain_normal_basis to handle scaling.
	vec3 terrain_normal = u_terrain_normal_basis * unpack_normal(texture(u_terrain_normalmap, terrain_uv));
	
	for (int j = -1; j <= 1; ++j)
	{
		for (int i = -1; i <= 1; ++i)
		{
			for (int k = 0; k < flow_samples; ++k)
			{
				vec2 cell = vec2(cx + float(i), cy + float(j));
				
				float amp;
				vec2 start;
				float dir;
				float lambda;
				float alpha;
				vec3 color;
				wave_sample(cell, k, t, terrain_normal, amp, start, dir, lambda, alpha, color);

				vec2 travel = vec2(cos(dir), sin(dir)) * travel_dist;
				vec2 center = start + alpha * travel;

				// Time envelope
				float timefac = 0.5 * (1.0 - cos(2.0 * PI * alpha));
				amp *= timefac;
				color *= timefac;

				vec3 ker_X;
				mat3 ker_dXdp;
				vec3 ker_dXdt;
				float ker_color;
				wave_kernel(wpos.xz, amp, center, travel, lambda, dt, ker_X, ker_dXdt, ker_dXdp, ker_color);

				X += ker_X;
				dXdp = dXdp + ker_dXdp;
				dXdt += ker_dXdt;
				particle_color += ker_color * color;
			}
		}
	}
	
//	float r = normalize(terrain_normal).x;
//	float r = terrain_uv.x * 0.001;
//	float r = clamp((h - terrain_height_min) / (terrain_height_max - terrain_height_min), 0, 1);
	float r = terrain_height * 1.0;
	particle_color = vec3(1.0 - r, r, 0);
//	particle_color = texture(terrain_normalmap, terrain_uv).xyz;
//	particle_color += terrain_normal * vec3(1, 0, 1);
}

void waves(vec4 wpos, float t, float dt, out vec3 position, out vec3 velocity, out vec3 normal, out vec3 tangent, out float foam, out vec3 particle_color)
{
	vec3 X;
	mat3 dXdp;
	vec3 dXdt;

//	wave_kernel(p, wave_amplitude, vec2(0, 0), normalize(linear_direction), dt, X, dXdt, dXdp, local, envelope);
//	wave_sample(p, wave_amplitude, vec2(-4, 2), vec2(8, -5), 0.5, 0.1, X, dXdt, dXdp, local, envelope);
	wave_sum(wpos, t, dt, X, dXdt, dXdp, particle_color);

	position = X;
	velocity = dXdt;
	mat3 nortfm = transpose(inverse(dXdp));
	normal = normalize(nortfm * vec3(0, 1, 0));
	tangent = normalize(nortfm * vec3(0, 0, 1));
	
	foam = clamp(1.0 - determinant(dXdp), 0, 1);
}

// END_IMPORT

// Based on water shader by Ronny Mühle, published under MIT license
// https://github.com/Platinguin/Godot-Water-Shader-Prototype
//
//MIT License
//
//Copyright (c) 2020 Ronny Mühle
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

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
