#version 320 es

lowp in vec2 o_uv;
lowp out vec4 frag_color;

lowp uniform sampler2D image;
lowp uniform vec4 color;

void main() {
	lowp vec4 finished_color = texture(image, o_uv) * color;
	
	// alpha sorting
	if (finished_color.a < 0.1) {
        discard;
	}
	
	frag_color = finished_color;
}
