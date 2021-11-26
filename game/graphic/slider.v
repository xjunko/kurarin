/*
	TO FUCKING DO:
		* add some pooling/schedule or something instead of creating a pipeline/shader/vertex for every slider at THE START OF THE PROGRAM
		  so it doesnt use 69420gb of ram at startup
		* fix position (scaling is right so atleast im right on that one)
*/

module graphic

import stbi
import math
import sokol
import sokol.gfx
import sokol.sgl
// import sokol.sapp



import framework.graphic.sprite
import framework.math.vector
import framework.math.time
import framework.transform

import game.math.difficulty

#flag -I @VMODROOT/
#include "assets/shaders/slider.h"
#include "assets/shaders/test.h"

fn C.fuck_shader_desc(gfx.Backend) &C.sg_shader_desc
fn C.test_shader_desc(gfx.Backend) &C.sg_shader_desc

const (
	state = &GlobalState{}
	fade = transform.Transform{typ: .fade, time: time.Time{0, 500}, before: [0.0], after: [1.0]}
)

pub struct GlobalState {
	pub mut:
		init bool
		slider_gradient C.sg_image
}

pub struct State {
	mut:
		shader C.sg_shader
		pip C.sg_pipeline
		bind C.sg_bindings
		pass_action C.sg_pass_action
}

pub struct SliderRenderer {
	pub mut:
		time          &time.Time = voidptr(0)
		difficulty    difficulty.Difficulty
		curves        []vector.Vector2
		vertices      []f32
		fade          transform.Transform
		state         &State = voidptr(0)
		alpha         f64
		color         []f32

		// time
		render_time f64
		skip_offset bool
		init        bool
		special     bool = true
		is_visible  bool
		cs          f64
}

pub fn (slider SliderRenderer) make_circle(x f64, y f64, radius f64, segments int) []vector.Vector2 {
	mut points := []vector.Vector2{}
	points << vector.Vector2{x, y}

	for i := 0; i < segments; i++ {
		points << vector.new_vec_rad(f64(i)/f64(segments)*2*math.pi, radius).add_normal(x, y)
	}
	points << points[1]

	return points
}

pub fn (mut slider SliderRenderer) make_vertex() {
	// 
	if slider.vertices.len > 0 {
		return // dont make since its already craeted dddd
	}

	// make the thing
	for v in slider.curves {
		tab := slider.make_circle(v.x, v.y, 64 * slider.cs, 30)
		for j, _ in tab {
			if j >= 2 {
				p1, p2, p3 := tab[j - 1], tab[j], tab[0]
				// Format
				// Position [vec3], Centre [vec3], TextureCoord [vec2]
				slider.vertices << [
					f32(p1.x), f32(p1.y), 1.0,
					f32(p3.x), f32(p3.y), 0.0,
					0.0, 0.0,
					f32(p2.x), f32(p2.y), 1.0,
					f32(p3.x), f32(p3.y), 0.0,
					0.0, 0.0,
					f32(p3.x), f32(p3.y), 0.0,
					f32(p3.x), f32(p3.y), 0.0,
					1.0, 0.0,
				]
			}
		}
	}

	// free
	unsafe {
		slider.curves.free()
	}

	// Vertex bind
	slider.state.bind.vertex_buffers[0] = C.sg_make_buffer(&C.sg_buffer_desc{
		size: usize(slider.vertices.len * int(sizeof(f32))),
		data: C.sg_range{
			ptr: slider.vertices.data,
			size: usize(slider.vertices.len * int(sizeof(f32)))
		},
		label: "THEFUCKINGSHIT".str
	})
}

pub fn (mut slider SliderRenderer) make_pipeline(cs f64) {
	if !state.init {
		mut state_g := state
		state_g.slider_gradient = load_image("assets/shaders/gradient2.png")
		state_g.init = true
		println('> SliderRender: Gradient loaded!')
	}

	// Init shader
	slider.cs = cs
	slider.state = &State{}
	slider.state.shader = C.sg_make_shader(C.fuck_shader_desc(C.sg_query_backend()))

	// SliderGradient
	slider.state.bind.fs_images[C.SLOT_texture_in] = state.slider_gradient

	// Pipeline
	mut pipeline_desc := &C.sg_pipeline_desc{
		shader: slider.state.shader
	}
	pipeline_desc.layout.attrs[0].format = .float3 // pos
	pipeline_desc.layout.attrs[1].format = .float3 // centre
	pipeline_desc.layout.attrs[2].format = .float2 // texture coord
	slider.state.pip = C.sg_make_pipeline(pipeline_desc)

	// Make them vertecisss
	slider.make_vertex()

	// // Test shader - to see if the shader even working
	// slider.state = &State{}
	// shader := C.sg_make_shader(C.test_shader_desc(C.sg_query_backend()))
	// // Vertices
	// vertices := [
	// 	// Positions				// Colors
	// 	f32(-.5), -.5, .0,			1.0, .0, .0,
	// 	.5, -.5, .0,				.0, 1.0, .0,
	// 	.0, .5, .0,					.0, .0, 1.0,
	// ]
	// slider.state.bind.vertex_buffers[0] = C.sg_make_buffer(&C.sg_buffer_desc{
	// 	size: usize(vertices.len * int(sizeof(f32))),
	// 	data: C.sg_range{
	// 		ptr: vertices.data,
	// 		size: usize(vertices.len * int(sizeof(f32)))
	// 	},
	// 	label: 'bullshit'.str
	// })
	// // Pipeline
	// mut pipeline_desc := &C.sg_pipeline_desc{shader: shader}
	// pipeline_desc.layout.attrs[C.ATTR_vs_test_position].format = .float3
	// pipeline_desc.layout.attrs[C.ATTR_vs_test_color].format = .float3
	// slider.state.pip = C.sg_make_pipeline(pipeline_desc)

	// // Pass
	// slider.state.pass_action = C.sg_pass_action{}
	// slider.state.pass_action.colors[0] = C.sg_color_attachment_action{
	// 	action: .load,
	// 	value: C.sg_color{1.0, 1.0, 1.0, 1.0}
	// }
	// slider.vertices << [f32(1), 2, 3]


	// Dnone
	slider.init = true
	slider.is_visible = false
}

