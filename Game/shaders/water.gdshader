shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, depth_draw_always;
//render_mode unshaded, depth_draw_always;

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

uniform float wave_length = 1.0;
uniform float phase_speed = 1.0;
uniform float kernel_radius = 3.0;

uniform float phase = 0.0;
uniform float amplitude = 1.0;
uniform vec2 linear_direction = vec2(4.0, -1.0);
//
//float waves_linear(vec2 pos, float t)
//{
//	vec2 k = 2.0 * PI / wave_length * normalize(linear_direction);
//	return sin(dot(k, pos) - phase_speed * t + phase);
//}
//
//float waves_random(vec2 pos, float t)
//{
//	float k = 2.0 * PI / wave_length;
//	return fbm(vec3(k * pos, phase_speed * t + phase));
//}
//
//float waves_sum(vec2 pos, float t)
//{
//	return amplitude_linear * waves_linear(pos, t) + amplitude_random * waves_random(pos, t);
//}
//
//void trochoidal_wave(inout vec2 pos, float val, vec2 dval)
//{
//	float totamp = amplitude_linear + amplitude_random;
//	float nval = val / totamp;
//	vec2 ofs = dval * sqrt(1.0 - nval*nval);
//	pos -= ofs;
//}

//void waves(vec2 pos, out vec3 vertex, out float dhdt, out vec2 dhdp, float t, float dt)
//{
//	float eps = 0.01;
//	vec2 e = vec2(eps, 0.0);
//
//	float h = waves_sum(pos, t);
//	dhdt = dt > 0.0 ? (waves_sum(pos, t + dt) - h) / dt : 0.0;
//	dhdp = vec2(waves_sum(pos + e.xy, t) - waves_sum(pos - e.xy, t), waves_sum(pos + e.yx, t) - waves_sum(pos - e.yx, t)) / (2.0*eps);
//
////	trochoidal_wave(pos, h, dh);
////	dh = vec2(waves_sum(pos + e.xy) - waves_sum(pos - e.xy), waves_sum(pos + e.yx) - waves_sum(pos - e.yx)) / (2.0*eps);
//
//	vertex = vec3(pos.x, h, pos.y);
//}

float rect(float x)
{
	float ax = abs(x);
	return ax < 0.5 ? 1.0 : (ax == 0.5 ? 0.5 : 0.0);
}

void wave_kernel(vec2 p, float A, vec2 center, vec2 direction, float dt, out vec3 X, out vec3 dXdt, out mat3 dXdp)
{
	float r = kernel_radius;
	vec3 dist = vec3(p.x - center.x, 0, p.y - center.y);

	// Envelope
	float l = length(dist) / r;
	vec3 dldp = dist / (length(dist) * r);
	float D = A * 0.5 * (cos(PI * l) + 1.0) * rect(0.5 * l);
	vec3 dDdp = -A * 0.5 * sin(PI * l) * rect(0.5 * l) * PI * dldp;
	
	float lambda = wave_length;
	vec3 dir = vec3(direction.x, 0, direction.y);

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
}

bool wave_sample(vec2 p, float A, vec2 start, vec2 travel, float t, float dt, out vec3 X, out vec3 dXdt, out mat3 dXdp)
{
	if (t >= 1.0)
	{
		return false;
	}
	vec2 center = start + t * travel;
	vec2 direction = normalize(travel);
	// Clamp amplitude to avoid overlap at the crest.
	A = min(A, 0.5 * wave_length / PI);
	// Time envelope
	A *= 0.5 * (1.0 - cos(2.0 * PI * t));
	wave_kernel(p, A, center, direction, dt, X, dXdt, dXdp);
	return true;
}

void waves_distribute(vec2 p, float A, float t, float dt, inout vec3 X, inout vec3 dXdt, inout mat3 dXdp)
{
	float travel_time = 3.0;
	float travel_dist = travel_time * phase_speed;
	float cell_size = kernel_radius / sqrt(2.0);

	for (int j = -3; j <= 3; ++j)
	{
		for (int i = -3; i <= 3; ++i)
		{
			for (int k = 0; k < 3; ++k)
			{
				vec3 u = hash(vec3(float(i), float(j), float(k)));
				vec3 v = hash(vec3(float(j), float(k), float(i)));

				vec2 cell = vec2(float(i), float(j));
				vec2 start = (cell + u.xz) * cell_size;
				vec2 travel = v.xz * travel_dist;
				// XXX Precision could suffer for large t, problem?
				// Should keep a rolling value in 0..1 range incremenenting by dt,
				// but has to happen outside of the shader.
				float alpha = fract(t / travel_time + u.y);
				float dalpha = dt / travel_time;
				
				vec3 sample_X;
				mat3 sample_dXdp;
				vec3 sample_dXdt;
				wave_sample(p, A, start, travel, alpha, dalpha, sample_X, sample_dXdt, sample_dXdp);
				X += sample_X;
				dXdp = dXdp + sample_dXdp;
				dXdt += sample_dXdt;
			}
		}
	}
}

