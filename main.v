import os
import flag
import lib.gg
import gx
import game.window

import game.math.resolution
import game.animation

import tests

pub struct MainWindow {
	pub mut:
		ctx &gg.Context = voidptr(0)
		game &window.GameWindow = voidptr(0)
		mode int

		// temp stuff
		game_speed f64 = 1.0
		test_stage int
}

pub fn (mut main_window MainWindow) draw_testing_mode() {
	stage_name := match main_window.test_stage {
		0 { 'Hitsound test' }
		else { 'None' }
	}

	// main_window.ctx.draw_text(0, 16, 'Currently testing: ${stage_name}', gx.TextCfg{color: gx.white})

	// do the test
	println('Currently testing: ${stage_name}')
	match main_window.test_stage {
		0 { tests.stress_test_audio() main_window.test_stage++}
		1 { println('Done testing!') exit(1)}
		else {}
	}
	
}

pub fn frame_init(mut main_window &MainWindow) {
	animation.ready_cache()

	if main_window.mode == 0 {
		main_window.game.load_beatmap()
		main_window.game.game_speed = main_window.game_speed
		main_window.game.start_game_loop(writer: 0)
	}
}

pub fn frame_update(mut main_window &MainWindow) {
	main_window.ctx.begin()

	if main_window.game.is_ready {
		main_window.game.draw()
	} else if main_window.mode == 1 {
		main_window.ctx.draw_text(0, 0, 'Running in test mode', gx.TextCfg{color: gx.white})
		main_window.draw_testing_mode()
	} else {
		main_window.ctx.draw_text(0, 0, 'Loading... ig...', gx.TextCfg{color: gx.white})
	}

	

	main_window.ctx.end()
}

[console]
fn main() {
	// get beatmap path
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Kurarin')
	fp.version('Not good enough for a version.')
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
		
		// FNs
		init_fn: frame_init,
		frame_fn: frame_update
	)

	main_window.game_speed = game_speed
	main_window.game = window.make_game_window(ctx: mut main_window.ctx, beatmap: beatmap_path)
	main_window.ctx.run()
}
