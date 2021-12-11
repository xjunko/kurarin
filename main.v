import os
import gx
import flag
import lib.gg
import sokol.sgl
import sokol.gfx

import game.window
import game.math.resolution
import game.animation

import framework.audio

import tests

pub struct MainWindow {
	pub mut:
		ctx &gg.Context = voidptr(0)
		game &window.GameWindow = voidptr(0)
		mode int
		pass C.sg_pass_action
		pass_dc C.sg_pass_action

		// temp stuff
		game_speed f64 = 1.0
		test_stage int
		stage_name string
		is_running_test bool
}

pub fn (mut main_window MainWindow) run_tests() {
	if main_window.is_running_test {
		return
	}

	main_window.is_running_test = true
	main_window.stage_name = match main_window.test_stage {
		0 { 'Hitsound test' }
		else { 'None' }
	}

	// do the test
	println('Currently testing: ${main_window.stage_name}')
	match main_window.test_stage {
		0 { tests.stress_test_audio() main_window.test_stage++}
		1 { println('Done testing!') exit(1)}
		else {}
	}	
}

pub fn frame_init(mut main_window &MainWindow) {
	animation.ready_cache()

	// sapp.show_mouse(false)

	if main_window.mode == 0 {
		main_window.game.load_beatmap()
		main_window.game.game_speed = main_window.game_speed
		main_window.game.start_game_loop(writer: 0)
	}

	// Pass
	main_window.pass.colors[0] = C.sg_color_attachment_action{
		action: .clear,
		value: C.sg_color{0.0, 0.0, 0.0, 1.0}
	}
	main_window.pass_dc.colors[0] = C.sg_color_attachment_action{
		action: .load,
		value: C.sg_color{0.0, 0.0, 0.0, 1.0}
	}
}

pub fn frame_update(mut main_window &MainWindow) {
	if main_window.mode == 1 {
		if !main_window.is_running_test {
			go main_window.run_tests()
		}
		main_window.ctx.begin()
		main_window.ctx.draw_text(0, 0, "Kurarin test mode (v 0.0.2)", gx.TextCfg{color: gx.white})
		main_window.ctx.draw_text(0, 16, "Running: ${main_window.stage_name}", gx.TextCfg{color: gx.white})
		main_window.ctx.end()
		return
	}

	if !main_window.game.is_ready {
		main_window.ctx.begin()
		main_window.ctx.draw_text(0, 0, "Loading!", gx.TextCfg{color: gx.white})
		main_window.ctx.end()
		return
	}

	// Start
	main_window.ctx.ft.flush()
	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0.0, 1280, 720, 0.0, -1.0, 1.0)

	// Background
	gfx.begin_default_pass(main_window.pass, 1280, 720)
	main_window.game.draw_back_layer()
	sgl.draw()
	gfx.end_pass()
	gfx.commit()

	// Front
	gfx.begin_default_pass(main_window.pass_dc, 1280, 720)
	main_window.game.draw()
	main_window.game.draw_special()
	sgl.draw()
	gfx.end_pass()
	gfx.commit()
}

/*
pub fn frame_mouse_move(x f32, y f32, mut main_window &MainWindow) {
	if true { return }
	main_window.game.player_repr.position.x = f64(x)
	main_window.game.player_repr.position.y = f64(y)
}
*/

// pub fn frame_key_down(key gg.KeyCode, _ gg.Modifier, mut main_window &MainWindow) {
// 	if !main_window.game.is_ready || (key != .z && key != .x) { return }
// 	main_window.game.player.receive_keys_click(key)
// }

// pub fn frame_key_up(key gg.KeyCode, _ gg.Modifier, mut main_window &MainWindow) {
// 	if !main_window.game.is_ready || (key != .z && key != .x) { return }
// 	main_window.game.player.receive_keys_unclick(key)
// }


[console]
fn main() {
	// get beatmap path
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Kurarin')
	fp.version('v0.0.2')
	fp.description('Plays an osu! beatmap! (User mode soontm maybe)')

	beatmap_path := fp.string('beatmap_file', `b`, '', 'Path to the .osu file.')
	game_speed := fp.float('speed', `s`, 1.0, 'Gameplay speed. (Like DT yknow, but manual)')
	run_test := fp.bool('test', `t`, false, 'Run a test. (Lower your volume btw lol)')

	fp.finalize() or {
		println(fp.usage())
		return
	}

	// Check the path
	if !os.exists(beatmap_path) && !run_test {
		println(fp.usage())
		return
	}
	//
	println('> Beatmap: ${beatmap_path}')

	mut main_window := &MainWindow{mode: [0, 1][int(run_test)]}
	main_window.ctx = gg.new_context(
		width: int(resolution.global.width),
		height: int(resolution.global.height),
		window_title: "bruh",
		user_data: main_window,
		fullscreen: false,
		sample_count: 2,
		bg_color: gx.black,
		
		// FNs
		init_fn: frame_init,
		frame_fn: frame_update
		
		// keydown_fn: frame_key_down,
		// keyup_fn: frame_key_up,
		// move_fn: frame_mouse_move
	)

	// Init audio
	audio.init_audio()


	main_window.game_speed = game_speed
	main_window.game = window.make_game_window(ctx: mut main_window.ctx, beatmap: beatmap_path)
	main_window.ctx.run()
}
