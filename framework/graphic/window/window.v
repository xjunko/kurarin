module window

import library.gg
import gx

import framework.math.time

import core.common.constants

// Generic window struc
// Contains: FPS counter and some other info shit
pub struct GeneralWindow {
	mut:
		time_took_to_render time.TimeCounter
		time_took_to_update time.TimeCounter

	pub mut:
		ctx &gg.Context = voidptr(0)
}

pub fn (mut window GeneralWindow) init() {}

// Tickers
pub fn (mut window GeneralWindow) tick_draw() {
	window.time_took_to_render.tick_average_fps()
}

pub fn (mut window GeneralWindow) tick_update() {
	window.time_took_to_update.tick_average_fps()
}

// Draw
pub fn (mut window GeneralWindow) draw_stats() {
	// Game info
	window.ctx.draw_rect_filled(0, 50, 60, 16, gx.Color{0, 0, 0, 100})
	window.ctx.draw_text(5, 50, constants.game_name, gx.TextCfg{color: gx.white})
	window.ctx.draw_rect_filled(0, 50 + 16, 145, 16, gx.Color{0, 0, 0, 100})
	window.ctx.draw_text(5, 50 + 16, constants.game_version, gx.TextCfg{color: gx.white})

	// FPS
	window.ctx.draw_rect_filled(1280 - 135, 720 - 37, 155, 16, gx.Color{0, 0, 0, 100})
	window.ctx.draw_rect_filled(1280 - 120, 720 - (37 + 16), 150, 16, gx.Color{0, 0, 0, 100})
	window.ctx.draw_text(1280 - 5, 720 - 37, "Update: ${window.time_took_to_update.get_average_fps():.0}fps [${window.time_took_to_update.average:.0}ms]", gx.TextCfg{color: gx.white, align: .right})
	window.ctx.draw_text(1280 - 5, 720 - (37 + 16), "Draw: ${window.time_took_to_render.get_average_fps():.0}fps [${window.time_took_to_render.average:.0}ms]", gx.TextCfg{color: gx.white, align: .right})
}