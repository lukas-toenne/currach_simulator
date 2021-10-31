shader_type canvas_item;

uniform sampler2D u_tex;
uniform float scale = 8.0;

void fragment()
{
	COLOR = texelFetch(u_tex, ivec2(FRAGCOORD.xy / scale), 0);
//	COLOR = vec4(0, 1, 0.3, 1);
}