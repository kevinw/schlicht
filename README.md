# Schlicht 
Schlicht *(german for easy)* Game framework made in [odin](https://odin-lang.org/) 

# Goals 
* Easy to use via global variables
* Not too many dependencies
* Native library for odin

# Features
* Modern OpenGL
* Primitive Rendering: Point, Line, Rectangle, Circle
* Texture Rendering: Sprite, Spritesheet
* Simple Asset Manager

# Dependencies
* OpenGL
* GLFW
* stb_image

# Examples
Check out the examples to see ways to use this framework.
You can run examples from the main folder via `odin run examples/example_name.odin`

# How to Use
1. Install [odin](https://odin-lang.org/)
2. Download library dependencies into your odin/shared folder and follow their build steps
	* [schlicht](https://github.com/Skytrias/schlicht)
	* [odin-gl](https://github.com/vassvik/odin-gl) 
	* [odin-gl_font](https://github.com/vassvik/odin-gl_font) 
	* [odin-stb](https://github.com/vassvik/odin-stb)
	* ... more might follow
3. Run `odin run main.odin` and output into a format your OS needs
	* linux: `odin run main.odin -out=build/klei-plane`
	* windows: `odin run main.odin -out/build/klei-plane.exe`

# Source Code
Source code might look weirdly indented because my editor auto indents for me. 
