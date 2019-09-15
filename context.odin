package schlicht

import fmt "core:fmt"
import glfw "shared:odin-glfw"
import gl "shared:odin-gl"
using import "core:math"
import stbi "shared:odin-stb/stbi"

// vertex info position and tex coordinates of a texture
Vertex :: struct #packed {
	position, tex_coords: Vec2,
}

// GLOBAL state of opengl for easy usage like raylib
global_context: Context;

// gl struct with all shaders, window info 
Context :: struct {
	window: glfw.Window_Handle,
	primitive_shader: Shader,
	mouse_pos: Vec2,
	mouse_left, mouse_right: Vec2,
    old_window_dimensions: Vec2, 
    window_offset: Vec2, 
	
    // vbos, vaos everything for rendering
	quad_vbo, quad_vao: u32,
	centered_vbo, centered_vao: u32,
	ebo: u32,
    white_texture_id: u32,
    
    line_vbo: u32,
    circle_vbo: u32,
    texture_vbo: u32,
}

// inits a opengl with set options for 2d rendering
init_context :: proc(title: string, width, height: int, offset: Vec2 = {}) {
	// gl errors to odin printed
	error_callback :: proc"c"(error: i32, desc: cstring) {
		fmt.printf("Error code %d: %s\n", error, desc);
	}
	glfw.set_error_callback(error_callback);
	
	glfw.init();
	
	window := glfw.create_window(width, height, title, nil, nil);
	if window == nil do panic("window couldnt be created");
	
	// mouse movement code
	cursor_callback :: proc"c"(window: glfw.Window_Handle, x, y: f64) {
		global_context.mouse_pos[0] = f32(x);
		global_context.mouse_pos[1] = f32(y);
	}
	glfw.set_cursor_pos_callback(window, cursor_callback);
	
    // resizing 
	resize_callback :: proc"c"(window: glfw.Window_Handle, width, height: i32) {
		gl.Viewport(0, 0, width, height);
		
        scale := global_context.old_window_dimensions / { f32(width), f32(height) };
        
        //fmt.println(scale);
        
        projection := ortho3d(0, cast(f32) width, cast(f32) height, 0, -1.0, 1.0);
        gl.UseProgram(global_context.primitive_shader.program);
        gl.UniformMatrix4fv(global_context.primitive_shader.projection, 1, gl.FALSE, &projection[0][0]);
    }
	glfw.set_window_size_callback(window, resize_callback);
	
	glfw.window_hint(glfw.CONTEXT_VERSION_MAJOR, 3);
    glfw.window_hint(glfw.CONTEXT_VERSION_MINOR, 2);
    glfw.window_hint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE);
    glfw.window_hint(glfw.OPENGL_PROFILE, cast(int) glfw.OPENGL_CORE_PROFILE);
	glfw.make_context_current(window);
	
	gl.load_up_to(3, 2, glfw.set_proc_address);
	
    // shader loading and setting up
	primitive_shader := init_shader(primitive_shader_vert, primitive_shader_frag);
	
    projection := ortho3d(0, cast(f32) width, cast(f32) height, 0, -1.0, 1.0);
	gl.UseProgram(primitive_shader.program);
	gl.UniformMatrix4fv(primitive_shader.projection, 1, gl.FALSE, &projection[0][0]);
    
	// enabling gl features
	gl.Enable(gl.BLEND);
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
	gl.ClearColor(0.0, 0.0, 0.0, 0.0);
	
	// set of vertices and vbo / vertex u32 set for static usage across draw calls
	quad_vertices := [4]Vertex {
		Vertex { { 0, 0 }, { 0, 0 } },
		Vertex { { 0, 1 }, { 0, 1 } },
		Vertex { { 1, 1 }, { 1, 1 } },
		Vertex { { 1, 0 }, { 1, 0 } }
	};
	
	quad_vao, quad_vbo: u32;
	gl.GenVertexArrays(1, &quad_vao);
    gl.GenBuffers(1, &quad_vbo);
	gl.BindVertexArray(quad_vao);
    
    gl.BindBuffer(gl.ARRAY_BUFFER, quad_vbo);
	gl.BufferData(gl.ARRAY_BUFFER, size_of(quad_vertices), &quad_vertices[0], gl.STATIC_DRAW);
	
    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), cast(rawptr) offset_of(Vertex, position));
    gl.EnableVertexAttribArray(0);
    gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), cast(rawptr) offset_of(Vertex, tex_coords));
	gl.EnableVertexAttribArray(1);
	
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindVertexArray(0);
    
    // centered vertices with optional indices that you have to enable in draw calls
	centered_vertices := [4]Vertex {
		Vertex { { -0.5, -0.5 }, { 0, 0 } },
		Vertex { { -0.5, 0.5 }, { 0, 1 } },
		Vertex { { 0.5, 0.5 }, { 1, 1 } },
		Vertex { { 0.5, -0.5 }, { 1, 0 } },
	};
	
	indices := [6]u32 {
		0, 1, 3,
		3, 2, 1,
	};
    
    centered_vao, centered_vbo: u32;
	ebo: u32 = 0;
	gl.GenVertexArrays(1, &centered_vao);
    gl.GenBuffers(1, &centered_vbo);
	gl.GenBuffers(1, &ebo);
	gl.BindVertexArray(centered_vao);
    
    gl.BindBuffer(gl.ARRAY_BUFFER, centered_vbo);
	gl.BufferData(gl.ARRAY_BUFFER, size_of(centered_vertices), &centered_vertices[0], gl.STATIC_DRAW);
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices[0], gl.STATIC_DRAW);
    
    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), cast(rawptr) offset_of(Vertex, position));
	gl.EnableVertexAttribArray(0);
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), cast(rawptr) offset_of(Vertex, tex_coords));
	gl.EnableVertexAttribArray(1);
    
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
	gl.BindVertexArray(0);
    
    // just generate them once so you dont allocate memory all the time
    line_vbo, circle_vbo, texture_vbo: u32;
    gl.GenBuffers(1, &line_vbo);
    gl.GenBuffers(1, &circle_vbo);
    gl.GenBuffers(1, &texture_vbo);
	
	// important to get images loaded right
    stbi.set_flip_vertically_on_load(1);
	
	global_context = Context {
		window = window,
		primitive_shader = primitive_shader,
		quad_vbo = quad_vbo,
		quad_vao = quad_vao,
		centered_vbo = centered_vbo,
		centered_vao = centered_vao,
        ebo = ebo,
        line_vbo = line_vbo,
        circle_vbo = circle_vbo,
        texture_vbo = texture_vbo,
        old_window_dimensions = Vec2 { f32(width), f32(height) },
    };
    
    offset_window(offset);
}

