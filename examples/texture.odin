package examples

using import "core:math"
using import "../../schlicht" 

main :: proc() {
    // init window and opengl
    init_context("Texture", 500, 500);
    defer destroy_context();
    context_color(WHITE);
    
    // folder name where your assets are
    init_assets("examples/resources");
    defer destroy_assets();
    
    // endless proc you can extend with any amount of string names
    load_all_textures("white", "ground");
    
    // bad: this needs to be done to get primitive rendering working currently
    // global_context.white_texture_id = global_assets.textures["white"].id;
    
    // create a copy that we can easily reference
    ground_texture := global_assets.textures["ground"];
    
    angle: f32 = 0.0;
    for context_alive() {
        update_begin_context();
        
        // simple draw with a reference of a texture 
        draw_texture(&ground_texture, Vec2 { 0, 0 });
        // Vec2 {} can be omitted
        draw_texture(&ground_texture, { 32, 32 });
        
        // optional arguments for draw commands can be used, look at draw.odin for options like centering, rotation, etc
        draw_texture(&ground_texture, { 100, 100 }, false, angle);
        draw_texture(&ground_texture, { 150, 100 }, true, angle);
        draw_texture(&ground_texture, { 200, 100 }, true, angle, 2.0);
        
        angle += 0.01;
        
        update_end_context();
    }
}