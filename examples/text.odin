package examples

using import "core:math"
using import "../../schlicht" 
import stbtt "shared:odin-stb/stbtt" 
import stbti "shared:odin-stb/stbi" 
import gl "shared:odin-gl"
import "core:os"

main :: proc() {
    // init window and opengl
    init_context("Text", 500, 500);
    defer destroy_context();
    context_color(WHITE);
    
    // folder name where your assets are
    init_assets("examples/resources");
    defer destroy_assets();
    
    // endless proc you can extend with any amount of string names
    load_all_textures("white");
    
    // bad: this needs to be done to get primitive color rendering working currently
    global_context.white_texture_id = global_assets.textures["white"].id;
    
    read_ttf("consola.ttf");
    
    for context_alive() {
        update_begin_context();
        
        draw_rectangle(Vec2 { 0, 0 }, Vec2 { 50, 50 }, false, RED);
        //stbtt
        
        update_end_context();
    }
}

Character :: struct {
    id, advance: u32, 
    size, bearing: Vec2,
}

global_characters: map[u8] Character;

TextShader :: struct {
    program: u32,
    projection, text_color: i32,
}

global_text_shader: TextShader;

import "core:fmt"

font_size: u32 = 40;
font_atlas_width: u32 = 1024;
font_atlas_height: u32 = 1024;
font_oversample_x: u32 = 2;
font_oversample_y: u32 = 2;
font_first_char: u32 = ' ';
font_char_count: u32 = '~' - ' ';
font_texture: u32 = 0;

read_ttf :: proc(file_name: string) {
    using stbtt;
    
    // load text shader 
    program, program_success := gl.load_shaders_source(text_shader_vert, text_shader_frag);
    
    if !program_success do panic("TTF: Shader failed loading");
    
    global_text_shader = TextShader {
        program = program,
        projection = gl.get_uniform_location(program, "projection"),
        text_color = gl.get_uniform_location(program, "text_color"),
    };
    
    font_data, ttf_success := os.read_entire_file(file_name);
    defer delete(font_data);
    
    if !ttf_success do panic("TTF: Font file reading failed or couldnt find file");
    
    /*
    font_info: stbtt_fontinfo = ---;
    if !init_font(&font_info, font_data, 0) do panic("TTF: font couldnt init"); 
    */

    font_atlas_data := make([]u8, font_atlas_width * font_atlas_height);
    defer delete(font_atlas_data);
    
    pack_context, success := pack_begin(font_atlas_data, cast(int) font_atlas_width, cast(int) font_atlas_height, 0, 1);
    
    if !success do panic("TTF: pack_begin failed");
    
    pack_set_oversampling(&pack_context, cast(int) font_oversample_x, cast(int) font_oversample_y);
    
    font_char_info := make([]stbtt_packedchar, font_char_count);
    defer delete(font_char_info);
    
    test := pack_font_range(&pack_context, font_data, 0, cast(f32) font_size, cast(i32) font_first_char, font_char_info);
    
    pack_end(&pack_context);
    
    gl.GenTextures(1, &font_texture);
    gl.BindTexture(gl.TEXTURE_2D, font_texture);
    gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1);

    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, cast(i32) font_atlas_width, cast(i32) font_atlas_height, 0, gl.RED, gl.UNSIGNED_BYTE, &font_atlas_data[0]);
    
    //gl.Hint(gl.GENERATE_MIPMAP_HINT, gl.NICEST);
    //gl.GenerateMipmap(gl.TEXTURE_2D);
}