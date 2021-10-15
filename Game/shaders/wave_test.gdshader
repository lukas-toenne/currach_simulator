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

uniform float wave_length = 3.0;
uniform float phase_speed = 1.0;
uniform float wave_lifetime = 3.0;
uniform float kernel_radius = 3.0;

uniform sampler2D flow_map;
uniform vec2 flow_map_origin = vec2(0, 0);
uniform vec2 flow_map_scale = vec2(1, 1);

float cell_size()
{
	return phase_speed * wave_lifetime + kernel_radius;
}

uniform float amplitude = 1.0;
uniform float detail_amplitude = 0.1;
uniform float detail_scale = 0.4;
uniform float detail_speed = 0.2;

float rect(float x)
{
	float ax = abs(x);
	return ax < 0.5 ? 1.0 : (ax == 0.5 ? 0.5 : 0.0);
}

void wave_kernel(vec2 p, float A, vec2 center, vec2 travel, float lambda, float dt, out vec3 X, out vec3 dXdt, out mat3 dXdp, out float color)
{
	float r = kernel_radius;
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
	
	color = 0.5 * (cos(PI * l) + 1.0) * rect(0.5 * l);
	if (abs(l - 1.0) < 0.01)
	{
		color = 1.0;
	}
}

float rayleigh_sample(float mean, float u)
{
	return mean * sqrt(max(-4.0 / PI * log(1.0 - u), 0.0));
}

void wave_sample(vec2 cell, int seed, float t, out float amp, out vec2 start, out float dir, out float lambda, out float alpha, out vec3 color)
{
	vec3 q = hash(vec3(float(seed), cell.y, cell.x)) * 0.5 + 0.5;
	float phase_shift = q.x;
	// XXX Precision could suffer for large t, problem?
	// Should keep a rolling value in 0..1 range incremenenting by dt,
	// but has to happen outside of the shader.
	float sample_phase = t / wave_lifetime + phase_shift;
	alpha = fract(sample_phase);
	// Derived seed value that changes with each iteration
	float nseed = float(seed) + 82.3 * floor(sample_phase);

	vec3 u = hash(vec3(cell.x, cell.y, nseed)) * 0.5 + 0.5;
	vec3 v = hash(vec3(cell.y, nseed, cell.x)) * 0.5 + 0.5;

	amp = amplitude;
	lambda = wave_length;
//	float freq = rayleigh_sample(phase_speed / wave_length, u.x);
//	float freq2 = freq * freq;
//	float freq4 = freq2 * freq2;
//	float freq5 = freq4 * freq;
//	float B = 1.0;
//	amp = amplitude * exp(-B / freq4) / freq5 * 1000.0;
//	lambda = phase_speed / freq;
	// Clamp amplitude to avoid overlap at the crest.
	amp = min(amp, 0.5 * lambda / PI);

	start = (cell + v.xy) * cell_size();

	vec2 flow_uv = (start - flow_map_origin) / flow_map_scale;
	vec4 flow = textureLod(flow_map, flow_uv, 0.0);
	dir = 6.0 * PI * flow.r;
//	dir = 2.0 * PI * v.z;

	color = u;
}

