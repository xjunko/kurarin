module gui

import os
import gg
import core.common.settings
import core.osu.parsers.beatmap
import core.osu.runtime.gameplay
import framework.logging
import framework.graphic.context
import framework.graphic.window as i_window
import framework.math.time

[heap]
pub struct GUIWindow {
	i_window.GeneralWindow
mut:
	time &time.TimeCounter = unsafe { nil }
pub mut:
	manager  &beatmap.BeatmapManager = unsafe { nil }
	menu     &MainMenu = unsafe { nil }
	gameplay &gameplay.OSUGameplay = unsafe { nil }

	joe   bool   // Has song loaded yet
	joe_i int    // Index of beatmap
	joe_s int    // Current Scene
	joe_p string // Path of the beatmap (Temp)
}

pub fn (mut window GUIWindow) init(_ voidptr) {
	// Reset time
	window.time = time.get_time()

	// Start
	logging.info('Initialize.')

	window.manager = beatmap.make_manager('/run/media/junko/2nd/Projects/dementia/assets/osu/maps/')

	logging.info('Found beatmaps: ${window.manager.beatmaps.len} beatmaps')

	// Scenes
	logging.info('Setting up scenes.')

	window.menu = &MainMenu{
		window: window
	}

	logging.info('Done setting up scenes.')

	//
	window.start_update_thread()

	// Test
	window.menu.change_beatmap(&window.manager.beatmaps[0].versions[0])
}

pub fn (mut window GUIWindow) draw(_ voidptr) {
	window.tick_draw()

	// Draw scenes
	match window.joe_s {
		0 << 0 {
			window.ctx.begin()
			window.mutex.@lock()
			window.menu.draw(ctx: window.ctx)
			window.mutex.unlock()

			window.draw_stats()

			// Draw logs (The last 32)
			for i, log in logging.global.logs {
				window.ctx.draw_rect_filled(0, i * 16, window.ctx.text_width(log), 16,
					gg.Color{0, 0, 0, 255})
				window.ctx.draw_text(0, i * 16, log, color: gg.Color{255, 255, 255, 255})
			}

			window.ctx.end()
		}
		1 << 2 {
			// This is kinda hacky but whatever.
			// Load gameplay.
			logging.info('Loading gameplay.')

			window.gameplay = &gameplay.OSUGameplay{}

			window.gameplay.init(mut window.ctx, window.menu.current_beatmap)

			window.time.reset(offset: settings.global.gameplay.playfield.lead_in_time)

			logging.info('Gameplay loaded?')

			window.joe_s = 1 << 3
		}
		1 << 3 {
			window.gameplay.draw(mut window.ctx)
		}
		else {}
	}
}

// Updates
pub fn (mut window GUIWindow) start_update_thread() {
	logging.info('Update thread starting.')

	go fn (mut window GUIWindow) {
		logging.info('Update thread started.')

		window.time.reset()

		mut limiter := time.Limiter{1000, 0, 0}

		for {
			window.mutex.@lock()
			window.update(window.time.time)
			window.mutex.unlock()
			limiter.sync()
		}
	}(mut window)
}

pub fn (mut window GUIWindow) update(time_ms f64) {
	window.tick_update()

	match window.joe_s {
		0 << 0 {
			window.menu.update(time_ms)
		}
		1 << 3 {
			window.gameplay.update(time_ms, window.time.delta)
		}
		else {}
	}
}

// Enter
pub fn (mut window GUIWindow) play_beatmap(path string) {
	window.joe_s = 1 << 2 // Getting reading to load
	window.joe_p = path

	logging.info('Getting ready to start gameplay.')

	window.menu.current_track.pause()
	window.menu.background.fadeout_and_die(window.time.time, 200.0)

	logging.info('Killed background.')
}

pub fn main() {
	mut window := &GUIWindow{
		manager: 0
	}

	logging.info('Runtime logs:')
	logging.info('Hello world.')

	logging.info('Creating GG context.')

	mut gg_context := gg.new_context(
		// Basic
		width: 1280
		height: 720
		user_data: window
		// FNs
		init_fn: window.init
		frame_fn: window.draw
		keydown_fn: fn (key gg.KeyCode, mod gg.Modifier, mut window GUIWindow) {
			if window.joe_s == 1 << 3 || window.joe_s == 1 << 2 {
				return
			}

			// vfmt off
			if key == .right {
				window.joe_i++

				window.menu.change_beatmap(&window.manager.beatmaps[window.joe_i % window.manager.beatmaps.len].versions#[-1 ..][0])
			}

			if key == .left {
				window.joe_i--

				window.menu.change_beatmap(&window.manager.beatmaps[window.joe_i % window.manager.beatmaps.len].versions#[-1 ..][0])
			}

			// vfmt on

			if key == .p {
				window.play_beatmap(os.join_path(window.menu.current_beatmap.root, window.menu.current_beatmap.filename))
			}
		}
	)

	window.ctx = &context.Context{
		Context: gg_context
	}

	logging.info('Wrapping Context with our own impl.')
	logging.info('Get ready to run.')

	window.ctx.run()
}
