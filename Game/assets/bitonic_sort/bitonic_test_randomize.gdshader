shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D u_tex;

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

void fragment()
{
//	uint k = uint(FRAGCOORD.x) + uint(FRAGCOORD.y) * uint(textureSize(u_tex, 0).x);
	uint k = uint(FRAGCOORD.x) + uint(FRAGCOORD.y) * uint(1024);
	float u = rand_from_seed(hash(k));
	COLOR = vec4(u, 0, 1.0 - u, 1);
}