void wave_sum(vec2 p, float t, float dt, out vec3 X, out vec3 dXdt, out mat3 dXdp, out vec3 particle_color)
{
	X = vec3(p.x, 0, p.y);
	dXdp = mat3(vec3(1, 0, 0), vec3(0, 1, 0), vec3(0, 0, 1));
	dXdt = vec3(0, 0, 0);
	particle_color = vec3(0.5);

	float travel_dist = phase_speed * wave_lifetime;
	float dalpha = dt / wave_lifetime;
	
	float cx = floor(p.x / cell_size());
	float cy = floor(p.y / cell_size());

	for (int j = -1; j <= 1; ++j)
	{
		for (int i = -1; i <= 1; ++i)
		{
			for (int k = 0; k < 20; ++k)
			{
				vec2 cell = vec2(cx + float(i), cy + float(j));
				
				float amp;
				vec2 start;
				float dir;
				float lambda;
				float alpha;
				vec3 color;
				wave_sample(cell, k, t, amp, start, dir, lambda, alpha, color);

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
}

void waves(vec2 p, float t, float dt, out vec3 position, out vec3 velocity, out vec3 normal, out vec3 particle_color)
{
	vec3 X;
	mat3 dXdp;
	vec3 dXdt;

//	wave_kernel(p, amplitude, vec2(0, 0), normalize(linear_direction), dt, X, dXdt, dXdp, local, envelope);
//	wave_sample(p, amplitude, vec2(-4, 2), vec2(8, -5), 0.5, 0.1, X, dXdt, dXdp, local, envelope);
	wave_sum(p, t, dt, X, dXdt, dXdp, particle_color);
	
	vec3 detail_uv = vec3(p.x, t * detail_speed, p.y) / detail_scale;
	vec3 detail = vec3(fbm(detail_uv.xyz), fbm(detail_uv.yzx), fbm(detail_uv.zxy));
	dXdp = dXdp + transpose(mat3(vec3(0), detail, vec3(0))) * detail_amplitude;

	position = X;
	velocity = dXdt;
	mat3 nortfm = transpose(inverse(dXdp));
	normal = normalize(nortfm * vec3(0, 1, 0));
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
uniform vec4 water_color: hint_color = vec4(0.45, 0.51, 0.55, 1);
uniform float water_color_depth = 1.0;
uniform float sss_strength = 7.0;
uniform float beach_alpha_fadeout = 0.05;

uniform bool use_flat_shader = false;
uniform float particle_viz : hint_range(0, 1) = 0.0;
uniform bool accurate_normals = false;

void vertex()
{
	vec3 velocity;
	vec3 particle_color;
	waves(VERTEX.xz, time, 0.0, VERTEX, velocity, NORMAL, particle_color);
}

void fragment()
{
	vec3 normal_output;
	vec3 particle_color = vec3(0);
	if (particle_viz > 0.0 || accurate_normals)
	{
		vec2 wave_pos = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xz;
		vec3 wave_vertex;
		vec3 wave_velocity;
		vec3 wave_normal;
		waves(wave_pos, time, 0.0, wave_vertex, wave_velocity, wave_normal, particle_color);
		
		if (accurate_normals)
		{
			// Swizzle the normal components from Y-up to Z-up
			normal_output = vec3(wave_normal.x, -wave_normal.z, wave_normal.y) * 0.5 + 0.5;
		}
	}

	if (!accurate_normals)
	{
		vec3 znor = (CAMERA_MATRIX * vec4(normalize(NORMAL), 0)).xyz;
		normal_output = vec3(znor.x, -znor.z, znor.y) * 0.5 + 0.5;
	}

//	vec3 normal_output = 0.5 * (CAMERA_MATRIX * vec4(normalize(NORMAL), 0)).xyz + 0.5;
//	normal_output = vec3(0, 0, 0.5);

	// UNDERWATER
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r; // LOOSING SS-REFLECTIONS

	// DEPTH REPROJECTION FROM CAMERA Z to Z Axis
	depth = depth * 2.0 - 1.0;
	depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]); // Camera Z Depth to World Space Z
	depth = depth + VERTEX.z;

	// NORMAL APPLIED TO DEPTH AND READ FROM BUFFER AGAIN (DISTORTED Z-DEPTH)
	depth = texture(DEPTH_TEXTURE, SCREEN_UV + ((normal_output.xy - vec2(0.5, 0.5)) * clamp(depth * 0.2, 0.0, 0.1) )).r;
	depth = depth * 2.0 - 1.0;
	depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]); // Camera Z Depth to World Space Z
	depth = depth + VERTEX.z;

//	float depth_mask = clamp(depth * underwater_tex_border, 0.0, 1.0);

	// WATER COLOR GRADIENT
//	vec3 water_gradient = texture(water_color, vec2(depth * water_color_depth, 0.5)).xyz;
	vec3 water_gradient = mix(water_color.rgb, water_color.rgb * 0.3, clamp(depth / water_color_depth, 0, 1));
	vec3 albedo_output;
	float alpha_output;
	float specular_output;
	float roughness_output;
	if (use_flat_shader)
	{
		albedo_output = water_color.rgb;
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
	 	albedo_output = water_gradient;

//		albedo_output = mix(albedo_output, albedo_output + albedo_foam_a, (1.0 - smoothstep(COLOR[0], 0.0, normal_dist_fadeout) ) * (mask_foam * foam_amount + mask_beach_waves) + (height_gerstner.y * foam_gerstner + height_gerstner_2.y * foam_gerstner ) );
//		normal_output = mix(normal_output, normal_output + normal_foam_a, (1.0 - smoothstep(COLOR[0], 0.0, normal_dist_fadeout) ) * (mask_foam * foam_amount + mask_beach_waves) + (height_gerstner.y * foam_gerstner + height_gerstner_2.y * foam_gerstner ) );
//
//		// BEACH
//		normal_output = mix(vec3(0.5, 0.5, 1.0), normal_output, clamp( smoothstep(depth, 0.0, beach_normal_fadeout) + mask_beach_waves, 0.5, 1.0) ); // smooth out
		alpha_output = smoothstep(depth, 0.00, beach_alpha_fadeout);
		specular_output = 0.6;
		roughness_output = 0.08;
	}
	albedo_output = mix(albedo_output, particle_color, particle_viz);
	
	ALBEDO = clamp(albedo_output, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
	NORMALMAP = clamp(normal_output, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
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






