module main

import os
import library.gg
import gx
import math
import sokol.gfx
import sokol.sgl
import time as timelib

import game.skin
import game.cursor
import game.beatmap
import game.settings
import game.beatmap.object.graphic

import framework.audio
import framework.math.time

pub struct Window {
	pub mut:
		ctx 		&gg.Context = voidptr(0)
		beatmap 	&beatmap.Beatmap = voidptr(0)
		cursor  	&cursor.Cursor = voidptr(0)
		proc    	&os.Process = voidptr(0)
		record 		bool
		record_data &byte = voidptr(0)
}

pub fn window_init(mut window &Window) {
	// mut beatmap := beatmap.parse_beatmap(r"/run/media/junko/2nd/Games/osu!/Songs/546820 YUC'e - Future Candy/YUC'e - Future Candy (Nathan) [Sugar Rush].osu")
	// mut beatmap := beatmap.parse_beatmap(r"/run/media/junko/2nd/Games/osu!/Songs/27107 IOSYS - The Lovely, Freezing, Tomboyish Bath, Cirno's Hot Spring/IOSYS - The Lovely, Freezing, Tomboyish Bath, Cirno's Hot Spring (Mafiamaster) [Hot Spring].osu")
	// mut beatmap := beatmap.parse_beatmap(r"/run/media/junko/2nd/Games/osu!/Songs/483606 NOMA - LOUDER MACHINE/NOMA - LOUDER MACHINE (Skystar) [Axarious' EX EX].osu")
	mut beatmap := beatmap.parse_beatmap(r"/run/media/junko/2nd/Games/osu!/Songs/179323 Sakamoto Maaya - Okaerinasai (tomatomerde Remix)/Sakamoto Maaya - Okaerinasai (tomatomerde Remix) (Azer) [Collab].osu")
	// mut beatmap := beatmap.parse_beatmap(r"/run/media/junko/2nd/Games/osu!/Songs/470977 Mili - worldexecute(me);/Mili - world.execute(me); (Exile-) [mapset.insane(Exile-);].osu")
	
	

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

	// If recording
	if window.record {
		window.init_pipe_process()

		// Time shit
		mut g_time := time.get_time()
		g_time.set_speed(settings.window.speed)
		g_time.use_custom_delta = true
		g_time.custom_delta = frametime
	}


	// Update loop
	if !window.record {
		go fn (mut window &Window) {
			mut g_time := time.get_time()
			g_time.set_speed(settings.window.speed)
			mut played := false
			time.reset()

			// g_time.time = 50000.0
			
			for {
				if g_time.time >= settings.gameplay.lead_in_time && !played {
					audio.play(path: window.beatmap.get_audio_path(), speed: settings.window.speed)
					played = true
				}

				window.cursor.update(g_time.time - settings.gameplay.lead_in_time)
				window.beatmap.update(g_time.time - settings.gameplay.lead_in_time)
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
	if !settings.gameplay.disable_cursor {
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

	// Pipe the window stuff 
	if window.record {
		// Update stuff
		mut g_time := time.get_time()
		window.cursor.update(g_time.time - settings.gameplay.lead_in_time)
		window.beatmap.update(g_time.time - settings.gameplay.lead_in_time)

		// TODO: separate video and update rate
		// This way the update rate can be stupidly high
		// so it doesnt skips transform on low fps
		window.pipe_window() 

		g_time.tick()
	}
}

[console]
fn main() {
	mut window := &Window{}
	window.ctx = gg.new_context(
		width: 1280,
		height: 720,
		user_data: window,
		bg_color: gx.black,

		// FNs
		init_fn: window_init,
		frame_fn: window_draw
	)

	// Record or na
	window.record = settings.window.record

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