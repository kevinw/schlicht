#version 330 core

in vec2 o_uv;
out vec4 frag_color;

uniform sampler2D text;
uniform vec3 text_color;

void main() {    
    vec4 sampled_color = vec4(1.0, 1.0, 1.0, texture(text, o_uv).r);
    frag_color = vec4(text_color, 1.0) * sampled_color;
}  