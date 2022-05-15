module main

import game.settings // Load this first

import os
import gx
import flag
import math
import sync
import sokol.gfx
import sokol.sgl
import sokol.sapp
import time as timelib
import library.gg

import game.x
import game.skin
import game.cursor
import game.beatmap
import game.ruleset
import game.overlays
import game.beatmap.object.graphic

import framework.audio
import framework.logging
import framework.math.time

const (
	game_name = "Kurarin"
	game_version = "rewrite-0.0.2a-preview1"
)

// TODO: lol
pub struct GameArgument {
	pub mut:
		beatmap_path string
		playing      bool
}

pub struct Window {
	pub mut:
		ctx 		&gg.Context = voidptr(0)
		beatmap 	&beatmap.Beatmap = voidptr(0)
		cursors     []&cursor.Cursor
		auto        &cursor.AutoCursor = voidptr(0)
		argument    &GameArgument = voidptr(0)

		// TODO: move this to somewhere else
		audio_been_played bool
		limiter           &time.Limiter = &time.Limiter{int(settings.global.window.fps), 0, 0}
		draw_counter      &time.TimeCounter = &time.TimeCounter{}

		// Ruleset
		ruleset &ruleset.Ruleset = voidptr(0)
		ruleset_mutex &sync.Mutex = sync.new_mutex()

		// Overlay
		overlay &overlays.GameplayOverlay = voidptr(0)

		// Recording stuff
		record 		bool
		video_proc  &os.Process = voidptr(0)
		record_data &u8 = voidptr(0)
		audio_proc  &os.Process = voidptr(0)
		audio_data  []u8

		// HACK: move this to somewhere else
		beatmap_song &audio.Track = voidptr(0)
		beatmap_song_boost f32 = f32(1.0)
}

pub fn (mut window Window) update_boost() {
	if settings.global.gameplay.hitobjects.scale_to_beat {
		target := math.clamp(1.0 + (0.5 * window.beatmap_song.boost), 1.0, 2.0) // 2.0 is the max
		window.beatmap_song_boost = f32(target * 0.1 + window.beatmap_song_boost - window.beatmap_song_boost * 0.1)

		// rate := 0.15 * (time.global.delta / 8.33334) // 120fps
		// window.beatmap_song_boost = f32(target * rate + window.beatmap_song_boost - window.beatmap_song_boost * rate)
	}
}

pub fn (mut window Window) update_cursor(time f64) {
	if !window.argument.playing {
		window.auto.update(time)
	}

	for mut cursor in window.cursors {
		cursor.update(time)
	}

	// Rainbow mode if theres only one cursor
	if window.cursors.len == 1 {
		color_index := (f32(math.fmod(time / 100.0, 10000)) / 10000.0) + 0.1
		window.cursors[0].trail_color.r = u8(f32(math.sin(0.3*(time / 1000.0) + 0 + 1 * color_index) * 127.0 + 128.0))
		window.cursors[0].trail_color.g = u8(f32(math.sin(0.3*(time / 1000.0) + 2 + 1 * color_index) * 127.0 + 128.0))
		window.cursors[0].trail_color.b = u8(f32(math.sin(0.3*(time / 1000.0) + 4 + 1 * color_index) * 127.0 + 128.0))
	}
}

pub fn (mut window Window) update(time f64) {
	if time >= settings.global.gameplay.playfield.lead_in_time && !window.audio_been_played {
		window.audio_been_played = true
		window.beatmap_song.set_speed(settings.global.window.speed)
		window.beatmap_song.set_pitch(settings.global.audio.pitch)
		window.beatmap_song.set_volume(f32((settings.global.audio.music / 100.0) * (settings.global.audio.global / 100.0)))
		window.beatmap_song.play()
	}

	// Overlay
	window.overlay.update(time - settings.global.gameplay.playfield.lead_in_time)

	// Ruleset
	window.ruleset_mutex.@lock()
	window.ruleset.update_click_for(window.cursors[0], time - settings.global.gameplay.playfield.lead_in_time)
	window.ruleset.update_normal_for(window.cursors[0], time - settings.global.gameplay.playfield.lead_in_time, false)
	window.ruleset.update_post_for(window.cursors[0], time - settings.global.gameplay.playfield.lead_in_time, false)
	window.ruleset.update(time - settings.global.gameplay.playfield.lead_in_time)
	window.ruleset_mutex.unlock()

	window.beatmap.update(time - settings.global.gameplay.playfield.lead_in_time, window.beatmap_song_boost)
	window.beatmap_song.update(time - settings.global.gameplay.playfield.lead_in_time)
	window.update_cursor(time - settings.global.gameplay.playfield.lead_in_time)
	window.update_boost()
}

