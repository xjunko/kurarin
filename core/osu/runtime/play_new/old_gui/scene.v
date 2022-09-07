module old_gui

import os
import gx
import math
import time as i_time

import framework.audio
import framework.logging
import framework.math.time
import framework.math.vector
import framework.math.easing
import framework.graphic.sprite

import core.osu.beatmap
import core.common.settings

const (
	loading_font_size = int(32)
	hard_limit_song_glob = int(50)
)

// Common
pub fn (mut window Window) draw_scene() {
	match window.task {
		.loading { window.draw_loading() }
		.menu { window.draw_menu() }
		.list { window.draw_list() }
		.loading_beatmap { window.draw_loading_beatmap() }
		.playing { window.draw_playing() }
		else {}
	}
}

pub fn (mut window Window) next_song() {
	window.beatmaps_i_c++
}

pub fn (mut window Window) previous_song() {
	window.beatmaps_i_c--
}

pub fn (mut window Window) update_current_song() bool {
	// Check if last map is the same as current.
	// Do a transition and shit if true.
	if window.beatmaps_i_l != window.beatmaps_i_c {
		// Left or Right
		// Unused direction
		// _ := math.max<f64>(0, f64(window.beatmaps_i_l - window.beatmaps_i_c))

		// REset title postiion
		window.menu_title_x = 0.0

		// Kill old shit
		// Free old background
		if !isnil(window.background) && !isnil(window.background.data) {
			C.stbi_image_free(window.background.data) // Call stbi directly
		}
		
		if window.audio != voidptr(0) {
			window.audio.pause()
		}

		// Load new shit
		window.current = window.beatmaps[math.abs<int>(window.beatmaps_i_c) % window.beatmaps.len]

		// Make new background and save the old background
		window.last_background = window.background
		window.background = window.ctx.create_image(window.current.get_bg_path())

		// Reset transforms beforehand
		window.background_s.reset_transform()
		window.last_background_s.reset_transform()

		// Transition
		window.background_s.textures[0] = window.background
		window.background_s.add_transform(typ: .fade, time: time.Time{time.global.time, time.global.time + 200}, before: [0.0], after: [255.0])
		// window.background_s.add_transform(typ: .move_x, easing: easing.quad_out, time: time.Time{time.global.time, time.global.time + 200}, before: [1280.0 * direction], after: [1280.0 / 2.0])
		window.background_s.reset_size_based_on_texture(source: vector.Vector2{settings.global.window.width, settings.global.window.height}, fit_size: true)

		window.last_background_s.textures[0] = window.last_background
		window.last_background_s.add_transform(typ: .fade, time: time.Time{time.global.time, time.global.time + 200}, before: [255.0], after: [0.0])
		// window.last_background_s.add_transform(typ: .move_x, easing: easing.quad_out, time: time.Time{time.global.time, time.global.time + 200}, before: [1280.0 * direction], after: [1280.0 / 2.0])
		window.last_background_s.reset_size_based_on_texture(source: vector.Vector2{settings.global.window.width, settings.global.window.height}, fit_size: true)
		
		// Audio
		window.audio = audio.new_track(window.current.get_audio_path())
		window.audio.set_volume(0.05)
		window.audio.set_position(window.current.general.preview_time)
		window.audio.play()
		window.visualizer.music = window.audio

		window.beatmaps_i_l = window.beatmaps_i_c

		return true
	}

	return false
}

// Scenes

/*

	LOADING

*/