void waves(vec2 p, float t, float dt, out vec3 position, out vec3 velocity, out vec3 normal, out vec3 debug)
{
	vec3 X = vec3(p.x, 0, p.y);
	mat3 dXdp = mat3(vec3(1, 0, 0), vec3(0, 1, 0), vec3(0, 0, 1));
	vec3 dXdt = vec3(0, 0, 0);

//	wave_kernel(0.63, vec2(0, 0), normalize(linear_direction), dt, X, dXdt, dXdp);
//	wave_sample(amplitude, vec2(-4, 2), vec2(8, -5), 0.5, 0.1, X, dXdt, dXdp);
	waves_distribute(p, amplitude, t, dt, X, dXdt, dXdp);

	// Zup -> Yup
	position = X;
	velocity = dXdt;
//	vec3 znor = normalize(cross(dXdp[0], dXdp[1]));
//	vec3 znor = normalize(cross(vec3(dXdp[0][0], dXdp[1][0], dXdp[2][0]), vec3(dXdp[0][1], dXdp[1][1], dXdp[2][1])));
	mat3 nortfm = transpose(inverse(dXdp));
//	mat3 nortfm = mat3(vec3(1, 0, 0), vec3(0, 1, 0), vec3(0, 0, 1));
	normal = normalize(nortfm * vec3(0, 1, 0));
//	normal = -normalize(znor);

//	mat3 test = mat3(dXdp[0], vec3(0, 1, 0), dXdp[1]);
	mat3 test = dXdp;
	bool tt = determinant(test) >= 0.0;
	debug = vec3(tt ? 1.0 : 0.0, tt ? 0.0 : 1.0, 0);
//	debug = vec3(sign(dXdp[0][0]), sign(dXdp[1][1]), sign(dXdp[2][2]));
//	debug = dXdp[1];
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
uniform vec4 water_color: hint_color = vec4(0, 0, 1, 1);
uniform float water_color_depth = 1.0;
uniform float sss_strength = 7.0;
uniform float beach_alpha_fadeout = 0.05;

void vertex()
{
	vec3 velocity;
	vec3 debug;
	waves(VERTEX.xz, time, 0.0, VERTEX, velocity, NORMAL, debug);
	
//	float camera_distance = length(CAMERA_MATRIX[3].xyz - (WORLD_MATRIX[3].xyz - VERTEX)) / 1000.0;
//	COLOR[0] = camera_distance;
	COLOR = vec4(NORMAL, 1);
}

void fragment()
{
	vec2 wave_pos = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xz;
	vec3 wave_vertex;
	vec3 wave_velocity;
	vec3 wave_normal;
	vec3 debug;
	waves(wave_pos, time, 0.0, wave_vertex, wave_velocity, wave_normal, debug);
	// Swizzle the normal components from Y-up to Z-up
	vec3 normal_output = vec3(wave_normal.x, -wave_normal.z, wave_normal.y) * 0.5 + 0.5;

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
	vec3 albedo_output = water_gradient;
	albedo_output = water_color.rgb;
//	albedo_output = normal_output;
//	albedo_output = (CAMERA_MATRIX * vec4(normalize(NORMAL), 0)).xyz * 0.5 + 0.5;
//	albedo_output = mix(debug, albedo_output, 0.8);

//	albedo_output = mix(albedo_output, albedo_output + albedo_foam_a, (1.0 - smoothstep(COLOR[0], 0.0, normal_dist_fadeout) ) * (mask_foam * foam_amount + mask_beach_waves) + (height_gerstner.y * foam_gerstner + height_gerstner_2.y * foam_gerstner ) );
//	normal_output = mix(normal_output, normal_output + normal_foam_a, (1.0 - smoothstep(COLOR[0], 0.0, normal_dist_fadeout) ) * (mask_foam * foam_amount + mask_beach_waves) + (height_gerstner.y * foam_gerstner + height_gerstner_2.y * foam_gerstner ) );
	
//	// BEACH
//	normal_output = mix(vec3(0.5, 0.5, 1.0), normal_output, clamp( smoothstep(depth, 0.0, beach_normal_fadeout) + mask_beach_waves, 0.5, 1.0) ); // smooth out
	float alpha_output = smoothstep(depth, 0.00, beach_alpha_fadeout);
	
	ALBEDO = clamp(albedo_output, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
	NORMALMAP = clamp(normal_output, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
//	NORMALMAP = vec3(0.0, 0.0, 1.0);
//	SPECULAR = 0.6;
	SPECULAR = 0.0;
//	ROUGHNESS = 0.08;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
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
//	DIFFUSE_LIGHT += (LIGHT_COLOR * ALBEDO * ATTENUATION / pi) * sss;
//	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * (spec + spec_glare);
}