// offsets the window by a set position, updates the window_offset var to keep mouse pos right
offset_window :: proc(offset: Vec2) {
    using global_context;
    
    view := mat4_translate({ offset[0], offset[1], 0 });
	gl.UseProgram(primitive_shader.program);
	gl.UniformMatrix4fv(primitive_shader.view, 1, gl.FALSE, &view[0][0]);
    global_context.window_offset = offset;
}

// poll glfw events, update projection
update_begin_context :: proc() {
	using global_context;
	
	glfw.poll_events();
	
	// set mouse pressed to left / right clicked
	mouse_left[0] = glfw.get_mouse_button(window, glfw.Mouse_Button.MOUSE_BUTTON_LEFT) == glfw.Key_State.PRESS ? 1 : 0;
	mouse_right[0] = glfw.get_mouse_button(window, glfw.Mouse_Button.MOUSE_BUTTON_RIGHT) == glfw.Key_State.PRESS ? 1 : 0;
	
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
}

// gl calls for the render end
update_end_context :: proc() {
	using global_context;
	
	// delayed mouse set to second index wether the mouse is clicked
	mouse_left[1] = glfw.get_mouse_button(window, glfw.Mouse_Button.MOUSE_BUTTON_LEFT) == glfw.Key_State.PRESS ? 1 : 0;
	mouse_right[1] = glfw.get_mouse_button(window, glfw.Mouse_Button.MOUSE_BUTTON_RIGHT) == glfw.Key_State.PRESS ? 1 : 0;
	
	glfw.swap_buffers(window);
}

