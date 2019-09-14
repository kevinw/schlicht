package schlicht

using import "core:math"
import gl "shared:odin-gl"
import "shared:odin-stb/stbi"


////////////////////////////////


// pixels, width and height data struct
Image :: struct {
	data: ^u8,
	width, height, channels: i32,
}

// stbi load
init_image :: proc(file_name: string) -> Image {
	image: Image;
	
	c_file_name := cast([]u8) file_name;
	image.data = stbi.load(&c_file_name[0], &image.width, &image.height, &image.channels, 0);
	
	return image;
    
}
// destroy image after loading into gl
destroy_image :: proc(image: Image) {
	stbi.image_free(image.data);
}


////////////////////////////////


// gl texture with id and width / height
Texture :: struct {
	id: u32, 
	dimensions: Vec2, 
}

// load pixel data into opengl and store data 
init_texture :: proc(image: ^Image) -> Texture {
	texture := Texture { dimensions = Vec2 { cast(f32) image.width, cast(f32) image.height }};
	
    gl.GenTextures(1, &texture.id);
	gl.BindTexture(gl.TEXTURE_2D, texture.id);
	
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.MIRRORED_REPEAT);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
	
	if image.data != nil {
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, image.width, image.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, image.data);
		gl.GenerateMipmap(gl.TEXTURE_2D);
	}
	else {
		panic("Image data didnt contain any valid data");
	}
	
	return texture;
}

unload_texture :: proc(texture_id: ^u32) {
	gl.DeleteTextures(1, texture_id);
}


////////////////////////////////


// Texture storage so you dont always have to generate all tile info for vertices
TextureSelection :: struct {
    using texture: Texture,
    sprite_dimensions: Vec2,
    frame_index: u32,
    old_frame_index: u32,
    
    tile_dimensions: Vec2,
    num_per_row: f32,
    tile_pos: Vec2,
}

init_texture_selection :: proc(texture: Texture, sprite_dimensions: Vec2) -> TextureSelection {
    return TextureSelection {
        texture = texture,
        sprite_dimensions = sprite_dimensions,
        old_frame_index = 1000,
        frame_index = 0,
    };
}

get_texture_selection_vertices :: proc(using texture_selection: ^TextureSelection, new_frame_index: u32 = 0, centered: bool = false) -> [4]Vertex {
    defer old_frame_index = frame_index;
    frame_index = new_frame_index;
    
    number_of_regions := dimensions / sprite_dimensions;
    uv := Vec2 {
        f32(i32(frame_index) % i32(number_of_regions.x)) / number_of_regions.x,
        f32(i32(frame_index) / i32(number_of_regions.y)) / number_of_regions.y - 1.0,
    };
    
    // TODO(Skytrias): use less code
    if !centered {
        return [4]Vertex {
            Vertex {
                { 0, 0 },
                uv,
            },
            Vertex {
                { 1, 0 },
                Vec2 { uv.x + 1.0 / number_of_regions.x, uv.y },
            },
            Vertex {
                { 1, 1 },
                Vec2 { uv.x + 1.0 / number_of_regions.x, uv.y + 1.0 / number_of_regions.y },
            },
            Vertex {
                { 0, 1 },
                Vec2 { uv.x, uv.y + 1.0 / number_of_regions.y },
            }
        };
    } else {
        return [4]Vertex {
            Vertex {
                { -0.5, -0.5 },
                uv,
            },
            Vertex {
                { 0.5, -0.5 },
                Vec2 { uv.x + 1.0 / number_of_regions.x, uv.y },
            },
            Vertex {
                { 0.5, 0.5 },
                Vec2 { uv.x + 1.0 / number_of_regions.x, uv.y + 1.0 / number_of_regions.y },
            },
            Vertex {
                { -0.5, 0.5 },
                Vec2 { uv.x, uv.y + 1.0 / number_of_regions.y },
            }
        };
    }
}