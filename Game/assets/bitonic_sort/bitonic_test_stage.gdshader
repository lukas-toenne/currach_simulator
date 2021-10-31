shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D u_tex;
uniform ivec2 u_tex_size = ivec2(1024, 1024);
uniform int u_stage = 0;
uniform int u_pass = 0;

int uv_to_index(ivec2 uv)
{
	return uv.x + uv.y * u_tex_size.x;
}

ivec2 index_to_uv(int index)
{
	// XXX Can optimize using bit shift/masking. Probably(?) no big impact compared to texelFetch.
	return ivec2(index % u_tex_size.x, index / u_tex_size.x);
}

vec4 do_pass(int index, int stage_size, int block_size)
{
	int block_mask = block_size - 1;
	int half_size = block_size >> 1;
	bool is_first_half = ((index & block_mask) < half_size);

	int index_a = is_first_half ? index : index - half_size;
	int index_b = is_first_half ? index + half_size : index;
	vec4 a = texelFetch(u_tex, index_to_uv(index_a), 0);
	vec4 b = texelFetch(u_tex, index_to_uv(index_b), 0);

	int stage_mask = (stage_size << 1) - 1;
	bool ascending = ((index & stage_mask) < stage_size);
	bool less_than = (is_first_half == ascending);
	return (a.r < b.r == less_than) ? a : b;
}

void fragment()
{
	int index = uv_to_index(ivec2(FRAGCOORD.xy));
	COLOR = do_pass(index, 2 << u_stage, 2 << u_pass);
//	COLOR = texelFetch(u_tex, index_to_uv(index), 0);
//	COLOR = vec4(0, 0.5, 0.8, 1);
}
