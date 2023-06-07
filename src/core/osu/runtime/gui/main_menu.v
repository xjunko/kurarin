module gui

import gg
import core.osu.parsers.beatmap
import framework.audio
import framework.logging
import framework.graphic.sprite
import framework.math.time
import framework.math.vector

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
	logging.info('[${@METHOD}] Changing beatmap to ${new_beatmap.metadata.title} [${new_beatmap.metadata.version}]')

	if !isnil(main_menu.current_track) {
		// Old track
		main_menu.current_track.pause()
		main_menu.current_track.set_volume(0.0)
		logging.info('Discarding old track.')
	}

	// New track
	main_menu.current_track = audio.new_track(new_beatmap.get_audio_path())
	main_menu.current_track.set_volume(0.2)
	main_menu.current_track.set_position(new_beatmap.general.preview_time)
	main_menu.current_track.play()
	logging.info('Playing new track.')

	main_menu.background.fadeout_and_die(main_menu.window.time.time, 50.0)

	// Load background and other crap
	mut background := &sprite.Sprite{
		always_visible: true
		textures: [main_menu.window.ctx.create_image(new_beatmap.get_bg_path())]
		origin: vector.top_left
	}

	background.add_transform(
		typ: .fade
		time: time.Time{main_menu.window.time.time, main_menu.window.time.time + 50.0}
		before: [195.0]
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
