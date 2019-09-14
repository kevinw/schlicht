#version 330 core

in vec2 o_uv;
out vec4 frag_color;

uniform sampler2D image;
uniform vec4 color;

void main() {
	vec4 finished_color = texture(image, o_uv) * color;
	
	// alpha sorting
	if (finished_color.a < 0.1) {
        discard;
	}
	
	frag_color = finished_color;
}
