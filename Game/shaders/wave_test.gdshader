shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, depth_draw_always;

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

uniform sampler2D terrain_heightmap;
uniform sampler2D terrain_normalmap;
uniform mat4 terrain_inverse_transform;
uniform mat3 terrain_normal_basis;
uniform float terrain_height_min = -1.0;
uniform float terrain_height_max = 1.0;

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

void wave_sum(vec2 p, vec4 wpos, float t, float dt, out vec3 X, out vec3 dXdt, out mat3 dXdp, out vec3 particle_color)
{
	X = vec3(p.x, 0, p.y);
	dXdp = mat3(vec3(1, 0, 0), vec3(0, 1, 0), vec3(0, 0, 1));
	dXdt = vec3(0, 0, 0);
	particle_color = vec3(0.0);

	float travel_dist = wave_speed * wave_lifetime;
	float dalpha = dt / wave_lifetime;
	
	float cx = floor(p.x / cell_size());
	float cy = floor(p.y / cell_size());

	vec2 terrain_cell_coords = (terrain_inverse_transform * wpos).xz;
	// Must add a half-offset so that we sample the center of pixels,
	// otherwise bilinear filtering of the textures will give us mixed results (#183)
	terrain_cell_coords += vec2(0.5);
	// Normalized UV
	vec2 terrain_uv = terrain_cell_coords / vec2(textureSize(terrain_heightmap, 0));
	// Height displacement
	float terrain_height = texture(terrain_heightmap, terrain_uv).r;

	// TODO choose LOD for terrain normal texture such that it averages over the whole wave cell,
	// i.e. LOD = ceil(log2(wave_cell_size / terrain_cell_size)),
	// where terrain_cell_size = terrain_transform * vec3(1)
	// Ideally the wave cell size should be a multiple of the terrain cell size!

	// Need to use u_terrain_normal_basis to handle scaling.
	vec3 terrain_normal = terrain_normal_basis * unpack_normal(texture(terrain_normalmap, terrain_uv));
	
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
				wave_kernel(p, amp, center, travel, lambda, dt, ker_X, ker_dXdt, ker_dXdp, ker_color);

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
//	particle_color = vec3(1.0 - r, r, 0);
//	particle_color = texture(terrain_normalmap, terrain_uv).xyz;
//	particle_color += terrain_normal * vec3(1, 0, 1);
}

void waves(vec2 p, vec4 wpos, float t, float dt, out vec3 position, out vec3 velocity, out vec3 normal, out vec3 tangent, out float foam, out vec3 particle_color)
{
	vec3 X;
	mat3 dXdp;
	vec3 dXdt;

//	wave_kernel(p, wave_amplitude, vec2(0, 0), normalize(linear_direction), dt, X, dXdt, dXdp, local, envelope);
//	wave_sample(p, wave_amplitude, vec2(-4, 2), vec2(8, -5), 0.5, 0.1, X, dXdt, dXdp, local, envelope);
	wave_sum(p, wpos, t, dt, X, dXdt, dXdp, particle_color);

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
	// Store the original vertex location to use as a texture parameter in the fragment function.
	WAVE_POSITION = VERTEX;
	
	vec4 wpos = WORLD_MATRIX * vec4(VERTEX, 1);
	
	vec3 velocity;
	vec3 particle_color;
	waves(VERTEX.xz, wpos, time, 0.0, VERTEX, velocity, NORMAL, TANGENT, FOAM, particle_color);
}

void fragment()
{
	vec3 normal_output;
	vec3 particle_color = vec3(0);
	if (particle_viz > 0.0)
	{
		vec2 wave_pos = (CAMERA_MATRIX * vec4(VERTEX, 1)).xz;
		vec4 wpos = WORLD_MATRIX * vec4(WAVE_POSITION, 1);
		vec3 wave_vertex;
		vec3 wave_velocity;
		vec3 wave_normal, wave_tangent;
		float wave_foam;
		waves(wave_pos, wpos, time, 0.0, wave_vertex, wave_velocity, wave_normal, wave_tangent, wave_foam, particle_color);
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
		float detail = fbm(detail_uv);
		mat3 detail_tfm = transpose(inverse(mat3(1) + detail_amplitude * mat3(vec3(0), dfbm(detail_uv), vec3(0))));
		normal_output = detail_tfm * localmap[2] * 0.5 + 0.5;
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
//		albedo_output = water_color.rgb;
//		albedo_output = normal_output;
//		albedo_output = (CAMERA_MATRIX * vec4(normalize(NORMAL), 0)).xyz * 0.5 + 0.5;
//		albedo_output = mix(debug, albedo_output, 0.8);
//		albedo_output = vec3(depth, 0, 0);

		alpha_output = 1.0;
		specular_output = 0.0;
		roughness_output = 1.0;
	}
	else
	{
//	 	albedo_output = water_gradient;
//	 	albedo_output = mix(albedo_output, vec3(1, 1, 1), smoothstep(COLOR.r, 0.0, 0.01));
//		albedo_output = vec3(clamp((fbm(wave_pos) - foam_threshold) / (1.0 - foam_threshold), 0, 1)) * foam_threshold;
//		albedo_output = vec3(clamp((fbm(wave_pos * 100.0) - foam_threshold) / (1.0 - foam_threshold), 0, 1)) * foam_threshold;
		albedo_output = water_color.rgb;
		// XXX Simple absorption based on vertical depth.
		// In Godot 4.0 it should be possible to pass depth to actual light function
		// as a global shader variable and do more accurate light estimation.
		float vdepth = (CAMERA_MATRIX * vec4(0, 0, depth, 0)).y;
		albedo_output *= exp(-water_density * vdepth);

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
	
//	ALBEDO = clamp(albedo_output, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
//	NORMALMAP = clamp(normal_output, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
//	SPECULAR = specular_output;
//	ROUGHNESS = roughness_output;
//	METALLIC = 0.0;
//	ALPHA = alpha_output;
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






