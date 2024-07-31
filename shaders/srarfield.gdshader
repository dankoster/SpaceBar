shader_type canvas_item;

uniform vec2 resolution = vec2(600.0, 400.0);
uniform sampler2D noise_texture: filter_nearest, repeat_enable;
uniform float density: hint_range(1.0, 100.0) = 30.0;
uniform float speed_x: hint_range(-100.0, 100.0, 0.1) = 20.0;
uniform float speed_y: hint_range(-100.0, 100.0, 0.1) = 0.0;
uniform float layers: hint_range(1.0, 10.0, 1.0) = 4.0;

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 uv = UV;
	uv.x *= resolution.x/ resolution.y;
	vec2 speed = TIME * vec2(speed_x, speed_y) * 0.01;
	float stars = 0.0;
	for(float i = 0.0; i < layers; i += 1.0) {
		float shift = i * 0.2;
		float brightness = 1.0 - i * 0.2;
		stars += step(0.2, pow(texture(noise_texture, uv + shift + speed * (1.0 - i * 0.1)).r, density)) * brightness;
	}
	COLOR = vec4(vec3(stars), 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
