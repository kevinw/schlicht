#version 320 es

layout (location = 0) in vec4 i_vertex; // <vec2 pos, vec2 tex>
out vec2 o_uv;

uniform mat4 projection;

void main() {
    gl_Position = projection * vec4(i_vertex.xy, 0.0, 1.0);
    o_uv = i_vertex.zw;
}  