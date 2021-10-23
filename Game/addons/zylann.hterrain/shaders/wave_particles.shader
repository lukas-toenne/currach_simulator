shader_type particles;

const float PI = 3.14159265359;

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

void vertex()
{
	uint alt_seed1 = hash(NUMBER + uint(1) + RANDOM_SEED);
	uint alt_seed2 = hash(NUMBER + uint(27) + RANDOM_SEED);
	uint alt_seed3 = hash(NUMBER + uint(43) + RANDOM_SEED);
	uint alt_seed4 = hash(NUMBER + uint(111) + RANDOM_SEED);
	if (RESTART)
	{
		//Initialization code goes here
		float phi = rand_from_seed(alt_seed1) * 2.0 * PI;
		vec3 p = vec3(cos(phi), 0, sin(phi));
		TRANSFORM = mat4(1);
		TRANSFORM[3].xyz = p * 3.0;
		VELOCITY = p * 1.0;
	}
	else
	{
		//per-frame code goes here
	}
}
