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
import math

// Impl
fn C._sapp_glx_swapinterval(int)

// Const
const (
	c_scene_none             = 0 << 0
	c_scene_main             = 1 << 0
	c_scene_pre_gameplay     = 1 << 1
	c_scene_loading_gameplay = 1 << 2
	c_scene_gameplay         = 1 << 3
)

// Structs
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
	joe_c int    // Useless counter for uselss thing
}

pub fn (mut window GUIWindow) init(_ voidptr) {
	window.joe_s = gui.c_scene_main

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
	window.menu.change_beatmap(&window.manager.beatmaps[0])
}

pub fn (mut window GUIWindow) draw(_ voidptr) {
	window.tick_draw()

	// Draw scenes
	match window.joe_s {
		gui.c_scene_main {
			window.ctx.begin()
			window.mutex.@lock()
			window.menu.draw(ctx: window.ctx)
			window.mutex.unlock()

			window.draw_stats()

			// Draw the last 32 logs
			mut t := 1
			for i := logging.global.logs.len - 1; i > math.max(logging.global.logs.len - 32,
				0); i-- {
				t++
				window.ctx.draw_rect_filled(0, 720 - t * 16, window.ctx.text_width(logging.global.logs[i]),
					16, gg.Color{0, 0, 0, 100})
				window.ctx.draw_text(0, 720 - t * 16, logging.global.logs[i],
					color: gg.Color{255, 255, 255, 100}
				)
			}

			window.ctx.end()
		}
		gui.c_scene_pre_gameplay {
			// Black screen with loading
			window.ctx.begin()

			window.mutex.@lock()
			window.menu.draw(ctx: window.ctx)
			window.mutex.unlock()

			window.ctx.draw_rect_filled(0, 0, 1280, 720, gg.Color{0, 0, 0, 200})

			window.ctx.draw_text(1280 / 2, 720 / 2, 'Loading...',
				color: gg.Color{255, 255, 255, 255}
				size: 64
				align: .center
				vertical_align: .middle
			)

			window.ctx.end()

			// 10 frames to sokol can draw stuff properly
			window.joe_c++

			if window.joe_c > 10 {
				window.joe_s = gui.c_scene_loading_gameplay
			}
		}
		gui.c_scene_loading_gameplay {
			// This is kinda hacky but whatever.
			// Load gameplay.
			logging.info('Loading gameplay.')

			window.gameplay = &gameplay.OSUGameplay{}

			window.gameplay.init(mut window.ctx, window.menu.current_version)

			window.time.reset()
			C._sapp_glx_swapinterval(0) // Disable VSync when changing to gameplay.

			logging.info('Gameplay loaded?')

			window.joe_s = gui.c_scene_gameplay
		}
		gui.c_scene_gameplay {
			window.mutex.@lock()
			window.gameplay.draw(mut window.ctx)
			window.mutex.unlock()

			window.ctx.begin()
			window.ctx.begin_gp()
			window.draw_stats()

			// Draw the last 16 logs
			mut t := 1
			for i := logging.global.logs.len - 1; i > math.max(logging.global.logs.len - 16,
				0); i-- {
				t++
				window.ctx.draw_rect_filled(0, t * 16, window.ctx.text_width(logging.global.logs[i]),
					16, gg.Color{0, 0, 0, 200})
				window.ctx.draw_text(0, t * 16, logging.global.logs[i],
					color: gg.Color{255, 255, 255, 100}
				)
			}
			window.ctx.end_gp_short()
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
		gui.c_scene_main {
			window.menu.update(time_ms)
		}
		gui.c_scene_gameplay {
			window.gameplay.update(time_ms, window.time.delta)
		}
		else {}
	}
}

// Enter
pub fn (mut window GUIWindow) play_beatmap(path string) {
	window.joe_s = gui.c_scene_pre_gameplay // Getting reading to load
	window.joe_p = path

	logging.info('Getting ready to start gameplay.')

	window.menu.current_track.pause()
	window.menu.background.fadeout_and_die(window.time.time, 200.0)

	logging.info('Killed background.')
}

// Events
pub fn (mut window GUIWindow) event_keydown(key gg.KeyCode, mod gg.Modifier, _ voidptr) {
	if window.joe_s == gui.c_scene_pre_gameplay || window.joe_s == gui.c_scene_loading_gameplay {
		return
	}

	if window.joe_s == gui.c_scene_gameplay {
		window.gameplay.event_keydown(key)
		return
	}

	match key {
		.right {
			window.joe_i++

			window.menu.change_beatmap(&window.manager.beatmaps[window.joe_i % window.manager.beatmaps.len])
		}
		.left {
			window.joe_i--

			if window.joe_i < 0 {
				window.joe_i = window.manager.beatmaps.len - 1
			}

			window.menu.change_beatmap(&window.manager.beatmaps[window.joe_i % window.manager.beatmaps.len])
		}
		.up {
			window.menu.prev_version()
		}
		.down {
			window.menu.next_version()
		}
		.p {
			window.play_beatmap(os.join_path(window.menu.current_version.root, window.menu.current_version.filename))
		}
		else {
			logging.debug('Unhandled key: ${key}')
		}
	}
}

pub fn (mut window GUIWindow) event_keyup(key gg.KeyCode, mod gg.Modifier, _ voidptr) {
	match window.joe_s {
		gui.c_scene_gameplay {
			window.gameplay.event_keyup(key)
		}
		else {}
	}
}

pub fn (mut window GUIWindow) event_mouse(x f32, y f32, _ voidptr) {
	if window.joe_s != gui.c_scene_gameplay {
		return
	}

	window.gameplay.event_mouse(x, y)
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
		// Event
		keydown_fn: window.event_keydown
		keyup_fn: window.event_keyup
		move_fn: window.event_mouse
	)

	window.ctx = &context.Context{
		Context: gg_context
	}

	logging.info('Wrapping Context with our own impl.')
	logging.info('Get ready to run.')

	window.ctx.run()
}
