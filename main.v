module main

import game.settings // Load this first

import os
import gx
import flag
import math
import sokol.gfx
import sokol.sgl
import library.gg
import time as timelib

import game.skin
import game.cursor
import game.beatmap
import game.beatmap.object.graphic

import framework.audio
import framework.logging
import framework.math.time

// TODO: lol
pub struct GameArgument {
	pub mut:
		beatmap_path string
}

pub struct Window {
	pub mut:
		ctx 		&gg.Context = voidptr(0)
		beatmap 	&beatmap.Beatmap = voidptr(0)
		cursor  	&cursor.Cursor = voidptr(0)
		argument    &GameArgument = voidptr(0)


		// Recording stuff
		record 		bool
		video_proc  &os.Process = voidptr(0)
		record_data &byte = voidptr(0)
		audio_proc  &os.Process = voidptr(0)
		audio_data  []byte

		// HACK: move this to somewhere else
		beatmap_song &audio.Track = voidptr(0)
		beatmap_song_boost f32 = f32(1.0)
}

pub fn (mut window Window) update_boost() {
	if settings.global.miscellaneous.scale_to_beat {
		target := math.clamp(1.0 + (0.5 * window.beatmap_song.boost), 1.0, 2.0) // 2.0 is the max
		window.beatmap_song_boost = f32(target * 0.1 + window.beatmap_song_boost - window.beatmap_song_boost * 0.1)

		// rate := 0.15 * (time.global.delta / 8.33334) // 120fps
		// window.beatmap_song_boost = f32(target * rate + window.beatmap_song_boost - window.beatmap_song_boost * rate)
	}
}

pub fn window_init(mut window &Window) {
	mut beatmap := beatmap.parse_beatmap(window.argument.beatmap_path)

	// init slider renderer
	graphic.init_slider_renderer()

	// 
	window.beatmap = beatmap
	window.beatmap.bind_context(mut window.ctx)
	window.beatmap.reset()

	// Make cursor
	window.cursor = cursor.make_cursor(mut window.ctx)
	window.cursor.bind_beatmap(mut window.beatmap)
	cursor.make_replay(mut window.beatmap, mut window.cursor)

	// Init beatmap bg song
	window.beatmap_song = audio.new_track(window.beatmap.get_audio_path())

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
			g_time.set_speed(settings.global.window.speed)
			mut played := false
			time.reset()
			
			for {
				if g_time.time >= settings.global.gameplay.lead_in_time && !played {
					window.beatmap_song.set_speed(settings.global.window.speed)
					window.beatmap_song.set_volume(f32((settings.global.window.audio_volume / 100.0) * (settings.global.window.overall_volume / 100.0)))
					window.beatmap_song.play()
					played = true
				}

				window.cursor.update(g_time.time - settings.global.gameplay.lead_in_time)
				window.beatmap.update(g_time.time - settings.global.gameplay.lead_in_time, window.beatmap_song_boost)
				window.beatmap_song.update(g_time.time) // doesnt care about time
				window.update_boost()
				
				timelib.sleep(time.update_rate_ms)
			}
		}(mut window)
	}
}

pub fn window_draw(mut window &Window) {
	// Background
	window.ctx.begin()
	window.ctx.end()

	// Game
	window.beatmap.draw()
	
	// TODO: maybe move cursor to beatmap struct
	if !settings.global.gameplay.disable_cursor {
		window.cursor.draw()
	}

	// Texts
	window.ctx.begin()
	window.ctx.draw_text(0, 0, "Time: ${time.global.time:.0} [${time.global.delta:.0}ms, ${time.global.fps:.0}fps]", gx.TextCfg{color: gx.white})
	window.ctx.draw_text(0, 16, "Recording: ${window.record}", gx.TextCfg{color: gx.white})

	gfx.begin_default_pass(graphic.global_renderer.pass, 1280, 720)
	sgl.draw()
	gfx.end_pass()
	gfx.commit()

	// We're recording.
	if window.record {
		mut g_time := time.get_time()

		// Start the music after the intro
		if g_time.time >= settings.global.gameplay.lead_in_time && !window.beatmap_song.playing {
			window.beatmap_song.set_speed(settings.global.window.speed)
			window.beatmap_song.set_volume(f32((settings.global.window.audio_volume / 100.0) * (settings.global.window.overall_volume / 100.0)))
			window.beatmap_song.play()
		}

		// Update cursor and beatmap
		window.cursor.update(g_time.time - settings.global.gameplay.lead_in_time)
		window.beatmap.update(g_time.time - settings.global.gameplay.lead_in_time, window.beatmap_song_boost)
		
		// Update audio boost
		window.beatmap_song.update(0.0) 
		window.update_boost()

		// Pipe 
		window.pipe_window() 
		window.pipe_audio()

		g_time.tick() // Tick 16.6667ms then wait for gg to call this function again.
	}
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
		frame_fn: window_draw

		// Just a test, remove `cursor.make_replay` on line 54 to get this working
		// move_fn: fn (x_ f32, y_ f32, mut window &Window) {
		// 	window.cursor.position.x = (x_ - x.resolution.offset.x) / x.resolution.playfield_scale
		// 	window.cursor.position.y = (y_ - x.resolution.offset.y) / x.resolution.playfield_scale
		// }
	)

	// Record or na
	window.record = settings.global.window.record

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
	fp.application("Kurarin")
	fp.version("0.2.2-dementia")
	fp.description("Kurarin rewrite Codename Dementia")

	beatmap_path := fp.string("beatmap", `b`, "", "Path to the .osu file")

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
		beatmap_path: beatmap_path
	}

	logging.info("Beatmap: ${beatmap_path}")

	initiate_game_loop(argument)
}