// set the current clearing color, call once as low as possible
context_color:: proc(color: Vec4) {
	gl.ClearColor(color[0], color[1], color[2], color[3]);
}

// wether the context should still be open
context_alive:: proc() -> bool {
	return !glfw.window_should_close(global_context.window);
}

// destroy the context and terminate glfw
destroy_context :: proc() {
	using global_context;
	
	glfw.terminate();
	
    gl.DeleteBuffers(1, &quad_vbo);
    gl.DeleteVertexArrays(1, &quad_vao);
	gl.DeleteBuffers(1, &centered_vbo);
    gl.DeleteVertexArrays(1, &centered_vao);
	gl.DeleteBuffers(1, &ebo);
	gl.DeleteBuffers(1, &line_vbo);
	gl.DeleteBuffers(1, &circle_vbo);
	gl.DeleteBuffers(1, &texture_vbo);
	
    gl.DeleteProgram(primitive_shader.program);
	
    destroy_input();
}


//////////////////////////////// SHADERS


// multiline strings for all shaders used in schlicht
primitive_shader_vert :: `
#version 320 es

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
`;

primitive_shader_frag :: `
#version 320 es

lowp in vec2 o_uv;
lowp out vec4 frag_color;

uniform sampler2D image;
lowp uniform vec4 color;

void main() {
	lowp vec4 finished_color = texture(image, o_uv) * color;
	
	// alpha sorting
	if (finished_color.a < 0.1) {
        discard;
	}
	
	frag_color = finished_color;
}`; 

text_shader_vert :: ` 
#version 320 es

layout (location = 0) in vec4 i_vertex; // <vec2 pos, vec2 tex>
out vec2 o_uv;

uniform mat4 projection;

void main() {
    gl_Position = projection * vec4(i_vertex.xy, 0.0, 1.0);
    o_uv = i_vertex.zw;
}`;

text_shader_frag :: ` 
#version 320 es

lowp in vec2 o_uv;
lowp out vec4 frag_color;

uniform sampler2D text;
lowp uniform vec3 text_color;

void main() {    
    lowp vec4 sampled_color = vec4(1.0, 1.0, 1.0, texture(text, o_uv).r);
    frag_color = vec4(text_color, 1.0) * sampled_color;
}`;


//////////////////////////////// MOUSE


// wrapper around global context to get the current mouse pos
get_mouse_pos :: proc() -> Vec2 {
	return global_context.mouse_pos - global_context.window_offset;
}

is_right_mouse_down :: proc() -> bool {
	return global_context.mouse_right[0] != 0;
}

is_left_mouse_down :: proc() -> bool {
	return global_context.mouse_left[0] != 0;
}

is_right_mouse_clicked :: proc() -> bool {
	return global_context.mouse_right[0] == 1 && global_context.mouse_right[1] != 1;
}

is_left_mouse_clicked :: proc() -> bool {
	return global_context.mouse_left[0] == 1 && global_context.mouse_left[1] != 1;
}


////////////////////////////////


// store input for any key in the game, seeing wether its currently down or not
InputPresses := make(map[glfw.Key] i8);

destroy_input :: proc() {
	delete (InputPresses);
}

is_key_down :: proc(key: glfw.Key) -> bool {
	return glfw.get_key(global_context.window, key) == glfw.PRESS;
}

is_key_pressed :: proc(key: glfw.Key) -> bool {
	pressed := glfw.get_key(global_context.window, key) == glfw.PRESS;
	
	defer InputPresses[key] = pressed ? 1 : 0;
	
	return pressed && InputPresses[key] != 1;
}

/*
is_key_released :: proc(key: glfw.Key) -> bool {
 released := glfw.get_key(global_context.window, key) == glfw.RELEASE;
 InputPresses[key] = 0;
 
 return released;
}*/