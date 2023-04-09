module beatmap

// Code is based on
// https://github.com/nastys/nastys.github.io/blob/master/dsceditor/dsc_worker_read.js
import os
import gx
import math
import encoding.binary
import framework.math.vector
import framework.math.time
import framework.graphic.sprite
import framework.audio
import core.diva.skin
import core.diva.beatmap.opcodes

const (
	ft_fmts = [
		353510679,
		285614104,
		335874337,
		369295649,
		352458520,
		335745816,
		335618838,
		319956249,
		319296802,
		318845217,
	]

	hit_sfx = audio.new_sample('assets/diva/sfx/hit.ogg')
)

pub fn read_raw_beatmap(path string) []opcodes.OPCode {
	raw_file_data := os.read_bytes(path) or { panic('Fucked up: ${err}') }

	mut commands := []opcodes.OPCode{}

	for i := 0; i < raw_file_data.len; i += 4 {
		number := int(binary.little_endian_u32(raw_file_data[i..i + 4]))

		// Verify
		if i == 0 {
			if beatmap.ft_fmts.contains(number) {
				println('Detected format: AFT')
			}
		}

		// Read OPCODEs
		if number in opcodes.codes {
			mut operation := opcodes.codes[number].clone()
			mut params := []int{}

			for j := 0; j < operation.length; j++ {
				i += 4
				params << int(binary.little_endian_u32(raw_file_data[i..i + 4]))
			}

			if params.len > 0 {
				operation.arguments << params
			}

			commands << operation
		}
	}

	return commands
}

// Abstracted struct
// TODO: MOve this
pub struct Note {
mut:
	command  opcodes.OPCode
	finished bool
pub mut:
	typ        int
	time       time.Time
	position   vector.Vector2
	angle      int
	wave_count int
	distance   int
	amplitude  int
	tft        int
	ts         int

	sprites []&sprite.Sprite
}

pub fn (mut note Note) update(update_time f64) {
	for mut sprite in note.sprites {
		sprite.update(update_time)
	}

	if update_time >= note.time.end && !note.finished {
		unsafe { beatmap.hit_sfx.play() }
		note.finished = true
	}
}

pub fn (mut note Note) get_note_sprite() string {
	return match note.typ {
		0, 4, 8, 18 { 'm_triangle' }
		1, 5, 9, 19 { 'm_circle' }
		2, 6, 10, 20 { 'm_cross' }
		3, 7, 11, 21 { 'm_square' }
		else { 'm_circle' }
	}
}

pub fn (mut note Note) get_note_background_sprite() string {
	return note.get_note_sprite() + '_bg'
}

pub fn (mut note Note) init(mut arg sprite.CommonSpriteArgument) {
	common_scale := 0.75

	for i, sprite_name in [note.get_note_background_sprite(),
		note.get_note_sprite(), 'm_arrow'] {
		mut note_sprite := &sprite.Sprite{}
		note_sprite.textures << skin.get_texture(sprite_name)

		// Note
		if i < 2 {
			if i == 0 { // Note Background
				note_sprite.add_transform(
					typ: .move
					time: time.Time{note.time.start - note.tft, note.time.end}
					before: [note.position.x, note.position.y]
					after: [note.position.x, note.position.y]
				)
			} else {
				// Actual note, moves around and shit
				start_x := note.position.x +
					math.sin((f64(note.angle) / 1000.0) * math.pi / 180.0) * (f64(note.distance) / 500)
				start_y := note.position.y - math.cos((f64(note.angle) / 1000.0) * math.pi / 180.0) * (f64(note.distance) / 500)
				note_sprite.add_transform(
					typ: .move
					time: time.Time{note.time.start - note.tft, note.time.end}
					before: [start_x, start_y]
					after: [note.position.x, note.position.y]
				)
				note_sprite.add_transform(
					typ: .scale_factor
					time: time.Time{note.time.end, note.time.end + 100}
					before: [1.0 * common_scale]
					after: [
						1.5 * common_scale,
					]
				)
				note_sprite.add_transform(
					typ: .fade
					time: time.Time{note.time.end, note.time.end + 100}
					before: [255.0]
					after: [0.0]
				)
			}
		} else {
			note_sprite.origin = vector.bottom_centre
			note_sprite.add_transform(
				typ: .angle
				time: time.Time{note.time.start - note.tft, note.time.end}
				before: [0.0]
				after: [math.pi * 2]
			)
			note_sprite.add_transform(
				typ: .move
				time: time.Time{note.time.start - note.tft, note.time.end}
				before: [note.position.x, note.position.y]
				after: [note.position.x, note.position.y]
			)
		}

		// sprite.add_transform(typ: .fade, time: time.Time{note.time.start - note.tft, note.time.end}, before: [0.0], after: [255.0])
		// sprite.add_transform(typ: .fade, time: time.Time{note.time.end, note.time.end + 100}, before: [0.0], after: [0.0])
		note_sprite.add_transform(
			typ: .scale_factor
			time: time.Time{note.time.start - f64(note.tft), note.time.start - f64(note.tft) + 30}
			before: [1.0 * common_scale]
			after: [
				1.2 * common_scale,
			]
		)
		note_sprite.add_transform(
			typ: .scale_factor
			time: time.Time{note.time.start - f64(note.tft) + 30, note.time.start - f64(note.tft) +
				60}
			before: [
				1.2 * common_scale,
			]
			after: [1.0 * common_scale]
		)
		// sprite.add_transform(typ: .scale_factor, time: time.Time{note.time.start - 30, note.time.start}, before: [1.4], after: [1.0])

		note_sprite.reset_size_based_on_texture()
		note_sprite.reset_attributes_based_on_transforms()

		// Finish
		note.sprites << note_sprite
	}

	// Hit animation
	for i, sprite_name in ['m_hit_effect', 'm_hit'] {
		mut effect_sprite := &sprite.Sprite{
			additive: true
		}
		effect_sprite.textures << skin.get_texture(sprite_name)

		effect_sprite.add_transform(
			typ: .fade
			time: time.Time{note.time.end + 200, note.time.end + 300}
			before: [255.0]
			after: [0.0]
		)
		effect_sprite.add_transform(
			typ: .move
			time: time.Time{note.time.end, note.time.end + 200}
			before: [note.position.x, note.position.y]
			after: [note.position.x, note.position.y]
		)
		effect_sprite.add_transform(
			typ: .scale_factor
			time: time.Time{note.time.end, note.time.end + 200}
			before: [0.75 * common_scale]
			after: [
				(1.0 + (f64(1 - i) / 2.0)) * common_scale,
			]
		)

		effect_sprite.reset_size_based_on_texture()
		effect_sprite.reset_attributes_based_on_transforms()

		note.sprites << effect_sprite
	}
}

