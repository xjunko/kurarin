module graphic

/*
	THE ONE AND ONLY

	SLIDER RENDER RER

	I FUCKING HATE SLIDER RENDER RER
*/

/*
	BIG FUCKEN TODO

	* figure out how the fuck to create a rendertarget (with depth test and blending)
	* render slider on the rendertarget (with depth test and without blending) (pass 1)
	* draw the rendertarget on the screen with (without depth test and with blending) (pass 2)

	// OK DONE :DDDD
*/

import game.settings
import game.x

import math

import sokol
import sokol.gfx
import sokol.sgl // TODO: use sokol's wrapper structs instead of C's 

import framework.logging
import framework.math.vector
import framework.math.time

#flag -I @VMODROOT/
#include "assets/shaders/slider.h"
// #include "assets/shaders/test.h"

fn C.fuck_shader_desc(gfx.Backend) &C.sg_shader_desc
// fn C.test_shader_desc(gfx.Backend) &C.sg_shader_desc

pub const (
	used_import = gfx.used_import + sokol.used_import
	global_renderer = &SliderRenderer{}
	use_test_shader = false
)

pub struct SliderRendererAttr {
	pub mut:
		cs       f64
		length   f64
		points   []vector.Vector2
		vertices []f32
		colors   []f32 // [3]Body [3]Border [3]BorderWidth, Unused, Unused
		uniform  C.sg_range
		bindings C.sg_bindings
		has_been_initialized bool
}

pub struct SliderRenderer {
	mut:
		quality              int  = 30 // anything >= 3 is fine
		has_been_initialized bool

	pub mut:
		shader      C.sg_shader
		pip         C.sg_pipeline
		pass        gfx.Pass
		pass_action C.sg_pass_action
		pass_action2 C.sg_pass_action
		gradient    C.sg_image
		uniform     C.sg_range
		color_img gfx.Image
		depth_img gfx.Image
		uniform_values []f32 // 
}

// Boost scaling thingy
pub fn update_boost_level(boost f32) {
	mut g_render := global_renderer
	g_render.uniform_values[16] = boost
}


// Maker
pub fn make_circle_vertices(position vector.Vector2, cs f64) []vector.Vector2 {
	mut points := []vector.Vector2{}
	points << position

	for i := 0; i < global_renderer.quality; i++ {
		points << vector.new_vec_rad(
			f64(i)/f64(global_renderer.quality)*2.0*math.pi,
			cs
		).add_normal(position.x, position.y)
	}

	points << points[1]

	return points
}

pub fn make_slider_renderer_attr(cs f64, points []vector.Vector2, pixel_length f64) &SliderRendererAttr {
	mut attr := &SliderRendererAttr{}

	// Attributes
	attr.cs = cs
	attr.points = points
	attr.length = pixel_length

	// Color uniform
	attr.colors = []f32{}
	attr.colors << [
		f32(0.0), f32(0.0), f32(0.0), 1.0, // Body
		f32(1.0), f32(1.0), f32(1.0), 1.0, // Border
		f32(0.5), f32(0.0), f32(0.0), 1.0 // Width
	] // ghost numbers, dont ask my why its there

	attr.uniform = C.sg_range{
		ptr: attr.colors.data,
		size: usize(attr.colors.len * int(sizeof(f32)))
	}

	return attr

}

pub fn (mut attr SliderRendererAttr) make_vertices() {
	/*
		for whatevrer reason i cant make buffer on gothread/coroutine, only on draw calls bruh
	*/

	if attr.has_been_initialized { return }

	attr.vertices = []f32{}//len: int(attr.length * 30 * 24)}

	// Make the fuckng verticds sss
	for _, v in attr.points {
		tab := make_circle_vertices(v, attr.cs)
		for j, _ in tab {
			if j >= 2 {
				p1, p2, p3 := tab[j - 1], tab[j], tab[0]
				// Format
				// Position [vec3], Centre [vec3], TextureCoord [vec2]
				attr.vertices << &[
					f32(p1.x), f32(p1.y), 1.0,
					f32(p3.x), f32(p3.y), 0.0, 
					0.0, 0.0, 

					f32(p2.x), f32(p2.y), 1.0, 
					f32(p3.x), f32(p3.y), 0.0, 
					0.0, 0.0, 
					
					f32(p3.x), f32(p3.y), 0.0, 
					f32(p3.x), f32(p3.y), 0.0, 
					1.0, 0.0
				]
			}
		}
	}

	// // Test shader vertices
	// attr.vertices = [
	// 	// Positions				// Colors
	// 	f32(-.5), -.5, .0,			1.0, .0, .0,
	// 	.5, -.5, .0,				.0, 1.0, .0,
	// 	.0, .5, .0,					.0, .0, 1.0,
	// ]

	if attr.vertices.len == 0 {
		return // Something went wrong or the slider is just straitght up retadred
	}
	
	// Bind the shit
	attr.bindings.vertex_buffers[0] = C.sg_make_buffer(&C.sg_buffer_desc{
		size: usize(attr.vertices.len * int(sizeof(f32))),
		data: C.sg_range{
			ptr: attr.vertices.data,
			size: usize(attr.vertices.len * int(sizeof(f32)))
		}
		label: "SliderBinding".str,
	})

	// Failed to create vertex_buffers
	// if attr.bindings.vertex_buffers[0].id == 0 {
	// TODO: Fix this dumbass code
	if false {
		logging.error("Failed to bind vertex buffers")
		return 
	}

	// Done
	attr.has_been_initialized = true
}

