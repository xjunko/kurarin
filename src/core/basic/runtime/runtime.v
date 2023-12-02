module runtime

import gg
import sokol.gfx
import sokol.sgl
import sokol.sapp
import framework.graphic.window as i_window
import framework.graphic.context

@[heap]
pub struct Window {
	i_window.GeneralWindow
pub mut:
	img gg.Image
}

pub fn (mut window Window) init(_ voidptr) {
	window.img = window.ctx.create_image('/home/junko/Pictures/1.png')
}

pub fn (mut window Window) draw(_ voidptr) {
	window.ctx.begin()

	width := sapp.width()
	height := sapp.height()

	window.ctx.draw_image_with_config(
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
