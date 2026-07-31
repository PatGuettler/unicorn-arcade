shader_type spatial;
render_mode cull_back, diffuse_toon;

uniform vec4 albedo : source_color = vec4(0.95, 0.45, 0.71, 1.0);
uniform vec4 rim_color : source_color = vec4(0.13, 0.83, 0.93, 1.0);
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 0.85;
	SPECULAR = 0.15;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float toon = smoothstep(0.0, 0.25, ndl);
	DIFFUSE_LIGHT += clamp(toon, 0.35, 1.0) * LIGHT_COLOR * ALBEDO;

	float rim = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), rim_power);
	SPECULAR_LIGHT += rim * rim_color.rgb * LIGHT_COLOR;
}