pub fn (mut attr SliderRendererAttr) update_vertex_progress(start int, end int) {
	// TODO: come back to this
	// if !attr.has_been_initialized { 
	// 	attr.make_vertices()
	// }

	// if attr.vertices[start * 30 * 24 .. end * 30 * 24].len != 0 {	
		// C.sg_update_buffer(&attr.bindings.vertex_buffers[0], &C.sg_range{
			// ptr: &attr.vertices[start * 30 * 24 .. (end * 30 * 24) - 1][0],
			// size: usize((attr.vertices[start * 30 * 24 .. end * 30 * 24].len) * int(sizeof(f32)))
			// ptr: attr.vertices.data,
			// size: usize(attr.vertices.len * int(sizeof(f32)))
		// })	
	// }
}

// Draw
pub fn (mut attr SliderRendererAttr) draw_slider(alpha f64, colors []f64) {
	if !global_renderer.has_been_initialized { panic("global_renderer.has_been_initialized == False; This should not happen.") }

	if !attr.has_been_initialized { 
		attr.make_vertices()
		return
	}

	// Fuck around with the colors
	// Literally copy-pasted from mcosu lmaooo credit to mckay
	if settings.global.gameplay.hitobjects.rainbow_slider && !settings.global.gameplay.hitobjects.old_slider {
		time := time.global.time / 100.0
		attr.colors[0] = f32(math.sin(0.3 * time + 0 + 10) * 127 + 128) / 255
		attr.colors[1] = f32(math.sin(0.3 * time + 2 + 10) * 127 + 128) / 255
		attr.colors[2] = f32(math.sin(0.3 * time + 4 + 10) * 127 + 128) / 255

		attr.colors[4] = f32(math.sin(0.3 * time * 1.5 + 0 + 10) * 127 + 128) / 255
		attr.colors[5] = f32(math.sin(0.3 * time * 1.5 + 2 + 10) * 127 + 128) / 255
		attr.colors[6] = f32(math.sin(0.3 * time * 1.5 + 4 + 10) * 127 + 128) / 255
	}

	// Set border color
	if !settings.global.gameplay.hitobjects.old_slider {
		attr.colors[0] = f32(colors[0] / 255.0 / 1.5)
		attr.colors[1] = f32(colors[1] / 255.0 / 1.5)
		attr.colors[2] = f32(colors[2] / 255.0 / 1.5)
		
		attr.colors[4] = f32(colors[0] / 255.0)
		attr.colors[5] = f32(colors[1] / 255.0)
		attr.colors[6] = f32(colors[2] / 255.0)
	}

	// FIXME: This is janky asf lmao but it works
	gfx.begin_pass(global_renderer.pass, &global_renderer.pass_action2)
		gfx.apply_pipeline(global_renderer.pip)
			gfx.apply_bindings(&attr.bindings)
			gfx.apply_uniforms(.vs, C.SLOT_vs_uniform, global_renderer.uniform)
			gfx.apply_uniforms(.fs, C.SLOT_fs_uniform, attr.uniform)
				gfx.draw(0, attr.vertices.len, 1)
		gfx.end_pass()
	gfx.commit()


	gfx.begin_default_pass(graphic.global_renderer.pass_action, int(settings.global.window.width), int(settings.global.window.height))
		sgl.enable_texture()
			sgl.texture(global_renderer.color_img)
		sgl.c4b(255, 255, 255, u8(255 - ( 255 * alpha )))
		sgl.begin_quads()
			sgl.v3f_t2f(0,    0,   1, 0, 1)
			sgl.v3f_t2f(int(settings.global.window.width), 0,   							   1, 1, 1)
			sgl.v3f_t2f(int(settings.global.window.width), int(settings.global.window.height), 1, 1, 0)
			sgl.v3f_t2f(0,    							   int(settings.global.window.height), 1, 0, 0)
		sgl.end()
		sgl.disable_texture()
			sgl.draw()
		gfx.end_pass()
	gfx.commit()
}

