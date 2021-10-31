shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, depth_draw_always;
//render_mode unshaded;

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

uniform float u_wave_amplitude = 0.1;
uniform float u_wave_density = 20;
uniform float wave_length = 3.0;
uniform float wave_speed = 1.0;
uniform float wave_lifetime = 3.0;
uniform float wave_radius = 3.0;
uniform sampler2D u_wave_kernel_pos;
uniform sampler2D u_wave_kernel_pos_dx;
uniform sampler2D u_wave_kernel_pos_dy;
uniform sampler2D u_wave_kernel_pos_dz;
uniform sampler2D u_wave_kernel_particle;

uniform sampler2D u_terrain_heightmap;
uniform sampler2D u_terrain_normalmap;
uniform mat4 u_terrain_inverse_transform;
uniform mat3 u_terrain_normal_basis;

uniform sampler2D flow_map;
uniform vec2 flow_map_origin = vec2(0, 0);
uniform vec2 flow_map_scale = vec2(1, 1);

// Make sure the particle simulation shaders and scripts are updated when changing width.
const int IDX_PARTICLE_START = 4;
const int WAVE_PARTICLE_PIXELS = 4;
const int WAVE_PARTICLE_TEXTURE_WIDTH = 1024;
uniform sampler2D u_wave_particles;
uniform int u_num_wave_particles;

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

// Compression for derivative colors to fit into 0..1 range.
uniform float wave_kernel_color_factor = 0.5;

// XXX Procedural kernel function: no texture lookup but lacks filtering (mipmaps)
//float rect(float x)
//{
//	float ax = abs(x);
//	return ax < 0.5 ? 1.0 : (ax == 0.5 ? 0.5 : 0.0);
//}
//void wave_kernel(vec2 p, float A, vec2 center, vec2 travel, float lambda, float dt, out vec3 X, out vec3 dXdt, out mat3 dXdp, out float color)
//{
//	float r = wave_radius;
//	vec3 dist = vec3(p.x - center.x, 0, p.y - center.y);
//
//	// Envelope
//	float l = length(dist) / r;
//	vec3 dldp = dist / (length(dist) * r);
//	float D = A * 0.5 * (cos(PI * l) + 1.0) * rect(0.5 * l);
//	vec3 dDdp = -A * 0.5 * sin(PI * l) * rect(0.5 * l) * PI * dldp;
//
//	vec3 dir = normalize(vec3(travel.x, 0, travel.y));
//
//	float u = dot(dist, dir);
//	vec3 dudp = dir;
//	float w = 2.0 * PI * u / lambda;
//	vec3 dwdp = 2.0 * PI * dudp / lambda;
//
//	vec3 L = -sin(w) * dir;
//	mat3 dLdp = -cos(w) * outerProduct(dir, dwdp);
//	vec3 H = vec3(0, cos(w), 0);
//	mat3 dHdp = transpose(mat3(vec3(0, 0, 0), -sin(w) * dwdp, vec3(0, 0, 0)));
//
//	X = (L + H) * D;
//	dXdp = (dLdp + dHdp) * D + outerProduct(L + H, dDdp);
//
//	vec3 ortho = vec3(dir.y, 0, -dir.x);
//	float v = dot(dist, ortho);
//	vec3 local = vec3(u, v, 0);
//
//	color = 0.5 * (cos(PI * l) + 1.0) * rect(0.5 * l) * 0.2;
//	if (abs(l - 1.0) < 0.01)
//	{
//		color = 1.0;
//	}
//}

void wave_kernel_uv(vec2 p, vec2 center, vec2 travel, float lambda, out vec2 kernel_uv, out mat2 kernel_duv, out mat3 kernel_matrix)
{
	vec2 dir = normalize(travel);
	mat2 rot = mat2(vec2(dir.x, -dir.y), vec2(dir.y, dir.x));
	kernel_uv = rot * (p - center) / lambda;
	kernel_duv = mat2(vec2(dir.x, -dir.y), vec2(dir.y, dir.x)) / lambda;
	kernel_matrix = mat3(vec3(dir.x, 0, dir.y), vec3(0, 1, 0), vec3(-dir.y, 0, dir.x));
}

