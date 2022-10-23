module diva

import time
import sync

import library.gg

import framework.audio
import framework.math.time
import framework.graphic.window
import framework.graphic.sprite

import core.diva.beatmap
import core.diva.skin

// Hacks
fn C._sapp_glx_swapinterval(int)

[heap]
pub struct Window {
	window.GeneralWindow

	mut:
		draw_limiter &time.Limiter = &time.Limiter{fps: 60}
		thread_limiter &time.Limiter = &time.Limiter{fps: 480}

	pub mut:
		mutex   &sync.Mutex = sync.new_mutex()
		beatmap &beatmap.Beatmap = voidptr(0)
}

pub fn (mut window Window) init(_ voidptr) {
	// Disable vsync
	C._sapp_glx_swapinterval(0)

	window.beatmap = beatmap.read_beatmap("./assets/scores/055/pv_055_extreme.dsc")
	window.beatmap.reset(mut sprite.CommonSpriteArgument{ctx: mut window.ctx})

	go window.update(0)
}

pub fn (mut window Window) update(_ voidptr) {
	mut g_time := time.get_time()
	g_time.reset()

	mut audio := audio.new_track("./assets/scores/055/kokoro.mp3")

	play_at := 1000.0

	for {
		window.mutex.@lock()

		window.GeneralWindow.tick_update()

		if !audio.playing && g_time.time >= play_at {
			audio.play()
		}

		window.beatmap.update(g_time.time - play_at - 1700.0)

		window.mutex.unlock()
		window.thread_limiter.sync()
	}
}

pub fn (mut window Window) draw(_ voidptr) {
	window.mutex.@lock()

	// Draw FPS counter
	window.GeneralWindow.tick_draw()

	window.ctx.begin()

	window.beatmap.draw(ctx: window.ctx, time: time.global.time - 1000.0 - 1700.0)

	// Text
	window.GeneralWindow.draw_stats()

	window.ctx.end()

	window.mutex.unlock()

	window.draw_limiter.sync()
}

pub fn main() {
	mut window := &Window{}
	window.ctx = gg.new_context(
		width: 1280,
		height: 720,
		user_data: window,

		// FNs
		init_fn: window.init,
		frame_fn: window.draw
	)

	skin.bind_context(mut window.ctx)
	window.ctx.run()
}
