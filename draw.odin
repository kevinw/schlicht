package schlicht

using import "core:math"

import gl "shared:odin-gl"

// set colors to be used easily
BLACK := Vec4 { 0, 0, 0, 1 };
WHITE := Vec4 { 1, 1, 1, 1 };
RED := Vec4 { 1, 0, 0, 1 };
BLUE := Vec4 { 0, 0, 1, 1 };
GREEN := Vec4 { 0, 1, 0, 1 };

// updates all uniforms used for rendering primitives or textures
@private
update_uniforms :: proc(pos, dimensions: Vec2, in_color: Vec4, angle_radians: f32, scale: f32) {
	using global_context;
    
    model := identity(Mat4);
    
    translated := mat4_translate({ pos[0], pos[1], 0.0 });
    rotated := mat4_rotate({ 0, 0, 1 }, angle_radians);
    scaled := scale_vec3(model, { dimensions[0] * scale, dimensions[1] * scale, 1.0 });
	
    model = mat4_mul(model, translated);
    model = mat4_mul(model, rotated);
    model = mat4_mul(model, scaled);
    
    gl.UseProgram(primitive_shader.program);
    gl.UniformMatrix4fv(primitive_shader.model, 1, gl.FALSE, &model[0][0]);
    color := in_color;
    gl.Uniform4fv(primitive_shader.color, 1, cast(^f32) &color);
}

// primitive draw call to reduce individual calls
@private
draw_primitive :: proc(filled: bool, centered: bool = false, gl_draw_enum: u32 = 0) {
    using global_context;
    
    // chose centered or quad vertices
    if !centered {
        gl.BindVertexArray(quad_vao);
    } else {
        gl.BindVertexArray(centered_vao);
    }
    
    // primitive white texture to get original color
    gl.BindTexture(gl.TEXTURE_2D, white_texture_id);
    
    // draw via indices to get filled or just line drawing
    if filled {
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo); 
        gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil);
    } else {
        gl.DrawArrays(gl_draw_enum, 0, 4);
    }
    
    gl.BindVertexArray(0);
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
}

// draws a rectangle at the position with its dimensions,
// wether it gets centered, rotation, scale and line width
draw_rectangle :: proc(pos, dimensions: Vec2, centered: bool = false,color: Vec4 = WHITE, angle_radians: f32 = 0.0, scale: f32 = 1.0, line_width: f32 = 1.0) {
	update_uniforms(pos, dimensions, color, angle_radians, scale);
	gl.LineWidth(line_width);
    draw_primitive(false, centered, gl.LINE_LOOP);
}

// draws a filled rectangle at the position with its dimensions,
// wether it gets centered, rotation, scale and line width
draw_filled_rectangle :: proc(pos, dimensions: Vec2, centered: bool = false,color: Vec4 = WHITE, angle_radians: f32 = 0.0, scale: f32 = 1.0) {
    update_uniforms(pos, dimensions, color, angle_radians, scale);
    draw_primitive(true, centered);
}

// draws a connected line from 2 positions
draw_line :: proc(from, to: Vec2, in_color: Vec4 = WHITE, line_width: f32 = 1.0) {
	using global_context;
	
    line_vertices := [2]Vec2 {
		from,
        to,
    };  
    
	model := identity(Mat4);
	gl.UseProgram(primitive_shader.program);
	gl.UniformMatrix4fv(primitive_shader.model, 1, gl.FALSE, &model[0][0]);
	color := in_color;
	gl.Uniform4fv(primitive_shader.color, 1, cast(^f32) &color);
	
	gl.LineWidth(line_width);
	
	gl.BindBuffer(gl.ARRAY_BUFFER, line_vbo);
    gl.BufferData(gl.ARRAY_BUFFER, size_of(line_vertices), &line_vertices[0], gl.STATIC_DRAW);
    
    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 0, nil);
    gl.EnableVertexAttribArray(0);
    
    gl.BindTexture(gl.TEXTURE_2D, white_texture_id);
    gl.DrawArrays(gl.LINES, 0, 2);
    
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
}