void wave_add_kernel(
	vec4 wpos,
	vec3 world_dx,
	vec3 world_dy,
	vec2 center,
	vec2 travel,
	float amp,
	float lambda,
	float life,
	float random,
	inout vec3 X,
	inout vec3 dXdt,
	inout mat3 dXdp,
	inout vec3 color)
{
	vec2 ker_uv;
	mat2 ker_duv;
	mat3 ker_matrix;
	wave_kernel_uv(wpos.xz, center, travel, lambda, ker_uv, ker_duv, ker_matrix);
	if (ker_uv.x < 0.0 || ker_uv.x > 1.0 || ker_uv.y < 0.0 || ker_uv.y > 1.0)
	{
		return;
	}

	// Derivative of texture UV coordinates per screen pixel.
	ker_duv = ker_duv * mat2(world_dx.xz, world_dy.xz);
	
	// Time envelope
	float timefac = 0.5 * (1.0 - cos(2.0 * PI * life));
	amp *= timefac;
	random *= timefac;

	// XXX Procedural kernel function: no texture lookup but lacks filtering (mipmaps)
//	vec3 ker_X;
//	mat3 ker_dXdp;
//	vec3 ker_dXdt;
//	vec3 ker_color;
//	wave_kernel(wpos.xz, amp, center, travel, lambda, dt, ker_X, ker_dXdt, ker_dXdp, ker_color);

	ivec2 tex_size = textureSize(u_wave_kernel_particle, 0);
//				ivec2 tex_size_sq = tex_size * tex_size;
	ivec2 tex_size_sq = ivec2(1);
	// L2,1 norm used for LOD
	float ker_max = max(dot(ker_duv[0], ker_duv[0]) * float(tex_size_sq.x), dot(ker_duv[1], ker_duv[1]) * float(tex_size_sq.y));
	float ker_lod = 0.5 * log2(ker_max);

	vec3 ker_X = textureLod(u_wave_kernel_pos, ker_uv, ker_lod).rgb * 2.0 - 1.0;
	mat3 ker_dXdp = (mat3(
		textureLod(u_wave_kernel_pos_dx, ker_uv, ker_lod).xyz,
		textureLod(u_wave_kernel_pos_dy, ker_uv, ker_lod).xyz,
		textureLod(u_wave_kernel_pos_dz, ker_uv, ker_lod).xyz) * 2.0 - 1.0);
	vec3 ker_color = textureLod(u_wave_kernel_particle, ker_uv, ker_lod).rgb;

	X += ker_matrix * ker_X * amp;
	dXdp = dXdp + ker_matrix * ker_dXdp * amp;
//	dXdt += ker_dXdt;
	
//	vec3 k = vec3(mod(random * 6.0 + 5.0, 6.0), mod(random * 6.0 + 3.0, 6.0), mod(random * 6.0 + 1.0, 6.0));
//	vec3 hue_color = 1.0 - max(vec3(0), min(k, min(4.0 - k, vec3(1))));
//	color += clamp(ker_color.r + ker_color.g * 0.5 + ker_color.b * 0.1, 0, 1.0) * hue_color;
	color += clamp(ker_color.r + ker_color.g * 0.5 + ker_color.b * 0.1, 0, 1.0) * mix(vec3(1, 0, 0), vec3(0, 0, 1), random);
}

float rayleigh_sample(float mean, float u)
{
	return mean * sqrt(max(-4.0 / PI * log(1.0 - u), 0.0));
}

void wave_sample(vec2 cell, int seed, float t, out float amp, out vec2 start, out float dir, out float lambda, out float life, out float color)
{
	vec3 rand1 = hash(vec3(float(seed), cell.y, cell.x)) * 0.5 + 0.5;
	float phase_shift = rand1.x;
	// XXX Precision could suffer for large t, problem?
	// Should keep a rolling value in 0..1 range incremenenting by dt,
	// but has to happen outside of the shader.
	float sample_phase = t / wave_lifetime + phase_shift;
	life = fract(sample_phase);
	// Derived seed value that changes with each iteration
	float nseed = float(seed) + 82.3 * floor(sample_phase);
	vec3 rand2 = hash(vec3(cell.x, cell.y, nseed)) * 0.5 + 0.5;
	vec3 rand3 = hash(vec3(cell.y, nseed, cell.x)) * 0.5 + 0.5;

	amp = u_wave_amplitude;
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

	vec2 terrain_cell_coords = (u_terrain_inverse_transform * vec4(start.x, 0, start.y, 1)).xz;
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

	float terrain_dir = atan(-terrain_normal.z, -terrain_normal.x);
	dir = terrain_dir;

//	dir = 2.0 * PI * rand3.z;

//	dir = 0.0;
// <<< FLOW METHODS

	color = rand2.x;
}

