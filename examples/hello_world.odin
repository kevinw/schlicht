package examples

using import "../../schlicht" 

main :: proc() {
    init_context("Hello World!", 500, 500);
    defer destroy_context();
    
    for context_alive() {
        update_begin_context();
        update_end_context();
    }
}