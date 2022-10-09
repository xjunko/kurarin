module play_new

import os
// import sync
import term.ui

import framework.math.time

import beatmap
import core.osu.runtime.play_old

const (
	osu_path = "/run/media/junko/2nd/Projects/player/files/"
)

enum ProgramStatus {
	just_started
	beatmap_init
	beatmap_update
	ready
}

[heap]
pub struct Window {
	mut:
		status 		ProgramStatus = .just_started
		logs    	[]string
		beatmaps 	[]beatmap.Beatmap
		scroll      int

	pub mut:
		ctx 		&ui.Context = voidptr(0)
		// mutex 		&sync.Mutex = sync.new_mutex()
}

pub fn (mut window Window) update_thread() {
	window.logs << "Log started!"

	mut limiter := &time.Limiter{fps: 420}

	for {
		// window.mutex.@lock()

		if window.status == .beatmap_init {
			window.status = .beatmap_update
			go window.update_beatmaps()
		}

		limiter.sync()
		// window.mutex.unlock()
	}
}

pub fn (mut window Window) update_beatmaps() {
	if folders := os.glob(os.join_path(osu_path, "*")) {
		// window.beatmaps = os.dir()
		for folder in folders {
			// Check if theres any *.osu files in there
			if osu_files := os.glob(os.join_path(folder, "*.osu")) {
				for osu_file in osu_files {
					// Found something, add this to beatmap list.
					window.beatmaps << beatmap.parse_beatmap(osu_file) // TODO: Difficulty support instead of using whatever the first *.osu we get.\
					break
				}
			}
		}
	}

	// Should be enough data to run, lets go.
	window.status = .ready
}

pub fn (mut window Window) draw_menu() {
	width, height := window.ctx.window_width, window.ctx.window_height

	title := "Kurarin's Beatmap Browser | WIP 1"
	window.ctx.draw_text((width - title.len) / 2, 1, title)
	window.ctx.draw_text(0, 2, '─'.repeat(width))

	// List
	for n, beatmap in window.beatmaps {
		if n < window.scroll || n - window.scroll > height-3 { continue }

		beatmap_info_str := '[${["X", ">"][int(n == window.scroll)]}] ${n+1} | ${beatmap.artist} - ${beatmap.title}'
		window.ctx.draw_text(0, n - window.scroll + 3, beatmap_info_str)
	}

	window.ctx.draw_text(0, height - 5, "BRUH: ${window.scroll}")
	// Bar
	window.ctx.draw_text(0, height - 1, '─'.repeat(width))
}

pub fn (mut window Window) event(e &ui.Event, _ voidptr) {
	match e.typ {
		.key_down {
			// Movement
			if e.code == .up {
				window.trigger_before()
			} else if e.code == .down {
				window.trigger_next()
			} 

			// Click
			if e.code == .enter {
				play_old.main(
					window.beatmaps[window.scroll].get_full_path(),
					"",
					false
				)
				exit(1)
			}
		}

		else {}
	}
}

pub fn (mut window Window) trigger_before() {
	window.scroll--
	
	if window.scroll < 0 {
		window.scroll = window.beatmaps.len - 1
	}
}

pub fn (mut window Window) trigger_next() {
	window.scroll++
	
	if window.scroll > window.beatmaps.len - 1 {
		window.scroll = 0
	}
}

pub fn (mut window Window) frame(_ voidptr) {
	window.ctx.clear()

	// window.mutex.@lock()
	if window.status == .just_started {
		window.ctx.draw_text(1, 1, 'Starting')

		window.logs << "Program started succesfully."
		
		go window.update_thread()
		window.status = .beatmap_init

	} else if window.status == .beatmap_init || window.status == .beatmap_update {
		window.ctx.draw_text(1, 1, 'Loading beatmaps..')
		window.ctx.draw_text(1, 2, 'Found: ${window.beatmaps.len}')
		window.ctx.draw_text(1, 3, 'Recent: ${window.beatmaps[.. 1]}')
	} else if window.status == .ready {
		window.draw_menu()
	}
	// window.mutex.unlock()

	window.ctx.reset_bg_color()
	window.ctx.flush()
}

pub fn main() {
	mut window := &Window{}

	window.ctx = ui.init(
		user_data: window,

		// FNs
		event_fn: window.event,
		frame_fn: window.frame
	)

	window.ctx.run() or { panic("Failed to run TUI") }
}