void header_pack(ivec2 uv, float time, int count, float count_frac, out vec4 col)
{
	int type = uv.x;
	switch (type)
	{
		case 0:
			col = vec4(time, intBitsToFloat(count), count_frac, 0);
			break;
		
		default:
			col = vec4(0);
			break;
	}
}

void header_unpack(sampler2D tex, out float time, out int count, out float count_frac)
{
	ivec2 uv0 = ivec2(0, 0);
//	ivec2 uv1 = ivec2(1, 0);
	vec4 col0 = texelFetch(tex, uv0, 0);
//	vec4 col1 = texelFetch(tex, uv1, 0);
	time = col0.r;
	count = floatBitsToInt(col0.g);
	count_frac = col0.b;
}

void particle_pack(ivec2 uv, int flags, float birth_time, vec2 pos, vec2 vel, out vec4 col)
{
	int type = (uv.x - IDX_PARTICLE_START) % WAVE_PARTICLE_PIXELS;
//	int texel = uv.x + uv.y * WAVE_PARTICLE_TEXTURE_WIDTH;
	switch (type)
	{
		case 0:
			col = vec4(intBitsToFloat(flags), birth_time, 0, 0);
			break;

		case 1:
			col = vec4(pos.xy, vel.xy);
			break;

		default:
			col = vec4(0);
			break;
	}
}

void particle_unpack(sampler2D tex, ivec2 uv, out int flags, out float birth_time, out vec2 pos, out vec2 vel)
{
	int k = uv.x - IDX_PARTICLE_START;
	ivec2 uv0 = ivec2(IDX_PARTICLE_START + k - k % WAVE_PARTICLE_PIXELS, uv.y);
	ivec2 uv1 = uv0 + ivec2(1, 0);
	ivec2 uv2 = uv0 + ivec2(2, 0);
	ivec2 uv3 = uv0 + ivec2(3, 0);
	vec4 col0 = texelFetch(tex, uv0, 0);
	vec4 col1 = texelFetch(tex, uv1, 0);
	vec4 col2 = texelFetch(tex, uv2, 0);
	vec4 col3 = texelFetch(tex, uv3, 0);
	flags = floatBitsToInt(col0.x);
	birth_time = col0.y;
	pos = col1.xy;
	vel = col1.zw;
}

bool get_particle_index(ivec2 uv, out int index)
{
	int texel = int(uv.x) + int(uv.y) * WAVE_PARTICLE_TEXTURE_WIDTH;
	if (texel >= IDX_PARTICLE_START)
	{
		index = (texel - IDX_PARTICLE_START) / WAVE_PARTICLE_PIXELS;
		return true;
	}
	else
	{
		index = -1;
		return false;
	}
}

ivec2 get_particle_uv(int index)
{
	int texel = index * WAVE_PARTICLE_PIXELS + IDX_PARTICLE_START;
	return ivec2(texel % WAVE_PARTICLE_TEXTURE_WIDTH, texel / WAVE_PARTICLE_TEXTURE_WIDTH);
}

int get_particle_count(sampler2D tex)
{
	vec4 col = texelFetch(tex, ivec2(0, 0), 0);
	return floatBitsToInt(col.r);
}