pub fn (mut window Window) draw() {
	// Background
	window.ctx.begin()
	window.ctx.end()

	// Game
	window.beatmap.draw()
	window.overlay.draw()
	
	// TODO: maybe move cursor to beatmap struct
	if settings.global.gameplay.cursor.visible {
		for mut cursor in window.cursors {
			cursor.draw()
		}
	}

	window.ctx.begin()

	// Texts (only on windowed mode)
	if !settings.global.video.record {
		// Game info
		window.ctx.draw_rect_filled(0, 50, 60, 16, gx.Color{0, 0, 0, 100})
		window.ctx.draw_text(5, 50, game_name, gx.TextCfg{color: gx.white})
		window.ctx.draw_rect_filled(0, 50 + 16, 145, 16, gx.Color{0, 0, 0, 100})
		window.ctx.draw_text(5, 50 + 16, game_version, gx.TextCfg{color: gx.white})

		// FPS info
		window.ctx.draw_rect_filled(1145, 683, 155, 16, gx.Color{0, 0, 0, 100})
		window.ctx.draw_text(1275, 683, "Update: ${time.global.get_average_fps():.0}fps [${time.global.average:.0}ms]", gx.TextCfg{color: gx.white, align: .right})
		window.ctx.draw_rect_filled(1160, 683 + 16, 150, 16, gx.Color{0, 0, 0, 100})
		window.ctx.draw_text(1275, 683+16, "Draw: ${window.draw_counter.get_average_fps():.0}fps [${window.draw_counter.average:.0}ms]", gx.TextCfg{color: gx.white, align: .right})
	}

	gfx.begin_default_pass(graphic.global_renderer.pass_action, 1280, 720)
	sgl.draw()
	gfx.end_pass()

	gfx.commit()
}

pub fn window_init(mut window &Window) {
	mut beatmap := beatmap.parse_beatmap(window.argument.beatmap_path)

	// init slider renderer
	graphic.init_slider_renderer()

	// 
	window.beatmap = beatmap
	window.beatmap.bind_context(mut window.ctx)
	window.beatmap.reset()

	// Init beatmap bg song
	window.beatmap_song = audio.new_track(window.beatmap.get_audio_path())

	// Make cursor based on argument
	if window.argument.playing {
		window.cursors << cursor.make_cursor(mut window.ctx)
	} else {
		window.auto = cursor.make_auto_cursor(mut window.ctx, window.beatmap.objects)
		window.cursors << unsafe{ window.auto.cursor }
	}

	// Make ruleset
	window.ruleset = ruleset.new_ruleset(mut window.beatmap, mut window.cursors)

	// Overlay
	window.overlay = overlays.new_gameplay_overlay(window.ruleset, window.cursors[0], window.ctx)

	// If recording
	if window.record {
		window.init_video_pipe_process()
		window.init_audio_pipe_process()

		// Time shit
		mut g_time := time.get_time()
		g_time.set_speed(settings.global.window.speed)
		g_time.use_custom_delta = true
		g_time.custom_delta = frametime
	}


	// Update loop
	if !window.record {
		go fn (mut window &Window) {
			mut g_time := time.get_time()
			mut limiter := time.Limiter{480, 0, 0}
			g_time.reset()
			g_time.set_speed(settings.global.window.speed)
			window.draw_counter.reset()

			// Disable mouse
			sapp.show_mouse(false)
			
			for {
				window.update(g_time.time)
				g_time.tick_average_fps()
				limiter.sync()
			}
		}(mut window)
	}
}

pub fn window_draw(mut window &Window) {
	window.draw()
	window.draw_counter.tick_average_fps()
	window.limiter.sync()
}

