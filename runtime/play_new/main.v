module play_new

import game.settings

import gx
import library.gg
import sync
import math

import sokol.gfx 
import sokol.sgl
// import time as i_time

import game.skin
import game.cursor
import game.ruleset
import game.beatmap
import game.beatmap.object.graphic

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
	window.background_s = &sprite.Sprite{textures: [gg.Image{}], position: vector.Vector2{1280.0 / 2.0, 720.0 / 2.0}, always_visible: true}
	window.last_background_s = &sprite.Sprite{textures: [gg.Image{}], position: vector.Vector2{1280.0 / 2.0, 720.0 / 2.0}, always_visible: true}
	window.logo_s = &sprite.Sprite{position: vector.Vector2{1280.0 / 2.0, 720.0 / 2.0}, always_visible: true}

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
		button.add_transform(typ: .move_y, time: time.Time{0.0, 0.0}, before: [((720.0 / 2.0)-175) + ((114 + 5) * i)])
		button.color.r = i * 255
		button.color.g = 100 + i * 100
		button.color.b = 50 + i * 200
		button.color.a = 0
		window.menu_buttons << button
		window.manager.add(mut button)

		button.reset_size_based_on_texture()
		button.reset_attributes_based_on_transforms()
	}

	// jk, initialize beatmap list stuff
	how_many_on_screen := 14
	size_per_map := 720.0 / f64(how_many_on_screen)
	list_texture := window.ctx.create_image("assets/textures/menu-button-background.png")

	for i in 0 .. how_many_on_screen + 2 { // 2 for offscreen
		mut beatmap_s := &sprite.Sprite{textures: [list_texture], always_visible: true, origin: vector.top_left}
		beatmap_s.add_transform(typ: .move, time: time.Time{0, 0}, before: [f64(i) * 10, f64(i) * size_per_map])
		beatmap_s.add_transform(typ: .fade, time: time.Time{0, 0}, before: [0.0])
		beatmap_s.reset_size_based_on_texture(size: vector.Vector2{x: 300.0, y: size_per_map})
		beatmap_s.reset_attributes_based_on_transforms()

		// Debug
		beatmap_s.color.r = i * 255
		beatmap_s.color.g = 100 + i * 100
		beatmap_s.color.b = 50 + i * 200

		window.list_beatmap_s << beatmap_s
		window.manager.add(mut beatmap_s)
	}

	window.manager.add(mut window.logo_s)
}

pub fn (mut window Window) update_loop() {
	window.task = .loading

	// HACK: Do something about this, some old relic code from kurarin 0.0.0 from 2020
	time.reset()

	for window.task != .exit {
		time.tick()
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

	// window.ctx.end()
	gfx.begin_default_pass(graphic.global_renderer.pass_action, 1280, 720)
	sgl.draw()
	gfx.end_pass()

	gfx.commit()
}

pub fn main() {
	mut window := &Window{}
	window.ctx = gg.new_context(
		width: 1280,
		height: 720,
		user_data: window,

		// FNs
		init_fn: window.initialize,
		frame_fn: window.draw,

		keydown_fn: window.key_down
	)

	window.ctx.run()
}