module play_new

// import gx
import sync
import library.gg

import core.common.settings

import core.osu.beatmap

import framework.audio

import framework.graphic.window
import framework.graphic.sprite
import framework.graphic.visualizer

import framework.math.vector
import framework.math.time

const (
	frame_rate = 120
)

[heap]
pub struct Window {
	window.GeneralWindow

	mut:
		song &audio.Track = unsafe { 0 }
		logo &sprite.Sprite = unsafe { 0 }
		background &sprite.Sprite = unsafe { 0 }
		background_glow &sprite.Sprite = unsafe { 0 }
		sides []&sprite.Sprite

		beatmap &beatmap.Beatmap = unsafe { 0 }

	pub mut:
		sprites &sprite.Manager = sprite.make_manager()
		mutex   &sync.Mutex = sync.new_mutex()
		limiter &time.Limiter = &time.Limiter{fps: frame_rate}
		visualizer &visualizer.Visualizer = unsafe { 0 }
}

pub fn (mut window Window) init(_ voidptr) {
	// Load beatmap
	window.beatmap = beatmap.parse_beatmap(
		"/home/junko/.local/share/osu/exports/MachineGunPoemDoll/cosMo@BousouP feat. Hatsune Miku - Machinegun Poem Doll (AutotelicBrown) [Elegy].osu", 
		true
	)

	// Make some crap
	window.background = &sprite.Sprite{
		textures: [window.ctx.create_image(window.beatmap.get_bg_path())]
		always_visible: true,
		position: vector.Vector2{settings.global.window.width / 2.0, settings.global.window.height / 2.0}
	}

	window.background_glow = &sprite.Sprite{
		textures: [window.ctx.create_image(window.beatmap.get_bg_path())]
		always_visible: true,
		position: vector.Vector2{settings.global.window.width / 2.0, settings.global.window.height / 2.0},
		additive: true
	}

	window.background.reset_size_based_on_texture(source: vector.Vector2{settings.global.window.width + 100, 768.0}, fit_size: true) // Make it a lil bigger than screen size
	window.background_glow.reset_size_based_on_texture(source: vector.Vector2{settings.global.window.width + 100, 768.0}, fit_size: true) // Make it a lil bigger than screen size
	window.sprites.add(mut window.background)
	window.sprites.add(mut window.background_glow)

	// Logo
	window.logo = &sprite.Sprite{
		textures: [window.ctx.create_image("assets/common/textures/menu-logo-osu.png")],
		always_visible: true,
		position: vector.Vector2{settings.global.window.width / 2.0, settings.global.window.height / 2.0}
	}

	rate := settings.global.window.height / 720.0

	window.logo.reset_size_based_on_texture(source: vector.Vector2{300.0 * rate, 300.0 * rate}, fit_size: true)

	window.sprites.add(mut window.logo)

	// Side glows
	for i in 0 .. 2 {
		mut sprite := &sprite.Sprite{
			textures: [window.ctx.create_image("assets/common/textures/menu-side-glow.png")],
			always_visible: true,
			origin: vector.top_left,
			additive: true
		}

		sprite.reset_size_based_on_texture(size: vector.Vector2{f64(sprite.textures[0].width) * rate, settings.global.window.height})
		
		sprite.color.r = 0
		sprite.color.g = 90
		sprite.color.b = 100

		if i == 1 {
			sprite.origin = vector.bottom_centre
			sprite.position.x = settings.global.window.width - (f64(sprite.textures[0].width) * rate) / 2.0
			sprite.angle = -180.0
		}

		window.sprites.add(mut sprite)

		window.sides << sprite
	}


	// Thread
	go fn (mut window Window){
		mut limiter := &time.Limiter{fps: frame_rate}
		mut g_time := time.get_time()
		g_time.reset()
		
		window.song = audio.new_track(window.beatmap.get_audio_path())
		window.song.set_volume(0.3)

		rate := settings.global.window.height / 720.0

		// Vis
		window.visualizer = &visualizer.Visualizer{music: window.song}
		window.visualizer.bar_draw_length *= rate * 1.5

		window.visualizer.update_logo(vector.Vector2{1280.0 / 2.0 - 300.0 / 2.0, 720.0 / 2.0 - 300.0 / 2.0}, vector.Vector2{300.0, 300.0})

		for {
			if !window.song.playing {
				window.song.play()
			}

			window.mutex.@lock()

			// Tick info
			window.GeneralWindow.tick_update()

			// Updates
			window.sprites.update(g_time.time)
			window.song.update(g_time.time)
			window.visualizer.update(g_time.time)

			// Smoothen

			// Sync logo with visualizer
			window.logo.size.x = 300.0 * rate * (1.0 + window.song.boost_sm)
			window.logo.size.y = 300.0 * rate * (1.0 + window.song.boost_sm)

			window.visualizer.logo_position.x = window.logo.position.x - window.visualizer.logo_size.x / 2.0
			window.visualizer.logo_position.y = window.logo.position.y - window.visualizer.logo_size.y / 2.0
			window.visualizer.logo_size = window.logo.size

			// GLow shit
			window.sides[0].color.a = u8(255.0 * (window.song.boost_sm * 4.0) * 0.25 + f64(window.sides[0].color.a) - f64(window.sides[0].color.a) * 0.25)
			window.sides[1].color.a = window.sides[0].color.a
			window.background_glow.color.a = window.sides[0].color.a / 4

			window.mutex.unlock()
			limiter.sync()
		}
	}(mut window)
}

pub fn (mut window Window) draw(_ voidptr) {
	window.ctx.begin()

	// Tick info
	window.GeneralWindow.tick_draw()

	window.sprites.draw(ctx: window.ctx, time: 0.0)
	window.visualizer.draw(mut window.ctx)

	// Draw common shit
	window.GeneralWindow.draw_stats()

	window.ctx.end()
	window.limiter.sync()
}

pub fn main() {
	mut window := &Window{}

	window.ctx = gg.new_context(
		width: int(settings.global.window.width), 
		height: int(settings.global.window.height),
		user_data: window,

		// FNs
		init_fn: window.init,
		frame_fn: window.draw,
	)

	window.ctx.run()
}