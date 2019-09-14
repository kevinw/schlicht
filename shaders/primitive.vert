#version 330 core

layout (location = 0) in vec2 i_pos;
layout (location = 1) in vec2 i_uv;

uniform mat4 model;
uniform mat4 projection;
uniform mat4 view;

out vec2 o_uv;

void main() {
	gl_Position = projection * view * model * vec4(i_pos, 0.0f, 1.0f);
	o_uv = i_uv;
}