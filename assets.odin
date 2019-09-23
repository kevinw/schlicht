package schlicht

import strings "core:strings"

// global assets that will be used in the engine
global_assets: Assets;

// global assets storage for textures
Assets :: struct {
	textures: map[string] Texture,
	folder: string,
}

// init dynamic arrays
init_assets :: proc(folder_name: string) {
	global_assets = Assets {
		textures = make(map[string] Texture),
		folder = folder_name
	};
}

// manually loads a texture from a full path you've provided, saves the texture under the texture_name provided
load_texture_manual :: proc(file_name: string, texture_name: string) {
    using global_assets;
    
    img := init_image(file_name);
    textures[texture_name] = init_texture(&img);
    
    destroy_image(img);
}

// loads a single texture that gets added to the textures map
load_texture :: proc(file_name: string) {
	using global_assets;
	
	img := init_image(
		strings.concatenate([]string { folder, "/", file_name, ".png" })
		);
	
	textures[file_name] = init_texture(&img);
	
	destroy_image(img);
}

// loads a variable amount of texture files
load_all_textures :: proc(files: ..string) {
	using global_assets;
	
	for file in files {
		load_texture(file);
	}
}

// destroy the maps
destroy_assets :: proc() {
	using global_assets;
	
	for key in textures {
		copy_of_id := textures[key].id;
        unload_texture(&copy_of_id);
    }
    
    delete(textures);
}