pub fn window_draw_recording(mut window &Window) {
	window_size := gg.window_size()

	if window_size.width != 1280 || window_size.height != 720 {
		window.ctx.begin()
		window.ctx.resize(1280, 720)
		window.ctx.draw_text(0, 0, "Please make sure the window resolution is [1280, 720].", gx.TextCfg{color: gx.white})
		window.ctx.end()
		return
	}

	logging.info("Video rendering started!")

	// Continue rendering
	mut last_progress := int(0)
	mut last_count := i64(0)
	mut count := i64(0)
	mut last_time := timelib.ticks()

	// shrug
	update_delta := 1000.0 / 1000.0
	game_update_delta := 1000.0 / settings.global.video.update_fps // Render Update FPS
	fps_delta := 1000.0 / settings.global.video.fps

	mut delta_sum_video := fps_delta
	mut delta_sum_update := 0.0

	mut video_time := 0.0

	end_time := (window.beatmap.time.end + 3000.0) * settings.global.window.speed
	for video_time < end_time {
		// Update and Audio
		delta_sum_update += update_delta
		if delta_sum_update >= game_update_delta {
			video_time += game_update_delta * settings.global.window.speed
			// Update
			window.update(video_time)

			// Submit audio
			window.pipe_audio()
			delta_sum_update -= game_update_delta
		}

		// Video
		delta_sum_video += update_delta
		if delta_sum_video >= fps_delta {
			// Draw
			window.draw()

			// Pipe 
			window.pipe_window() 

			// Print progress
			count++
			progress := int((video_time / end_time) * 100.0)

			if math.fmod(progress, 5) == 0 && progress != last_progress {
				speed := f64(count - last_count) * (1000 / settings.global.video.fps) / (timelib.ticks() - last_time) 
				eta := int((end_time - video_time) / 1000.0 / speed)

				mut eta_text := ""

				hours := eta / 3600
				minutes := eta / 60

				if hours > 0 {
					eta_text += "${hours}h "
				}

				if minutes > 0 {
					eta_text += "${minutes%60:02d}m"
				}

				logging.info("Progress: ${progress}% | Speed: ${speed:.2f}x | ETA: ${eta_text}")

				last_time = timelib.ticks()
				last_count = count
				last_progress = progress
			}
			delta_sum_video -= fps_delta
		}
	}
	window.ctx.quit() // Ok we're done...
}

pub fn initiate_game_loop(argument GameArgument) {
	mut window := &Window{}
	window.argument = &argument

	window.ctx = gg.new_context(
		width: 1280,
		height: 720,
		user_data: window,
		bg_color: gx.black,

		// FNs
		init_fn: window_init,
		frame_fn: [window_draw, window_draw_recording][int(settings.global.video.record)] // yea...

		// Just a test, remove `cursor.make_replay` on line 54 to get this working
		move_fn: fn (x_ f32, y_ f32, mut window &Window) {
			if !window.argument.playing {
				return
			}

			window.cursors[0].position.x = (x_ - x.resolution.offset.x) / x.resolution.playfield_scale
			window.cursors[0].position.y = (y_ - x.resolution.offset.y) / x.resolution.playfield_scale
			
		}

		keydown_fn: fn (keycode gg.KeyCode, modifier gg.Modifier, mut window &Window) {
			if !window.argument.playing {
				return
			}

			window.ruleset_mutex.@lock()
			if keycode == .z {
				window.cursors[0].left_button = true
			}

			if keycode == .x {
				window.cursors[0].right_button = true
			}
			window.ruleset_mutex.unlock()
		}
		keyup_fn: fn (keycode gg.KeyCode, modifier gg.Modifier, mut window &Window) {
			if !window.argument.playing {
				return
			}
			
			window.ruleset_mutex.@lock()
			if keycode == .z {
				window.cursors[0].left_button = false
			}

			if keycode == .x {
				window.cursors[0].right_button = false
			}

			window.ruleset_mutex.unlock()
		}
	)

	// Record or na
	window.record = settings.global.video.record

	// Don't record if we're playing the game, only record for auto (and replays soon).
	if window.record && argument.playing {
		logging.error("Recording is unavailable rn due to gameplay refactor, try again later.")
		exit(1)
	}

	skin.bind_context(mut window.ctx)

	if window.record {
		time.stop()
		time.reset()
	}

	window.ctx.run()

	if window.record {
		window.close_pipe_process()
	}
}

[console]
fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application(game_name)
	fp.version(game_version)
	fp.description("Everything WIP, be careful when running ;).")

	beatmap_path := fp.string("beatmap", `b`, "", "Path to the .osu file.")
	is_playing := fp.bool("play", `p`, false, "Flag for playing in the client.")

	fp.finalize() or {
		println(fp.usage())
		return
	}

	// TODO: im pretty sure theres a required tags for the fp.string method
	if beatmap_path.len == 0 {
		println(fp.usage())
		return
	}

	// Checks
	if !os.exists(beatmap_path) {
		logging.error("Invalid beatmap path: ${beatmap_path}")
		return
	}

	// Create GameArgument
	argument := &GameArgument{
		beatmap_path: beatmap_path,
		playing: is_playing
	}

	logging.info("Beatmap: ${beatmap_path}")

	initiate_game_loop(argument)
}