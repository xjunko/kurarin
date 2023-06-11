module runtime

import gg
import sokol.gfx
import sokol.sgl
import sokol.sapp
import mohamedlt.sokolgp as sgp
import framework.graphic.window as i_window
import framework.graphic.context

[heap]
pub struct Window {
	i_window.GeneralWindow
pub mut:
	img gg.Image
}

pub fn (mut window Window) init(_ voidptr) {
	// Init Renderer(s)
	// Renderer: SGP
	sgp_desc := sgp.Desc{}
	sgp.setup(&sgp_desc)

	if !sgp.is_valid() {
		panic('Failed to init SokolGP: ${sgp.get_error_message(sgp.get_last_error())}')
	}

	window.img = window.ctx.create_image('/home/junko/Pictures/1.png')
}

pub fn (mut window Window) draw(_ voidptr) {
	window.ctx.begin()

	width := sapp.width()
	height := sapp.height()

	sgp.begin(width, height)
	sgp.viewport(0, 0, width, height)

	sgp.set_color(0.1, 0.1, 0.1, 1.0)
	sgp.clear()

	window.ctx.draw_image_batch_with_config(
		img: &window.img
		img_id: window.img.id
		img_rect: gg.Rect{
			x: 0
			y: 0
			width: 1280
			height: 720
		}
		color: gg.Color{255, 255, 255, 255}
	)

	gfx.begin_default_pass(window.ctx.clear_pass, sapp.width(), sapp.height())

	sgp.flush()
	sgp.end()

	sgl.draw()

	gfx.end_pass()
	gfx.commit()
}

pub fn run() {
	mut window := &Window{}

	mut gg_context := gg.new_context(
		width: 1280
		height: 720
		user_data: window
		// FNs
		init_fn: window.init
		frame_fn: window.draw
	)

	window.ctx = &context.Context{
		Context: gg_context
	}
	window.ctx.run()
}
