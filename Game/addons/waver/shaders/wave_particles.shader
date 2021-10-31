shader_type canvas_item;
render_mode blend_disabled;

const float PI = 3.14159265359;

// Make sure the simulation scripts and water shaders are updated when changing width.
const int IDX_PARTICLE_START = 4;
const int WAVE_PARTICLE_PIXELS = 4;
const int WAVE_PARTICLE_TEXTURE_WIDTH = 1024;

// Particle flags
const int PARTICLE_INITIALIZED = (1 << 0);
const int PARTICLE_DEAD = (1 << 1);

uniform bool u_reset = true;
uniform float u_time_scale = 1.0;

uniform float u_test_emit = 5.0;
uniform float u_test_speed = 1.5;


float rand_from_seed(in uint seed) {
  int k;
  int s = int(seed);
  if (s == 0)
    s = 305420679;
  k = s / 127773;
  s = 16807 * (s - k * 127773) - 2836 * k;
  if (s < 0)
    s += 2147483647;
  seed = uint(s);
  return float(seed % uint(65536)) / 65535.0;
}

uint hash(uint x) {
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = (x >> uint(16)) ^ x;
  return x;
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

//void fragment()
//{
//	COLOR = vec4(1, 0, 0, 0);
//}

void fragment()
{
	ivec2 uv = ivec2(FRAGCOORD.xy);
	int par_index;
	bool is_particle = get_particle_index(uv, par_index);

	if (u_reset)
	{
		if (par_index < 0)
		{
			header_pack(uv, TIME, 0, 0.0, COLOR);
		}
		else
		{
			particle_pack(uv, 0, 0.0, vec2(0), vec2(0), COLOR);
		}
	}
	else
	{
		float last_time;
		int count;
		float count_frac;
		header_unpack(SCREEN_TEXTURE, last_time, count, count_frac);
		float delta_time = TIME - last_time;

		if (par_index < 0)
		{
			count_frac += u_test_emit * delta_time;
			count += int(count_frac);
			count_frac = fract(count_frac);

			header_pack(uv, TIME, count, count_frac, COLOR);
		}
		else
		{
			int flags;
			float birth_time;
			vec2 pos, vel;
			particle_unpack(SCREEN_TEXTURE, uv, flags, birth_time, pos, vel);

			if ((flags & PARTICLE_INITIALIZED) == 0)
			{
				flags |= PARTICLE_INITIALIZED;
				birth_time = TIME;

				uint alt_seed1 = hash(uint(par_index + 1));
				uint alt_seed2 = hash(uint(par_index + 27));
				uint alt_seed3 = hash(uint(par_index + 43));
				uint alt_seed4 = hash(uint(par_index + 111));
				float dir = rand_from_seed(alt_seed2) * 2.0 * PI;
				vel = vec2(cos(dir), sin(dir));
				pos = vec2(1.0, 1.0) + vel * 0.2;
			}

			pos = pos + vel * delta_time;

			particle_pack(uv, flags, birth_time, pos, vel, COLOR);
		}
	}
}
