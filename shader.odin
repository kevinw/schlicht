package schlicht

import gl "shared:odin-gl"

Shader :: struct {
	program: u32,
	projection, model, view, color: i32,
	pos_location, uv_location: u32,
}

init_shader :: proc(vertex, fragment: string) -> Shader {
	// shader loading
	program, success := gl.load_shaders_file(vertex, fragment);
	
	// fails at runtime and displays error
	if !success do panic("shader loading failed, maybe it didnt find the file or couldnt compile the shader");
	
    return Shader {
		program = program,
        projection = gl.get_uniform_location(program, "projection"),
        model = gl.get_uniform_location(program, "model"),
        view = gl.get_uniform_location(program, "view"),
        color = gl.get_uniform_location(program, "color"),
        pos_location = cast(u32) gl.get_attribute_location(program, "i_pos"),
        uv_location = cast(u32) gl.get_attribute_location(program, "i_uv"),
	};
}