// draws a circle with a set amount of segments, offset by pos - size by radius
draw_circle :: proc(pos: Vec2, radius: f32, color: Vec4 = WHITE, line_width: f32 = 1.0) {
	using global_context;
	
    line_segments :: 30;
	circle_vertices: [line_segments]Vec2;
	
	// rotate each vertice to the right position from the center
	for i: i32 = 0; i < line_segments; i += 1 {
		angle := f32(i) / line_segments * TAU;
		
		circle_vertices[i] = Vec2 {
			cos(angle) * radius, sin(angle) * radius,
		};
	}
	
    update_uniforms(pos, { 1, 1 }, color, 0.0, 1.0);
    
	gl.LineWidth(line_width);
	
	gl.BindBuffer(gl.ARRAY_BUFFER, circle_vbo);
	gl.BufferData(gl.ARRAY_BUFFER, size_of(circle_vertices), &circle_vertices[0], gl.STATIC_DRAW);
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 0, nil);
	gl.EnableVertexAttribArray(0);
    
    gl.BindTexture(gl.TEXTURE_2D, white_texture_id);
	gl.DrawArrays(gl.LINE_LOOP, 0, cast(i32) len(circle_vertices));
    
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
}

// draws a circle with a set amount of segments, offset by pos - size by radius
draw_filled_circle :: proc(pos: Vec2, radius: f32, color: Vec4 = WHITE) {
	using global_context;
	
    line_segments :: 30;
	circle_vertices: [line_segments]Vec2;
	
	// rotate each vertice to the right position from the center
	for i: i32 = 0; i < line_segments; i += 1 {
		angle := f32(i) / line_segments * TAU;
		
		circle_vertices[i] = Vec2 {
			cos(angle) * radius, sin(angle) * radius,
		};
	}
	
    update_uniforms(pos, { 1, 1 }, color, 0.0, 1.0);
    
	// generate new point vertex on the fly
	circle_vertex: u32 = 0;
	gl.GenBuffers(1, &circle_vertex);
	gl.BindBuffer(gl.ARRAY_BUFFER, circle_vertex);
	gl.BufferData(gl.ARRAY_BUFFER, size_of(circle_vertices), &circle_vertices[0], gl.STATIC_DRAW);
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 0, nil);
	gl.EnableVertexAttribArray(0);
    
    gl.BindTexture(gl.TEXTURE_2D, white_texture_id);
	gl.DrawArrays(gl.TRIANGLE_FAN, 0, cast(i32) len(circle_vertices));
    
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
}

@private
draw_textured :: proc(texture_id: u32, centered: bool) {
    using global_context;
    
    if !centered {
        gl.BindVertexArray(quad_vao);
    } else {
        gl.BindVertexArray(centered_vao);
    }
    
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
    gl.BindTexture(gl.TEXTURE_2D, texture_id);
    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil);
    
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindVertexArray(0);
}

// draws a rectangle at the position with a set dimensions
draw_texture :: proc(using texture: ^Texture, pos: Vec2, centered: bool = false, angle_radians: f32 = 0.0, scale: f32 = 1.0, color: Vec4 = WHITE) {
    using global_context;
    
    update_uniforms(pos, dimensions, color, angle_radians, scale);
    draw_textured(id, centered);
}

// draws a rectangle assigned with a texture via indices
draw_texture_selection :: proc(
using texture_selection: ^TextureSelection, 
pos: Vec2, index: u32, centered: bool = false, angle_radians: f32 = 0.0, scale: f32 = 1.0, color: Vec4 = WHITE) {
    using global_context;
    
    vertices := get_texture_selection_vertices(texture_selection, index, centered);
    
    update_uniforms(pos, sprite_dimensions, color, angle_radians, scale);
    
    gl.BindTexture(gl.TEXTURE_2D, id);
    
    gl.BindBuffer(gl.ARRAY_BUFFER, texture_vbo);
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW);
    
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
	
    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), nil);
    gl.EnableVertexAttribArray(0);
    gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), cast(rawptr) offset_of(Vertex, tex_coords));
    gl.EnableVertexAttribArray(1);
    
    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil);
    
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
}
