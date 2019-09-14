package examples

using import "core:math"
using import "../../schlicht" 

main :: proc() {
    // init window and opengl
    init_context("Primitives", 500, 500);
    defer destroy_context();
    context_color(WHITE);
    
    // folder name where your assets are
    init_assets("examples/resources");
    defer destroy_assets();
    
    // endless proc you can extend with any amount of string names
    load_all_textures("white");
    
    // bad: this needs to be done to get primitive color rendering working currently
    global_context.white_texture_id = global_assets.textures["white"].id;
    
    angle: f32 = 0.0;
    for context_alive() {
        update_begin_context();
        
        // really simple commands 
        draw_rectangle(Vec2 { 0, 0 }, Vec2 { 50, 50 }, false, RED);
        // Vec2 can be ommited 
        draw_rectangle({ 50, 0 }, { 50, 50 }, false, BLUE);
        
        // optional arguments you can use, look at draw.odin if you forget them
        draw_rectangle({ 100, 100 }, { 50, 50 }, false, GREEN, angle);
        draw_rectangle({ 100, 100 }, { 50, 50 }, true, RED, angle);
        draw_rectangle({ 100, 100 }, { 50, 50 }, true, BLUE, angle, 2.0);
        
        angle += 0.01;
        
        update_end_context();
    }
}