pub fn (mut window Window) update_loading() {
	if window.beatmaps.len != 0 {
		return // Already loaded, not sure how to handle this yet.
	}

	// Only load beatmaps once.
	beatmaps_folder := r"/run/media/junko/2nd/Games/osu!/Songs/"
	mut beatmap_counter := int(0)

	if beatmaps := os.glob(os.join_path(beatmaps_folder, "*")) {
		// For each beatmaps
		for beatmap_p in beatmaps {
			// Load only one beatmap file per folder for now.
			if files := os.glob(os.join_path(beatmap_p, "*.osu")) {
				// Stop the loop once we reach the hard limit for beatmaps.
				if beatmap_counter >= hard_limit_song_glob {
					break
				}

				for beatmap_f in files {
					mut beatmap_s := beatmap.parse_beatmap(beatmap_f, true) // Lazy load
					window.beatmaps << beatmap_s
					beatmap_counter++
					break // now we fuck off
				}
			}
		}
	}

	logging.info("Found ${window.beatmaps.len} beatmaps!")

	// pick random map
	// window.beatmaps_i_c = rand.int_in_range(0, window.beatmaps.len - 1) or { 0 } // WHAT: this is stupid but okay

	// TODO: init beatmap browser, move this somewhre else
	window.init_list()

	// snakeoil loading time (maybe remove this)
	i_time.sleep(1000 * i_time.millisecond)

	// Goto menu
	window.task = .menu
}

pub fn (mut window Window) draw_loading() {
	window.ctx.draw_rect_filled(0, 0, f32(settings.global.window.width), f32(settings.global.window.height), gx.black)

	// Texts
	window.ctx.draw_text(int(settings.global.window.width) - 5, int(settings.global.window.height) - loading_font_size * 2, "Loading...", gx.TextCfg{color: gx.white, align: .right, size: loading_font_size})
	window.ctx.draw_text(int(settings.global.window.width) - 5, int(settings.global.window.height) - loading_font_size * 1, "Found ${window.beatmaps.len} beatmaps", gx.TextCfg{color: gx.white, align: .right, size: loading_font_size})
}

/*

	MENU

*/

pub fn (mut window Window) update_menu() {
	// Updates
	window.manager.update(time.global.time)
	window.overlay.update(time.global.time)
	window.update_current_song()

	// TODO: put this somewhere else
	window.menu_title_x = 10 * 0.25 + window.menu_title_x - window.menu_title_x * 0.25

	if window.audio != voidptr(0) {
		window.visualizer.update(time.global.time)
		window.audio.update(time.global.time)
	}

	// Click state
	if window.menu_last_state != window.menu_triggered {
		if window.menu_triggered {
			// Trigger
			window.logo_s.add_transform(typ: .move_x, easing: easing.quad_out, time: time.Time{time.global.time, time.global.time + 200}, before: [window.logo_s.position.x], after: [(settings.global.window.width / 2.0) - 200])

			for mut button in window.menu_buttons {
				button.add_transform(typ: .fade, time: time.Time{time.global.time, time.global.time + 100}, before: [0.0], after: [255.0])
			}
		} else {
			// Close
			window.logo_s.add_transform(typ: .move_x, easing: easing.quad_out, time: time.Time{time.global.time, time.global.time + 200}, before: [window.logo_s.position.x], after: [(settings.global.window.width / 2.0)])

			for mut button in window.menu_buttons {
				button.add_transform(typ: .fade, time: time.Time{time.global.time, time.global.time + 100}, before: [255.0], after: [0.0])
			}
		}

		window.menu_last_state = window.menu_triggered
	}

	// Buttons
	if window.menu_triggered {
		for mut button in window.menu_buttons {
			button.position.x = window.logo_s.position.x + window.logo_s.size.x / 2.0
		}
	}

	// Music effects
	window.logo_s.size.x = (400.0 * math.max<f64>(1.0 + (0.5 * window.audio.boost), 1.0)) * 0.1 + window.logo_s.size.x - window.logo_s.size.x * 0.1
	window.logo_s.size.y = window.logo_s.size.x

	// Background alpha music shit
	window.background_s.color.a = u8((200.0 + (128.0 * (math.max<f64>(0.5 * window.audio.boost, 0.0)))) * 0.25 + f64(window.background_s.color.a) - f64(window.background_s.color.a) * 0.25)

	// Logo Heartbeat
	if window.audio != voidptr(0) && window.audio.playing {
		delta := time.global.time - window.last_time
		window.logo_counter += delta
	}

	if window.logo_counter >= logo_hearbeat_rate {
		mut logo_ghost := &sprite.Sprite{textures: [window.logo_s.textures[0]], position: window.logo_s.position}
		logo_ghost.color.a = u8(255.0 * 0.1)
		logo_ghost.add_transform(typ: .scale_factor, easing: easing.quad_out, time: time.Time{time.global.time, time.global.time + 1000}, before: [window.logo_s.size.x / 400.0], after: [(window.logo_s.size.x / 400.0) *  1.2])
		logo_ghost.add_transform(typ: .fade, time: time.Time{time.global.time, time.global.time + 1000}, before: [255.0], after: [0.0])
		logo_ghost.reset_size_based_on_texture()
		logo_ghost.reset_time_based_on_transforms()
		logo_ghost.reset_size_based_on_texture(source: vector.Vector2{400, 400}, fit_size: true)
		window.overlay.add(mut logo_ghost)
		window.logo_counter -= logo_hearbeat_rate
	}

	// Update logo visualizer
	window.visualizer.update_logo(window.logo_s.position.sub(window.logo_s.origin.multiply(window.logo_s.size)), window.logo_s.size)
}