pub fn (mut slider SliderRenderer) update(time f64) {
	// Alpha thingy
	if time < (slider.time.start - slider.difficulty.preempt / 2) {
		slider.alpha = f64(time - (slider.time.start-i64(slider.difficulty.preempt)))/(slider.difficulty.preempt/2)
	} else if time >= slider.time.end {
		slider.alpha = 1.0 - f64(time - slider.time.end)/(slider.difficulty.preempt/4)
	} 

	if time >= (slider.time.start - slider.difficulty.preempt) && time <= slider.time.end {
		slider.is_visible = true
	} else if time >= slider.time.end + 1000 {
		slider.is_visible = false
	}

	// TODO: this crashes if enabled
	// Init slider stuff
	// if time >= slider.time.start - 2000 {
	// 	slider.make_vertex()
	// }

	// Unitialize the slider stuff after 500ms
	if (time >= slider.time.end + 500) && (slider.vertices.len > 0) && slider.init && false {
		slider.is_visible = false
		slider.init = false
		unsafe {
			slider.vertices.free()
			C.sg_destroy_buffer(slider.state.bind.vertex_buffers[0])
			C.sg_destroy_shader(slider.state.shader)
			C.sg_destroy_pipeline(slider.state.pip)
		}
	}
}

pub fn (mut slider SliderRenderer) draw(arg sprite.DrawConfig) {
	slider.update(arg.time)

	if !slider.init || !slider.is_visible || slider.vertices.len == 0 || slider.alpha <= 0.0 { return }
	// C.sg_begin_default_pass(&slider.state.pass_action, 1280, 720)
	gfx.apply_pipeline(slider.state.pip)
	gfx.apply_bindings(&slider.state.bind)

	// DOnt need this anymore since its in the shader itslef
	/*
	mut fucking_projection_and_transformation_shit := [
		f32(0.1628), 0.000000, 0.000000, -0.0416667,
		0.000000, -0.2894, 0.000000, 0.555556,
		0.000000, 0.000000, 1.000000, 0.0,
		0.000000, 0.000000, 0.000000, 20.000000
	]
	fucking_projection_and_transformation_shit << [
		f32(1),0,0,0,
		0,1,0,0,
		0,0,1,0,
		0,0,0,1
	]
	// println(fucking_projection_and_transformation_shit)

	vs_params := C.sg_range{
		ptr: fucking_projection_and_transformation_shit.data,
		size: usize(fucking_projection_and_transformation_shit.len * int(sizeof(f32)))
	}
	gfx.apply_uniforms(C.SG_SHADERSTAGE_VS, C.SLOT_vs_params, &vs_params)
	*/

	// fs params
	mut fs_params_arg := [
		slider.color[0], slider.color[1], slider.color[2], 1,
		f32(slider.alpha), 0, 0, 0,
	]
	fs_params := C.sg_range{
		ptr: fs_params_arg.data,
		size: usize(fs_params_arg.len * int(sizeof(f32)))
	}
	gfx.apply_uniforms(C.SG_SHADERSTAGE_FS, C.SLOT_fs_params, &fs_params)

	gfx.draw(0, slider.vertices.len, 1)
	// gfx.end_pass()
	// gfx.commit()
}

pub fn (mut slider SliderRenderer) draw_and_update(arg sprite.DrawConfig) {
	slider.update(0)
	slider.draw(arg)
}


// BRUH
pub fn load_image(path string) C.sg_image {
	// stbi.set_flip_vertically_on_load(true)
	stb_img := stbi.load(path) or { panic(err) }
	mut img_desc := C.sg_image_desc{
		width: stb_img.width,
		height: stb_img.height,
		num_mipmaps: 0,
		wrap_u: .clamp_to_edge,
		wrap_v: .clamp_to_edge,
		label: path.str,
		d3d11_texture: 0
	}
	img_desc.data.subimage[0][0] = C.sg_range{
		ptr: stb_img.data,
		size: usize(stb_img.nr_channels * stb_img.width * stb_img.height)
	}
	return C.sg_make_image(&img_desc)
}