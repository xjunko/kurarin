module gui

import gg
import core.osu.runtime
import core.osu.parsers.beatmap
import framework.audio
import framework.graphic.sprite
import framework.graphic.context
import framework.graphic.window as i_window
import framework.math.time
import framework.math.vector
import os

pub struct CustomSpriteManager {
	sprite.Manager
}

pub fn (mut sprite_manager CustomSpriteManager) fadeout_and_die(time_to_die f64, time_took_to_die f64) {
	for i, _ in sprite_manager.queue {
		sprite_manager.queue[i].time.end = time_to_die + time_took_to_die
		sprite_manager.queue[i].always_visible = false
	}
}

pub struct MainMenu {
mut:
	window     &GUIWindow
	background &CustomSpriteManager = &CustomSpriteManager{
	Manager: sprite.make_manager()
}
pub mut:
	current_beatmap &beatmap.Beatmap = unsafe { nil }
	current_track   &audio.Track     = unsafe { nil }
}

pub fn (mut main_menu MainMenu) change_beatmap(new_beatmap &beatmap.Beatmap) {
	main_menu.window.logs << '[${@METHOD}] Changing beatmap to ${new_beatmap.metadata.title} [${new_beatmap.metadata.version}]'

	if !isnil(main_menu.current_track) {
		// Old track
		main_menu.current_track.pause()
		main_menu.current_track.set_volume(0.0)
		main_menu.window.logs << 'Discarding old track.'
	}

	// New track
	main_menu.current_track = audio.new_track(new_beatmap.get_audio_path())
	main_menu.current_track.set_volume(0.4)
	main_menu.current_track.set_position(new_beatmap.general.preview_time)
	main_menu.current_track.play()
	main_menu.window.logs << 'Playing new track.'

	main_menu.background.fadeout_and_die(main_menu.window.time.time, 500.0)

	// Load background and other crap
	mut background := &sprite.Sprite{
		always_visible: true
		textures: [main_menu.window.ctx.create_image(new_beatmap.get_bg_path())]
		origin: vector.top_left
	}

	background.add_transform(
		typ: .fade
		time: time.Time{main_menu.window.time.time, main_menu.window.time.time + 500.0}
		before: [0.0]
		after: [255.0]
	)

	background.reset_size_based_on_texture(
		fit_size: true
		source: vector.Vector2[f64]{1280.0, 720.0}
	)

	main_menu.background.add(mut background)

	main_menu.current_beatmap = unsafe { new_beatmap }
}

pub fn (mut main_menu MainMenu) update(time_ms f64) {
	main_menu.background.update(time_ms)
}

pub fn (mut main_menu MainMenu) draw(arg sprite.CommonSpriteArgument) {
	main_menu.background.draw(arg)

	main_menu.window.ctx.draw_rect_filled(0, 0, 1280, 720, gg.Color{0, 0, 0, 100})

	if isnil(main_menu.current_beatmap) {
		return
	}

	// NOTE: this is super scuffed rn

	// Artist
	main_menu.window.ctx.draw_rect_filled(1280 - 50 - (main_menu.window.ctx.text_width(main_menu.current_beatmap.metadata.artist) * 2),
		200 - 32, (main_menu.window.ctx.text_width(main_menu.current_beatmap.metadata.artist) * 2),
		30, gg.Color{0, 0, 0, 255})
	main_menu.window.ctx.draw_text(1280 - 50, 200 - 32, main_menu.current_beatmap.metadata.artist,
		
		color: gg.Color{255, 255, 255, 255}
		align: .right
		size: 30
	)

	// Title
	main_menu.window.ctx.draw_rect_filled(1280 - 100 - (main_menu.window.ctx.text_width(main_menu.current_beatmap.metadata.title) * 2),
		200, (main_menu.window.ctx.text_width(main_menu.current_beatmap.metadata.title) * 2),
		32, gg.Color{0, 0, 0, 255})
	main_menu.window.ctx.draw_text(1280 - 100, 200, main_menu.current_beatmap.metadata.title,
		
		color: gg.Color{255, 255, 255, 255}
		align: .right
		size: 32
	)
}

[heap]
pub struct GUIWindow {
	i_window.GeneralWindow
mut:
	logs []string
	time &time.TimeCounter = unsafe { nil }
pub mut:
	manager &beatmap.BeatmapManager = unsafe { nil }
	menu    &MainMenu = unsafe { nil }

	joe      bool
	joe_i    int
	joe_path string
}

pub fn (mut window GUIWindow) init(_ voidptr) {
	// Reset time
	window.time = time.get_time()

	// Start
	window.logs << 'Initialize.'

	window.manager = beatmap.make_manager('/run/media/junko/2nd/Projects/dementia/assets/osu/maps/')

	window.logs << 'Found beatmaps: ${window.manager.beatmaps.len} beatmaps'

	// Scenes
	window.logs << 'Setting up scenes.'

	window.menu = &MainMenu{
		window: window
	}

	window.logs << 'Done setting up scenes.'

	//
	window.start_update_thread()

	// Test
	window.menu.change_beatmap(&window.manager.beatmaps[0].versions[0])
}

pub fn (mut window GUIWindow) draw(_ voidptr) {
	window.tick_draw()

	window.ctx.begin()

	window.mutex.@lock()

	// Draw scenes
	window.menu.draw(ctx: window.ctx)

	window.mutex.unlock()

	window.draw_stats()

	// Draw logs (The last 32)
	for i, log in window.logs#[-32..] {
		window.ctx.draw_rect_filled(0, i * 16, window.ctx.text_width(log), 16, gg.Color{0, 0, 0, 255})
		window.ctx.draw_text(0, i * 16, log, color: gg.Color{255, 255, 255, 255})
	}

	window.ctx.end()
}

// Updates
pub fn (mut window GUIWindow) start_update_thread() {
	window.logs << 'Update thread starting.'

	go fn (mut window GUIWindow) {
		window.logs << 'Update thread started.'

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

	window.menu.update(time_ms)
}

pub fn main() {
	mut window := &GUIWindow{
		manager: 0
	}

	window.logs << 'Runtime logs:'
	window.logs << 'Hello world.'

	window.logs << 'Creating GG context.'

	mut gg_context := gg.new_context(
		// Basic
		width: 1280
		height: 720
		user_data: window
		// FNs
		init_fn: window.init
		frame_fn: window.draw
		keydown_fn: fn (key gg.KeyCode, mod gg.Modifier, mut window GUIWindow) {
			if key == .right {
				window.joe_i++

				window.menu.change_beatmap(&window.manager.beatmaps[window.joe_i % window.manager.beatmaps.len].versions[0])
			}

			if key == .left {
				window.joe_i--

				window.menu.change_beatmap(&window.manager.beatmaps[window.joe_i % window.manager.beatmaps.len].versions[0])
			}

			if key == .p {
				window.joe_path = os.join_path(window.menu.current_beatmap.root, window.menu.current_beatmap.filename)
				window.menu.current_track.pause()
				window.ctx.quit()
			}
		}
	)

	window.ctx = &context.Context{
		Context: gg_context
	}

	window.logs << 'Wrapping Context with our own impl.'
	window.logs << 'Get ready to run.'

	window.ctx.run()

	runtime.run(window.joe_path, '', true)
}
