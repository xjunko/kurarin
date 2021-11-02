module window

// import sync
import math
import lib.gg
import gx
// import time as timelib

//
import framework.audio
import framework.math.time as ktime
import framework.graphic.canvas

//
import game.beatmap
import game.math.resolution
import game.auto

pub struct GameWindow {
	pub mut:
		// important shit
		ctx 	&gg.Context = voidptr(0)
		audio   &audio.AudioController = voidptr(0)
		beatmap &beatmap.Beatmap = voidptr(0)
		beatmap_path string

		// time shit
		game_speed  f64 = f64(0.5)
		start_at    f64 = f64(2000)
		global_time &ktime.TimeCounter = &ktime.TimeCounter{}
		game_time   &ktime.TimeCounter = &ktime.TimeCounter{}
		render_time &ktime.TimeCounter = &ktime.TimeCounter{}


		// canvas
		game_canvas &canvas.Canvas = &canvas.Canvas{}
		beatmap_canvas &canvas.Canvas = voidptr(0)

		//
		video_writer &VideoWriter = voidptr(0)

		//
		auto        bool = true
		is_ready    bool
}

// Unused
pub fn (mut window GameWindow) initialize() {
	// Start audio
	// window.audio.add_audio_and_play(path: window.beatmap.get_audio_file())	
}

pub struct StartTimeArg {
	writer       &VideoWriter = voidptr(0)
}

pub fn (mut window GameWindow) start_game_loop(args StartTimeArg) {
	window.reset_time()

	// Time stuff
	window.game_time.reset()
	window.game_time.time = f64(-4000)
	window.game_time.multiplier = window.game_speed
	window.video_writer = args.writer
	if true {
		// Time update
		go fn (mut window GameWindow) {
			mut beatmap_music := window.audio.add_audio(path: window.beatmap.get_audio_file(), speed: window.game_speed)
			mut started := false
			for {
				window.global_time.tick()

				//
				if window.game_time.time >= 0 && !started {
					// Initialize game shit
					started = true
					beatmap_music.play()
					println("> GameWindow: Starting GameTime")
				}

				// tick game time also
				window.game_time.tick()

				// timelib.sleep(1 * timelib.millisecond)
				// Uncomment this if you want your cpu to not die lol
			}
		}(mut window)
	} else {
		println("> In Recording mode!")
		panic("Recording is not supported, yet lol.")
	}
}

pub fn (mut window GameWindow) reset_time() {
	mut times := [window.global_time, window.game_time, window.render_time]
	for mut t in times {
		t.reset()
	}
}

pub fn (mut window GameWindow) load_beatmap() {
	window.beatmap = beatmap.parse_beatmap(window.beatmap_path)
	window.beatmap.initialize_sprite_component(mut window.ctx)

	// load storyboard also (if theres any)
	window.beatmap.setup_storyboard(mut window.ctx)

	// Canvas
	window.game_canvas.scale = resolution.global.playfield_scale
	window.game_canvas.position.x = ((resolution.global.width - resolution.global.playfield_width) / 2) / resolution.global.playfield_scale
	window.game_canvas.position.y = ((resolution.global.height - resolution.global.playfield_height) / 2) / resolution.global.playfield_scale

	// Add flying shit before beatmap objects
	generate_bullshit(mut window)

	// Add beatmap shit into canvas
	for mut object in window.beatmap.objects {
		window.game_canvas.add_hitobject(mut object)
	}

	// add auto player if enabled
	if window.auto {
		window.add_auto_player(events: auto.make_auto(window.beatmap))
	}

	// ready
	window.is_ready = true
}

// draw
pub fn (mut window GameWindow) draw_time_info() {
	// Tick render time
	window.render_time.tick()
	window.ctx.draw_text(0, 0, 'Time: ${window.global_time.time} | Gametime: ${window.game_time.time}', gx.TextCfg{color: gx.white})
	window.ctx.draw_text(0, 16, 'Global Update: ${window.global_time.fps:.2f}fps [${window.global_time.delta:.2f}ms] | Game Update: ${window.game_time.fps:.2f}fps [${window.game_time.delta}ms] | Draw Update: ${window.render_time.fps:.2f}fps [${window.render_time.delta}ms]', gx.TextCfg{color: gx.white})
}

pub fn (mut window GameWindow) draw() {
	// Background
	window.beatmap.background_sprite.draw_and_update(ctx: window.ctx, time: window.game_time.time)

	// Storyboard
	if !isnil(window.beatmap.storyboard) {
		window.beatmap.storyboard.background.draw_and_update(window.ctx, window.game_time.time)
	}

	// Game canvas
	window.game_canvas.draw_and_update(window.ctx, window.game_time.time)

	// time
	window.draw_time_info()
}

pub struct MakeWindowArg {
	mut:
		ctx &gg.Context [required]
		beatmap string  [required]
}

pub fn make_game_window(arg MakeWindowArg) &GameWindow {
	mut window := &GameWindow{ctx: arg.ctx, beatmap_path: arg.beatmap}
	window.audio = audio.get_audio_controller()
	window.reset_time()

	return window
}