pub fn (mut window Window) draw_menu() {
	// Draw
	window.manager.draw(ctx: window.ctx)
	// window.ctx.draw_rect_filled(0, 0, 1280, 720, gx.Color{0, 0, 0, 10}) // Background dim
	window.visualizer.draw(mut window.ctx)
	window.overlay.draw(ctx: window.ctx)

	// Info about current beatmap
	window.ctx.draw_rect_filled(0, 0, f32(settings.global.window.width), 70, gx.Color{0, 0, 0, 170})
	window.ctx.draw_rect_filled(0, f32(settings.global.window.height) - 70, f32(settings.global.window.width), 70, gx.Color{0, 0, 0, 170})

	if window.current != voidptr(0) {
		window.ctx.draw_text(int(window.menu_title_x), 10, "${window.current.metadata.artist} - ${window.current.metadata.title}", gx.TextCfg{color: gx.white, size: 40})
	}
}

/* 

	Beatmap list

*/

pub fn (mut window Window) init_list() {
	window.list_manager = sprite.make_manager()

	// TODO: (very unoptimized) make a sprite object FOR EVERY beatmap
	list_texture := window.ctx.create_image("assets/textures/menu-button-background.png")

	for n, mut _ in window.beatmaps {
		mut sprite := &sprite.Sprite{textures: [list_texture], origin: vector.top_left, always_visible: true}
		sprite.position.x = f64(settings.global.window.width - list_texture.width - 20)
		sprite.position.y = n * list_texture.height
		sprite.color.r = u8(n * 255)
		sprite.color.g = u8(n * 100 + 30)
		sprite.color.b = u8(n * 50 + 20)

		sprite.reset_size_based_on_texture()
		sprite.reset_attributes_based_on_transforms()

		window.list_beatmap_s << sprite
		window.list_manager.add(mut sprite)
	}
}

pub fn (mut window Window) update_list() {
	window.manager.update(time.global.time)
	window.list_manager.update(time.global.time)
	window.visualizer.update(time.global.time)
	window.audio.update(time.global.time)

	// // Do some animation if list updated.
	// size := 720.0 / 14.0
	// direction := -f64(window.beatmaps_i_l - window.beatmaps_i_c)

	// if window.update_current_song() {
	// 	// println("${13-(6 + (window.beatmaps_i_c % 11))}")
	// 	println("${window.beatmaps_i_c % 16}")
	// 	// window.list_beatmap_s[(math.abs<int>(window.beatmaps_i_c-6) % 14)].add_transform(typ: .scale, time: time.Time{time.global.time, time.global.time + 200}, before: [1.0, 1.0], after: [1.5, 1.0])

	// 	for mut bm in window.list_beatmap_s {
	// 		// FIXME: unreliable
	// 		if bm.position.y > 720 && direction == 1 {
	// 			bm.add_transform(
	// 				typ: .move, 
	// 				easing: easing.quad_out, 
	// 				time: time.Time{time.global.time, time.global.time + 100}
	// 				before: [-bm.size.x, -bm.size.y],
	// 				after: [0.0, 0.0],
	// 			)
	// 		} else if bm.position.y < 0 && direction == -1 {
	// 			bm.add_transform(
	// 				typ: .move, 
	// 				easing: easing.quad_out, 
	// 				time: time.Time{time.global.time, time.global.time + 100}
	// 				before: [15 * 10.0, 15 * size], 
	// 				after: [14 * 10.0, 14 * size]
	// 			)
	// 		} else {
	// 			bm.add_transform(
	// 				typ: .move, 
	// 				easing: easing.quad_out, 
	// 				time: time.Time{time.global.time, time.global.time + 100}
	// 				before: [bm.position.x, bm.position.y],
	// 				after: [bm.position.x + (10*direction), bm.position.y + (size*direction)],
	// 			)
	// 		}
	// 	}
	// }

	// // List animation
	// window.list_offset_y = (window.beatmaps_i_c % 14) * size

	// // Smoothing
	window.list_offset_y_sm = window.list_offset_y * 0.25 + window.list_offset_y_sm - window.list_offset_y_sm * 0.25
	window.list_manager.camera.offset.y = window.list_offset_y_sm
}

