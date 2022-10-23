module sekai

import sync
import library.gg

import core.sekai.skin
import core.sekai.beatmap
import core.common.settings

import framework.audio
import framework.logging
import framework.math.time

import framework.graphic.window

// Hacks to disable vsync
fn C._sapp_glx_swapinterval(int)

[heap]
pub struct Window {
	window.GeneralWindow

	mut:
		mutex &sync.Mutex = sync.new_mutex()
		beatmap &beatmap.Beatmap = voidptr(0)
		limiter &time.Limiter = &time.Limiter{fps: 480}
}

pub fn (mut window Window) init(_ voidptr) {
	// Disable vsync
	C._sapp_glx_swapinterval(0)

	// Load beatmap
	window.beatmap = beatmap.parse_beatmap("assets/psekai/maps/64/master.sus")
	window.beatmap.bind_context(mut window.ctx)
	window.beatmap.reset()

	// Update thread
	go fn (mut window Window) {
		mut limiter := &time.Limiter{fps: 480}
		mut g_time := time.get_time()
		g_time.reset()

		start_at_offset := 2000.0
		music_offset := 0.0
		mut song_started := false
		mut song := audio.new_track("assets/psekai/maps/64/audio.mp3")

		song.set_volume(0.3)
		song.set_position(music_offset)

		for {
			window.mutex.@lock()

			// Start the song if greater than offset
			if (g_time.time - start_at_offset) >= 0.0 && !song_started {
				song.play()
				song_started = true
			}

			// Update FPS counter
			window.GeneralWindow.tick_update()
		
			window.beatmap.update(g_time.time - start_at_offset)
			window.mutex.unlock()
			limiter.sync()
		}

	}(mut window)
}

pub fn (mut window Window) draw(_ voidptr) {
	window.mutex.@lock()

	// Draw FPS counter
	window.GeneralWindow.tick_draw()

	window.ctx.begin()

	window.beatmap.draw(ctx: window.ctx, time: time.global.time)

	// Textx
	window.GeneralWindow.draw_stats()

	window.ctx.end()

	window.mutex.unlock()

	window.limiter.sync()
}

pub fn main() {
	logging.warn("${@MOD}: PjSekai is mega WIP, expect the unexpected.")

	mut window := &Window{}
	window.ctx = gg.new_context(
		width: int(settings.global.window.width), 
		height: int(settings.global.window.height),
		user_data: window,

		// FNs
		init_fn: window.init,
		frame_fn: window.draw
	)

	// Bind skin context
	skin.bind_context(mut window.ctx)

	window.ctx.run()
}