void wave_sum(vec4 wpos, float t, float dt, mat4 world_projection_matrix, out vec3 X, out vec3 dXdt, out mat3 dXdp, out vec3 particle_color)
{
	mat4 inv_world_projection_matrix = inverse(world_projection_matrix);
	// Precompute texture UV derivatives for LOD.
	// Distance of the water plane to account for perspective.
	float view_z = (world_projection_matrix * wpos).z;
	// Derivative of world coordinates per screen pixel.
	vec3 world_dx = inv_world_projection_matrix[0].xyz * view_z;
	vec3 world_dy = inv_world_projection_matrix[1].xyz * view_z;

	X = wpos.xyz;
	dXdp = mat3(vec3(1, 0, 0), vec3(0, 1, 0), vec3(0, 0, 1));
	dXdt = vec3(0, 0, 0);
	particle_color = vec3(0.0);

	float travel_dist = wave_speed * wave_lifetime;
	float dalpha = dt / wave_lifetime;
	
	ivec2 wave_cell = ivec2(wpos.xz / cell_size());
	
	// Stochastic random particles
	int samples = int(u_wave_density);
	for (int j = -1; j <= 1; ++j)
	{
		for (int i = -1; i <= 1; ++i)
		{
			for (int k = 0; k < samples; ++k)
			{
				ivec2 cell = wave_cell + ivec2(i, j);
				
				float amp;
				vec2 start;
				float dir;
				float lambda;
				float life;
				float random;
				wave_sample(vec2(cell), k, t, amp, start, dir, lambda, life, random);

				vec2 travel = vec2(cos(dir), sin(dir)) * travel_dist;
				vec2 center = start + life * travel;
				wave_add_kernel(wpos, world_dx, world_dy, center, travel, amp, lambda, life, random, X, dXdt, dXdp, particle_color);
			}
		}
	}
	
	// Simulated dynamic particles
	float par_time;
	int par_count;
	float par_count_frac;
	header_unpack(u_wave_particles, par_time, par_count, par_count_frac);
	for (int k = 0; k < u_num_wave_particles; ++k)
	{
		vec2 par_pos, par_vel;
		int par_flags;
		float par_birth_time;
		particle_unpack(u_wave_particles, get_particle_uv(k), par_flags, par_birth_time, par_pos, par_vel);

		ivec2 par_cell = ivec2(par_pos / cell_size());
		ivec2 cell_diff = par_cell - wave_cell;
		if (cell_diff.x < -1 || cell_diff.x > 1 || cell_diff.y < -1 || cell_diff.y > 1)
		{
			continue;
		}
		
		float amp = 0.01;
		float lambda = wave_length;
		float life = 0.5;
		float random = 0.5;
		vec2 travel = par_vel;
		vec2 center = par_pos + life * travel;
		wave_add_kernel(wpos, world_dx, world_dy, center, travel, amp, lambda, life, random, X, dXdt, dXdp, particle_color);
//		wave_add_kernel(wpos, world_dx, world_dy, vec2(0.5, 0.5), vec2(1.0, 0.0), amp, lambda, life, random, X, dXdt, dXdp, particle_color);
	}

//	wave_add_kernel(vec4(1.0, 0.0, 1.0, 1.0), world_dx, world_dy, vec2(0.5, 0.5), vec2(1, 0), 1.0, 3.0, 0.5, 0.0, X, dXdt, dXdp, particle_color);
}

