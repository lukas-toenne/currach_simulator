shader_type spatial;
render_mode diffuse_lambert;
render_mode specular_schlick_ggx;

// BEGIN_IMPORT res://shaders/waves.gdshader

// hash and noise functions by Inigo Quilez, published under MIT license
// https://www.shadertoy.com/view/Xsl3Dl
//
// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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


// END_IMPORT

uniform float time = 0.0;
uniform float wave_length = 10.0;
uniform float phase_speed = 1.0;
uniform float phase = 0.0;
uniform float amplitude_linear = 1.0;
uniform float amplitude_random = 1.0;
uniform vec2 direction = vec2(1.0, 0.0);
uniform sampler2D wave_shape;

uniform vec4 water_color: hint_color = vec4(0, 0, 1, 1);
uniform float water_color_depth = 1.0;
uniform float sss_strength = 7.0;
uniform float beach_alpha_fadeout = 0.05;

const float PI = 3.14159265359;

float waves_linear(vec2 pos)
{
	vec2 k = 2.0 * PI / wave_length * normalize(direction);
	return sin(dot(k, pos) - phase_speed * time + phase);
}

float waves_random(vec2 pos)
{
	float k = 2.0 * PI / wave_length;
	return fbm(vec3(k * pos, phase_speed * time + phase));
}

float waves_sum(vec2 pos)
{
	return amplitude_linear * waves_linear(pos) + amplitude_random * waves_random(pos);
}

void trochoidal_wave(inout vec2 pos, float val, vec2 dval)
{
	float totamp = amplitude_linear + amplitude_random;
	float nval = val / totamp;
	vec2 ofs = dval * sqrt(1.0 - nval*nval);
	pos -= ofs;
}

void waves(vec2 pos, out vec3 vertex, out vec3 normal)
{
	float eps = 0.01;
	vec2 e = vec2(eps, 0.0);
	
	float h = waves_sum(pos);
	vec2 dh = vec2(waves_sum(pos + e.xy) - waves_sum(pos - e.xy), waves_sum(pos + e.yx) - waves_sum(pos - e.yx)) / (2.0*eps);
	
//	trochoidal_wave(pos, h, dh);
//	dh = vec2(waves_sum(pos + e.xy) - waves_sum(pos - e.xy), waves_sum(pos + e.yx) - waves_sum(pos - e.yx)) / (2.0*eps);
	
	vertex = vec3(pos.x, h, pos.y);
	normal = normalize(vec3(-dh.x, 1.0, -dh.y));
}

void vertex()
{
	vec3 wave_normal;
	waves(VERTEX.xz, VERTEX, wave_normal);
	
//	float camera_distance = length(CAMERA_MATRIX[3].xyz - (WORLD_MATRIX[3].xyz - VERTEX)) / 1000.0;
//	COLOR[0] = camera_distance;
}

void fragment()
{
	vec2 wave_pos = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xz;
	vec3 wave_vertex;
	vec3 wave_normal;
	waves(wave_pos, wave_vertex, wave_normal);
	
	vec3 normal_output = vec3(wave_normal.x, -wave_normal.z, wave_normal.y) * 0.5 + 0.5;

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

//	albedo_output = mix(albedo_output, albedo_output + albedo_foam_a, (1.0 - smoothstep(COLOR[0], 0.0, normal_dist_fadeout) ) * (mask_foam * foam_amount + mask_beach_waves) + (height_gerstner.y * foam_gerstner + height_gerstner_2.y * foam_gerstner ) );
//	normal_output = mix(normal_output, normal_output + normal_foam_a, (1.0 - smoothstep(COLOR[0], 0.0, normal_dist_fadeout) ) * (mask_foam * foam_amount + mask_beach_waves) + (height_gerstner.y * foam_gerstner + height_gerstner_2.y * foam_gerstner ) );
	
//	// BEACH
//	normal_output = mix(vec3(0.5, 0.5, 1.0), normal_output, clamp( smoothstep(depth, 0.0, beach_normal_fadeout) + mask_beach_waves, 0.5, 1.0) ); // smooth out
	float alpha_output = smoothstep(depth, 0.00, beach_alpha_fadeout);
	
	ALBEDO = clamp(albedo_output, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
	NORMALMAP = clamp(normal_output, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
	SPECULAR = 0.6;
	ROUGHNESS = 0.08;
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
	DIFFUSE_LIGHT += (LIGHT_COLOR * ALBEDO * ATTENUATION / pi) * sss;
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * (spec + spec_glare);
}














