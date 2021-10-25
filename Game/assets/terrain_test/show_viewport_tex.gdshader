shader_type canvas_item;

uniform sampler2D viewport_tex;

void fragment()
{
	COLOR = texture(viewport_tex, SCREEN_UV);
}