pub fn (mut window Window) draw_list() {
	window.manager.draw(ctx: window.ctx)
	window.list_manager.draw_internal_camera(ctx: window.ctx)

	// Dim
	window.ctx.draw_rect_filled(0, 0, f32(settings.global.window.width), f32(settings.global.window.height), gx.Color{0, 0, 0, 50})

	// Visualizer
	window.ctx.draw_rect_filled(0, 0, 200, f32(settings.global.window.height), gx.Color{0, 0, 0, 100})
	window.visualizer.draw(mut window.ctx)

	// // List
	// size := 720.0 / 14.0
	// for i in 0 .. 14 {
	// 	mut index := math.abs<int>(window.beatmaps_i_c)

	// 	// FIXME: this is retarded (midnight code)
	// 	if i < 6 {
	// 		index = math.abs<int>(index - (6 - i))
	// 	} else if i == 6 {
	// 		index = math.abs<int>(index)
	// 	} else if i > 6 {
	// 		index = math.abs<int>(index + (i - 6))
	// 	}

	// 	mut c_bm := &window.beatmaps[index % window.beatmaps.len]

	// 	window.ctx.draw_text((i * 10) + 150, int(f64(i) * size), "${c_bm.metadata.title}", gx.TextCfg{color: gx.white, size: 30})
	// 	window.ctx.draw_text((i * 10) + 0, int(f64(i) * size), "${i}|${index}|${index%16}|${index%15}", gx.TextCfg{color: gx.white, size: 30})
	// }

	// for i, mut bm in window.list_beatmap_s {
	// 	window.ctx.draw_text(int(bm.position.x)-40, int(bm.position.y), "${i}", gx.TextCfg{color: gx.white, size: 32})
	// }
}


/*

	Beatmap loading

*/

pub fn (mut window Window) draw_loading_beatmap() {
	window.ctx.draw_text(int(settings.global.window.width) / 2, int(settings.global.window.height) / 2, "Loading...", gx.TextCfg{color: gx.white, align: .center, size: 50})
}

/*

	Playing/Gameplay

*/

pub fn (mut window Window) update_playing() {
	game_time := time.global.time - (window.start_playing_at + 3000.0)
	delta := time.global.time - window.last_time

	window.current.update(game_time, 1.0)

	// Play moosic
	if game_time >= 0 && window.audio == voidptr(0) {
		window.audio = audio.new_track(window.current.get_audio_path())
		window.audio.set_volume(0.2)
		window.audio.set_position(game_time)
		window.audio.play()
	}

	// Ruleset
	window.ruleset.update_click_for(window.players[0], game_time)
	window.ruleset.update_normal_for(window.players[0], game_time, false)
	window.ruleset.update_post_for(window.players[0], game_time, false)
	window.ruleset.update(game_time)

	// Auto
	window.auto.update(game_time)
	
	// Cursors
	for mut player in window.players {
		player.update(game_time, delta)
	} 
	
}

pub fn (mut window Window) draw_playing() {
	window.current.draw()
}
