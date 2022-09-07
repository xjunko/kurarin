module old_gui

import core.common.settings

import gx
import library.gg
import sync
import math

import sokol.gfx 
import sokol.sgl
// import time as i_time

import core.osu.skin
import core.osu.cursor
import core.osu.ruleset
import core.osu.beatmap
import core.osu.beatmap.object.graphic

import framework.audio
import framework.logging
import framework.math.time
import framework.math.vector
import framework.graphic.sprite
import framework.graphic.visualizer

/*
	TODO:
	* split scenes into their own struct, maybe somewhere in game/scene
	* clean up the ui code
	* banger song ngl
*/

const (
	shut_the_fuck_up_v = settings.ok_sure
	logo_hearbeat_rate = f64(1000.0) // ms
)

pub enum Task {
	init
	loading
	menu
	list
	loading_beatmap
	playing
	exit
}

pub struct Window {
	mut:
		limiter    &time.Limiter = &time.Limiter{fps: 480}
		beatmaps   []&beatmap.Beatmap

		beatmaps_i_c int // Current
		beatmaps_i_l int = -1 // Last (Force to load on start)

		current           &beatmap.Beatmap = voidptr(0)
		audio             &audio.Track = voidptr(0)

		// Menu
		background        gg.Image
		background_s 	  &sprite.Sprite = voidptr(0)

		last_background   gg.Image
		last_background_s &sprite.Sprite = voidptr(0)

		logo_s       &sprite.Sprite = voidptr(0)
		logo_counter f64

		visualizer &visualizer.Visualizer = voidptr(0)

		manager           &sprite.Manager = voidptr(0)
		overlay           &sprite.Manager = voidptr(0)

		menu_title_x  f64
		menu_triggered bool
		menu_last_state bool
		menu_buttons []&sprite.Sprite

		// bruh
		safely_initialized bool // Will be used for initiliazing fields/var/whatever

		last_time f64

		// Beatmap list
		list_manager   &sprite.Manager = voidptr(0)

		list_beatmap_s []&sprite.Sprite
		list_offset_y f64
		list_offset_y_sm f64 // Smoothen

		// Gameplay
		players          []&cursor.Cursor
		auto             &cursor.AutoCursor = voidptr(0)
		ruleset 		 &ruleset.Ruleset = voidptr(0)
		start_playing_at f64 // TODO: retarded

		// Required for data race bullshit
		mutex &sync.Mutex = sync.new_mutex()

	pub mut:
		ctx  &gg.Context = voidptr(0)
		task Task = .init
}

pub fn (mut window Window) initialize() {
	logging.info("Window initialize!")

	// Renderer (important so we init it here instead.)
	skin.bind_context(mut window.ctx)
	graphic.init_slider_renderer()

	go window.update_loop()
}

pub fn (mut window Window) initialize_variables() {
	// Manager
	window.manager = sprite.make_manager()
	window.overlay = sprite.make_manager()

	// Visuazlier
	window.visualizer = &visualizer.Visualizer{music: 0}

	// Images
	window.background_s = &sprite.Sprite{textures: [gg.Image{}], position: vector.Vector2{settings.global.window.width / 2.0, settings.global.window.height / 2.0}, always_visible: true}
	window.last_background_s = &sprite.Sprite{textures: [gg.Image{}], position: vector.Vector2{settings.global.window.width / 2.0, settings.global.window.height / 2.0}, always_visible: true}
	window.logo_s = &sprite.Sprite{position: vector.Vector2{settings.global.window.width / 2.0, settings.global.window.height / 2.0}, always_visible: true}

	// Load required images
	window.logo_s.textures << window.ctx.create_image("assets/textures/logo.png")
	window.logo_s.reset_size_based_on_texture(source: vector.Vector2{400, 400}, fit_size: true)

	// Add shit
	window.manager.add(mut window.background_s)
	window.manager.add(mut window.last_background_s)

	// and lastly
	// Menu buttons
	button_texture := window.ctx.create_image("assets/textures/menu_button.png")
	for i in 0 .. 3 {
		mut button := &sprite.Sprite{textures: [button_texture], always_visible: true, origin: vector.top_left}
		button.add_transform(typ: .move_y, time: time.Time{0.0, 0.0}, before: [((settings.global.window.height / 2.0)-175) + ((114 + 5) * i)])
		button.color.r = i * 255
		button.color.g = 100 + i * 100
		button.color.b = 50 + i * 200
		button.color.a = 0
		window.menu_buttons << button
		window.manager.add(mut button)

		button.reset_size_based_on_texture()
		button.reset_attributes_based_on_transforms()
	}
	
	window.manager.add(mut window.logo_s)
}

pub fn (mut window Window) update_loop() {
	window.task = .loading

	// HACK: Do something about this, some old relic code from kurarin 0.0.0 from 2020
	mut g_time := time.get_time()
	g_time.reset()

	for window.task != .exit {
		g_time.tick()
		window.update()
		window.limiter.sync()
	}
}

pub fn (mut window Window) update() {
	window.mutex.@lock()

	// Safe checking
	if !window.safely_initialized {
		window.initialize_variables()
		window.safely_initialized = true
	}
	
	// The actual code
	if window.task == .loading {
		window.update_loading()
	}
	
	if window.task == .list {
		window.update_list()
	}

	if window.task == .menu {
		window.update_menu()
	}

	if window.task == .playing {
		window.update_playing()
	}

	// Done
	window.last_time = time.global.time
	window.mutex.unlock()
}

pub fn (mut window Window) draw() {
	// Dont do anything yet... wait for the game to initialized.
	if !window.safely_initialized {
		return
	}

	// Load queued images
	window.ctx.load_image_queue()

	// Background (draw it no matter what)
	window.ctx.begin()
	window.ctx.end()

	// Gameplay uses its own renderer
	if window.task == .playing {
		// window.draw_scene() // We can use window.draw_scene() here but better be explicit
		window.current.draw()
	}

	// Normal rendering
	// Start drawing
	window.ctx.begin()

	// Normal menu
	if window.task != .playing {
		window.draw_scene()
	}

	// Cursors
	if window.task == .playing {
		for mut player in window.players {
			player.draw()
		}
	}

	window.ctx.draw_rect_filled(0, 0, 100, 20, gx.Color{0, 0, 0, 100})
	window.ctx.draw_text(5, 0, "Scene: ${window.task}", gx.TextCfg{color: gx.white, size: 20})

	// window.ctx.endheight
	gfx.begin_default_pass(graphic.global_renderer.pass_action, int(settings.global.window.width), int(settings.global.window.height))
	sgl.draw()
	gfx.end_pass()

	gfx.commit()
}

pub fn (mut window Window) scroll(event &gg.Event, _ voidptr) {
	if window.task == .list {
		window.list_offset_y += event.scroll_y * 50

		// Dont overscroll
		window.list_offset_y = math.min<f64>(window.list_offset_y, 0.0)
		
	}
}

pub fn main() {
	mut window := &Window{}
	window.ctx = gg.new_context(
		width: int(settings.global.window.width),
		height: int(settings.global.window.height),
		user_data: window,

		// FNs
		init_fn: window.initialize,
		frame_fn: window.draw,

		keydown_fn: window.key_down
		scroll_fn: window.scroll
	)

	window.ctx.run()
}