pub fn (mut attr SliderRendererAttr) free() {
	// Free shit
	if !attr.has_been_initialized { return }

	for mut buffer in attr.bindings.vertex_buffers {
		buffer.free()
	}

	unsafe {
		attr.vertices.free()
		attr.points.free()
	}
}


// Init
pub fn init_slider_renderer() {
	// Start
	logging.info("Initializing slider renderer!")

	mut renderer := global_renderer

	// Normal slider shader
	renderer.shader = C.sg_make_shader(
		C.fuck_shader_desc(
			C.sg_query_backend()
		)
	)

	// Make pipeline
	mut pipeline_desc := &C.sg_pipeline_desc{
		shader: renderer.shader,
		depth: C.sg_depth_state{
			pixel_format: .depth
			compare: .less,
			write_enabled: true
		}
	}

	// Pipeline blending (for slider to appear correctly, well almost.)
	pipeline_desc.colors[0].pixel_format = .rgba8
	pipeline_desc.colors[0].blend.enabled = false
	pipeline_desc.colors[0].blend.op_rgb = .add
	pipeline_desc.colors[0].blend.src_factor_rgb = .src_alpha
	pipeline_desc.colors[0].blend.dst_factor_rgb = .one_minus_src_alpha


	// Pipeline attribute 
	pipeline_desc.layout.attrs[C.ATTR_vs_in_position].format = .float3 // pos
	pipeline_desc.layout.attrs[C.ATTR_vs_centre].format = .float3 // centre
	pipeline_desc.layout.attrs[C.ATTR_vs_texture_coord].format = .float2 // texture coord
	renderer.pip = C.sg_make_pipeline(pipeline_desc)

	// // Test Shader
	// renderer.shader = C.sg_make_shader(
	// 	C.test_shader_desc(
	// 		C.sg_query_backend()
	// 	)
	// )

	// mut pipeline_desc := &C.sg_pipeline_desc{shader: renderer.shader}
	// pipeline_desc.layout.attrs[C.ATTR_vs_test_position].format = .float3
	// pipeline_desc.layout.attrs[C.ATTR_vs_test_color].format = .float3
	// renderer.pip = C.sg_make_pipeline(pipeline_desc)

	// Color and Depth buffer
	mut img_desc := gfx.ImageDesc{
		render_target: true,
		width: int(settings.global.window.width),
		height: int(settings.global.window.height),
		pixel_format: .rgba8,
		label: "ColorBuffer".str
	}
	renderer.color_img = gfx.make_image(&img_desc)
	img_desc.pixel_format = .depth
	img_desc.label = "DepthBuffer".str
	renderer.depth_img = gfx.make_image(&img_desc)

	// Pass
	mut offscreen_pass_desc := gfx.PassDesc{label: "offscreen-pass".str}
	offscreen_pass_desc.color_attachments[0].image = renderer.color_img
	offscreen_pass_desc.depth_stencil_attachment.image = renderer.depth_img
	renderer.pass = gfx.make_pass(&offscreen_pass_desc)
	

	// Pass action
	renderer.pass_action.colors[0] = C.sg_color_attachment_action{
		action: .dontcare,
		value: C.sg_color{1.0, 1.0, 1.0, 1.0}
	}

	renderer.pass_action2.colors[0] = C.sg_color_attachment_action{
		action: .clear,
		value: C.sg_color{1.0, 1.0, 1.0, 0.0}
	}
	

	// Uniform (projection and slider scale)
	for col in 0 .. 4 {
		for row in 0 .. 4 {
			renderer.uniform_values << x.resolution.projection.get_f(col, row)
		}	
	}

	renderer.uniform_values << [
		f32(1.0), 0.0, 0.0, 0.0,
	]
	
	renderer.uniform = C.sg_range{
		ptr: renderer.uniform_values.data,
		size: usize(renderer.uniform_values.len * int(sizeof(f32)))
	}

	// Done
	renderer.has_been_initialized = true
	logging.info("Done initializing slider renderer!")
}