void waves(vec4 wpos, float t, float dt, mat4 world_projection_matrix, out vec3 position, out vec3 velocity, out vec3 normal, out vec3 tangent, out float foam, out vec3 particle_color)
{
	vec3 X;
	mat3 dXdp;
	vec3 dXdt;

	wave_sum(wpos, t, dt, world_projection_matrix, X, dXdt, dXdp, particle_color);

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

uniform float time = 0.0;
varying vec3 WAVE_POSITION;

uniform bool use_detail = true;
uniform float detail_amplitude = 0.25;
uniform float detail_scale = 1.0;
uniform float detail_speed = 1.0;

varying float FOAM;
uniform float foam_scale = 10.0;
uniform float foam_min : hint_range(0, 1) = 0.0;
uniform float foam_max : hint_range(0, 1) = 1.0;

uniform vec4 water_color : hint_color;
uniform float water_density = 0.1;
uniform float sss_strength = 7.0;
uniform float beach_alpha_fadeout = 0.05;

uniform bool use_flat_shader = false;
uniform float particle_viz : hint_range(0, 1) = 0.0;

void vertex()
{
	mat4 INV_WORLD_MATRIX = inverse(WORLD_MATRIX);
	
	vec4 wpos = WORLD_MATRIX * vec4(VERTEX, 1);
	// Store the original vertex location to use as a texture parameter in the fragment function.
	WAVE_POSITION = wpos.xyz;
	
	vec3 velocity;
	vec3 particle_color;
	vec3 position_out, normal_out, tangent_out;
	waves(wpos, time, 0.0, PROJECTION_MATRIX * INV_CAMERA_MATRIX, position_out, velocity, normal_out, tangent_out, FOAM, particle_color);
	VERTEX = (INV_WORLD_MATRIX * vec4(position_out, 1)).xyz;
	NORMAL = (INV_WORLD_MATRIX * vec4(normal_out, 0)).xyz;
	TANGENT = (INV_WORLD_MATRIX * vec4(tangent_out, 0)).xyz;
}

void fragment()
{
	vec3 normal_output;
	vec3 particle_color = vec3(0);
	if (particle_viz > 0.0)
	{
		vec4 wpos = vec4(WAVE_POSITION, 1);
		vec3 wave_vertex;
		vec3 wave_velocity;
		vec3 wave_normal, wave_tangent;
		float wave_foam;
		waves(wpos, time, 0.0, PROJECTION_MATRIX * INV_CAMERA_MATRIX, wave_vertex, wave_velocity, wave_normal, wave_tangent, wave_foam, particle_color);
	}

	vec3 ynor = mat3(CAMERA_MATRIX) * NORMAL;
	vec3 ytan = mat3(CAMERA_MATRIX) * TANGENT;
	vec3 znor = vec3(ynor.x, -ynor.z, ynor.y);
	vec3 ztan = vec3(ytan.x, -ytan.z, ytan.y);
	mat3 localmap = mat3(ztan, cross(znor, ztan), znor);

	// UNDERWATER
    float view_z = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r * 2.0 - 1.0;
	// Depth reprojection to get ray length inside water.
	view_z = PROJECTION_MATRIX[3][2] / (view_z + PROJECTION_MATRIX[2][2]); // Camera Z Depth to World Space Z
	float depth = view_z + VERTEX.z;

//	// NORMAL APPLIED TO DEPTH AND READ FROM BUFFER AGAIN (DISTORTED Z-DEPTH)
//	depth = texture(DEPTH_TEXTURE, SCREEN_UV + (znor.xy * clamp(depth * 0.1, 0.0, 0.1) )).r;
//	depth = depth * 2.0 - 1.0;
//	depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]); // Camera Z Depth to World Space Z
//	depth = depth + VERTEX.z;

	if (use_detail)
	{
		vec3 detail_uv = vec3(WAVE_POSITION.x, time * detail_speed, WAVE_POSITION.z) / detail_scale;
		vec3 dDdz = detail_amplitude * dfbm(detail_uv);
		vec3 Dnor = vec3(-dDdz.x, -dDdz.y, 1) / (1.0 + dDdz.z);
		normal_output = localmap * Dnor * 0.5 + 0.5;
//		normal_output = znor * 0.5 + 0.5;
	}
	else
	{
		normal_output = znor * 0.5 + 0.5;
	}

	// WATER COLOR GRADIENT
//	vec3 water_gradient = texture(water_color, vec2(7depth / water_color_depth, 0.5)).xyz;
//	vec3 water_gradient = mix(water_color.rgb, vec3(0), clamp(depth / water_color_depth, 0, 1));
	vec3 albedo_output;
	float alpha_output;
	float specular_output;
	float roughness_output;
	if (use_flat_shader)
	{
		albedo_output = vec3(0.5);
		alpha_output = 1.0;
		specular_output = 0.0;
		roughness_output = 1.0;
	}
	else
	{
		albedo_output = water_color.rgb;
		// XXX Simple absorption based on vertical depth.
		// In Godot 4.0 it should be possible to pass depth to actual light function
		// as a global shader variable and do more accurate light estimation.
		float vdepth = (CAMERA_MATRIX * vec4(0, 0, depth, 0)).y;
		albedo_output *= exp(-water_density * max(vdepth, 0.0));

//		alpha_output = clamp(depth / water_color_depth, 0, 1);
//		alpha_output = smoothstep(depth, 0.00, beach_alpha_fadeout);
		alpha_output = 1.0 - exp(-water_density * depth);
		specular_output = 0.6;
		roughness_output = 0.08;

		// FOAM
//		float foam_mask = clamp((FOAM - foam_min) / (foam_max - foam_min), 0, 1);
		float foam_mask = smoothstep(foam_min, foam_max, FOAM);
//		float foam_mask = (fbm(wave_pos * foam_scale) - COLOR.r);
		foam_mask *= fbm(WAVE_POSITION * foam_scale) * 0.5 + 0.5;

		albedo_output = mix(albedo_output, vec3(1), foam_mask);
//		albedo_output = mix(albedo_output, albedo_output + albedo_foam_a, (1.0 - smoothstep(COLOR[0], 0.0, normal_dist_fadeout) ) * (mask_foam * foam_amount + mask_beach_waves) + (height_gerstner.y * foam_gerstner + height_gerstner_2.y * foam_gerstner ) );
//		normal_output = mix(normal_output, normal_output + normal_foam_a, (1.0 - smoothstep(COLOR[0], 0.0, normal_dist_fadeout) ) * (mask_foam * foam_amount + mask_beach_waves) + (height_gerstner.y * foam_gerstner + height_gerstner_2.y * foam_gerstner ) );
		specular_output = mix(specular_output, 0.2, foam_mask);
		roughness_output = mix(roughness_output, 1.0, foam_mask);
		alpha_output = mix(alpha_output, 0.8, foam_mask);

//		// BEACH
//		normal_output = mix(vec3(0.5, 0.5, 1.0), normal_output, clamp( smoothstep(depth, 0.0, beach_normal_fadeout) + mask_beach_waves, 0.5, 1.0) ); // smooth out
//		alpha_output = smoothstep(alpha_output, 0.0, beach_alpha_fadeout);
	}
	albedo_output = mix(albedo_output, particle_color, particle_viz);
	
	ALBEDO = clamp(albedo_output, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
//	NORMALMAP = clamp(normal_output, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
	vec3 normal_z =  clamp(normal_output, 0, 1) * 2.0 - 1.0;
	NORMAL = (INV_CAMERA_MATRIX * vec4(normal_z.x, normal_z.z, -normal_z.y, 0.0)).xyz;
	SPECULAR = specular_output;
	ROUGHNESS = roughness_output;
	METALLIC = 0.0;
	ALPHA = alpha_output;
}

void light()
{
// LAMBER DIFFUSE LIGHTING
	float pi = 3.14159265358979323846;
//	float water_highlight_mask_1 = texture(water_highlight_map, fract( UV - (WORLD_MATRIX[3].xz * 0.25) + TIME * 0.051031 ) ).x;
//	float water_highlight_mask_2 = texture(water_highlight_map, fract( UV - (WORLD_MATRIX[3].xz * 0.25) + TIME * -0.047854) * 2.0 ).x;
	float water_highlight_mask_1 = 1.0;
	float water_highlight_mask_2 = 1.0;
	
	// SUBSURFACE SCATTERING
	float sss = clamp( smoothstep(0.65, 0.7, dot(NORMAL , VIEW) * 0.5 + 0.5 ) * smoothstep(0.5, 1.0, (dot(-LIGHT, VIEW) * 0.5 + 0.5) ) * ( dot (-CAMERA_MATRIX[2].xyz, vec3(0.0, 1.0, 0.0)) * 0.5 + 0.5), 0.0, 1.0) * sss_strength;
		
	float lambert = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float spec = clamp( pow( dot( reflect(LIGHT, NORMAL), -VIEW), 1000.0), 0.0, 1.0) * 2.0;
	float spec_glare = clamp( pow( dot( reflect(LIGHT, NORMAL), -VIEW), 100.0), 0.0, 1.0) * smoothstep(0.0, 0.1, water_highlight_mask_1 * water_highlight_mask_2) * 30.0;
	
	DIFFUSE_LIGHT += (LIGHT_COLOR * ALBEDO * ATTENUATION / pi) * lambert;
	if (!use_flat_shader)
	{
		DIFFUSE_LIGHT += (LIGHT_COLOR * ALBEDO * ATTENUATION / pi) * sss;
		DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * (spec + spec_glare);
	}
}
