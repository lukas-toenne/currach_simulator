shader_type spatial;
render_mode depth_draw_always, cull_back, unshaded, specular_disabled, shadows_disabled, ambient_light_disabled;

void vertex()
{
}

void fragment()
{
	SPECULAR = 0.0;
	ALPHA = 0.0;
}
