extends RefCounted

# Água animada leve em GL Compatibility; funciona offline e não usa assets de GTA.
static func create_water_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 shallow_color : source_color = vec4(0.075, 0.39, 0.50, 0.86);
uniform vec4 deep_color : source_color = vec4(0.025, 0.18, 0.28, 0.91);
uniform float wave_strength = 0.095;
uniform float illumination = 1.0;
varying vec2 world_coordinates;

void vertex() {
	world_coordinates = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	float a = sin(world_coordinates.x * 0.19 + TIME * 0.95);
	float b = cos(world_coordinates.y * 0.15 - TIME * 0.73);
	VERTEX.y += (a + b) * 0.5 * wave_strength;
}

void fragment() {
	float ripple = sin(world_coordinates.x * 0.26 + TIME * 0.85) *
	cos(world_coordinates.y * 0.21 - TIME * 0.58);
	float factor = clamp(0.46 + 0.35 * ripple, 0.0, 1.0);
	ALBEDO = mix(deep_color.rgb, shallow_color.rgb, factor) * mix(0.25, 1.0, illumination);
	ALPHA = mix(deep_color.a, shallow_color.a, factor);
	ROUGHNESS = 0.16;
	METALLIC = 0.04;
	SPECULAR = 0.8;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material