pub struct Beatmap {
mut:
	internal_repr_of_commands []opcodes.OPCode
pub mut:
	objects   []&Note
	objects_i int
	queue     []&Note
	sprites   []&sprite.Sprite
}

pub fn (mut beatmap Beatmap) reset(mut arg sprite.CommonSpriteArgument) {
	// Note Sprite
	for i := 0; i < beatmap.objects.len; i++ {
		beatmap.objects[i].init(mut arg)
	}

	// Background
	mut background := &sprite.Sprite{
		always_visible: true
		origin: vector.top_left
	}
	background.textures << skin.get_texture('g_default_bg')
	background.reset_size_based_on_texture()

	// Frame
	mut top_frame := &sprite.Sprite{
		always_visible: true
		origin: vector.top_left
	}
	top_frame.textures << skin.get_texture('g_top')

	top_frame.reset_size_based_on_texture(source: vector.Vector2{800, 500}, fit_size: true)

	mut bottom_frame := &sprite.Sprite{
		always_visible: true
		origin: vector.bottom_left
	}
	bottom_frame.position.y = 720.0
	bottom_frame.textures << skin.get_texture('g_bottom')

	bottom_frame.reset_size_based_on_texture(source: vector.Vector2{1280, 720}, fit_size: true)

	beatmap.sprites << background
	beatmap.sprites << top_frame
	beatmap.sprites << bottom_frame
}

pub fn (mut beatmap Beatmap) transform_commands_to_notes() {
	// Simulate gameplay loop
	mut current_line := 0
	mut current_time := 0
	mut current_bpm := 0
	mut current_tft := 0

	for current_line < beatmap.internal_repr_of_commands.len {
		current_command := beatmap.internal_repr_of_commands[current_line]

		match current_command.action {
			'BAR_TIME_SET' {
				current_bpm = current_command.arguments[0]
				current_tft = 1000 / (current_bpm / ((current_command.arguments[1] + 1) * 60))
			}
			'TARGET_FLYING_TIME' {
				current_tft = current_command.arguments[0]
				current_bpm = 240000 / current_tft
			}
			'TARGET' {
				beatmap.objects << &Note{
					typ: current_command.arguments[0]
					time: time.Time{f64(current_time), f64(current_time)}
					position: vector.Vector2{
						x: f64(current_command.arguments[1]) * 0.002666667
						y: f64(current_command.arguments[2]) * 0.002666667
					}
					angle: current_command.arguments[3]
					distance: current_command.arguments[4]
					amplitude: current_command.arguments[5]
					tft: current_tft
					ts: -1
				}
			}
			'TIME' {
				current_time = current_command.arguments[0] / 100
			}
			else {}
		}

		// Last
		current_line++
	}
}

pub fn (mut beatmap Beatmap) update(update_time f64) {
	// Add to queue
	preempt := 5000.0 // diva is abit unique cuz the
	// start time can be varied,
	// so fuck it, 5 second time window it is.
	for i := beatmap.objects_i; i < beatmap.objects.len; i++ {
		if update_time >= beatmap.objects[i].time.start - preempt {
			beatmap.queue << beatmap.objects[i]
			beatmap.objects_i++
			continue
		}
	}

	// Remove from queue
	for i := 0; i < beatmap.queue.len; i++ {
		if update_time >= beatmap.queue[i].time.end + preempt {
			beatmap.queue = beatmap.queue[1..]
			i--
			continue
		}

		// If not update
		beatmap.queue[i].update(update_time)
	}
}

pub fn (mut beatmap Beatmap) draw(arg sprite.CommonSpriteArgument) {
	// BG
	beatmap.sprites[0].draw(arg)

	// Dim
	arg.ctx.draw_rect_filled(0, 0, 1280, 720, gx.Color{0, 0, 0, 100})

	for mut note in beatmap.queue {
		for mut sprite in note.sprites {
			sprite.draw(arg)
		}
	}

	// Overlays
	beatmap.sprites[1].draw(arg)
	beatmap.sprites[2].draw(arg)
}

pub fn read_beatmap(path string) &Beatmap {
	mut beatmap := &Beatmap{}

	beatmap.internal_repr_of_commands = read_raw_beatmap(path)
	beatmap.transform_commands_to_notes()

	return beatmap
}
