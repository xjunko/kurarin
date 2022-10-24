module object

import gx
import math

import core.sekai.skin

import framework.audio
import framework.graphic.sprite

import framework.math.time
import framework.math.vector
// import framework.math.easing

const (
	note_flick = audio.new_sample("assets/psekai/sounds/note_flick.mp3")
	note_flick_critical = audio.new_sample("assets/psekai/sounds/note_flick_critical.mp3")

	note_perfect = audio.new_sample("assets/psekai/sounds/note_perfect.mp3")
	note_critical = audio.new_sample("assets/psekai/sounds/note_critical.mp3")

	note_volume = f32(0.5)
	
)

pub struct NoteObjectSprite {
	NoteObject

	mut:
		finished bool

		is_flick bool
		is_critical bool
		is_path bool

	pub mut:
		sprites []&sprite.Sprite
}

pub fn (mut note NoteObjectSprite) initialize(is_flick bool, is_critical bool, direction int) {
	// note.lane = 6
	// note.width = 5.0
	note.is_flick = is_flick // troll
	note.is_critical = is_critical
	preempt := 700.0

	mut type_of_note := "normal"

	if note.is_flick {
		type_of_note = "flick"
	} else if note.is_critical {
		type_of_note = "crtcl"
	}

	for i, sprite_name in ["notes/notes_${type_of_note}_middle", "notes/notes_${type_of_note}_right", "notes/notes_${type_of_note}_left"] {
		mut note_sprite := &sprite.Sprite{origin: vector.centre, always_visible: true}
		note_sprite.textures << skin.get_texture(sprite_name)

		mut offset := 0.0

		if i == 1 {
			offset = 0.5
		} else if i == 2 {
			offset = -0.5
		}

		// SPECIAL FCUKIG HACK:
		if direction == 12 {
			note_sprite.color.r = 255
			note_sprite.color.g = 255
			note_sprite.color.b = 255
			note_sprite.textures[0] = skin.get_texture("notes/tex_hold_path")
			note.is_path = true
		}

		offset *= note.width

		//
		start_x := f64(f32(note.lane - 6) * 0.5) / 2.0 + (offset / 4.0)
		end_x := f64(f32(note.lane - 6) * 0.5) + offset / 2.0

		note_sprite.add_transform(
			typ: .move, 
			time: time.Time{note.time.start - preempt, note.time.end}, 
			before: [start_x, 50.0], after: [end_x, -6.5]
		)

		note_sprite.add_transform(typ: .move, time: time.Time{note.time.end, note.time.end + 100}, before: [end_x, -6.5], after: [end_x, -10.0])
		note_sprite.add_transform(typ: .scale, time: time.Time{note.time.start - preempt, note.time.end}, before: [0.4, 0.5], after: [1.0, 1.0])

		mut sprite_x_size := 0.5

		if i == 0 {
			sprite_x_size = note.width * 0.5
		}

		if direction == 10 {
			note_sprite.color.r = 255
			note_sprite.color.g = 0
			note_sprite.color.b = 0
		}

		if direction == 11 {
			note_sprite.color.r = 0
			note_sprite.color.g = 0
			note_sprite.color.b = 255
		}

		if direction == 12 {
			note_sprite.reset_size_based_on_texture(size: vector.Vector2{sprite_x_size, 10.0})
		} else {
			note_sprite.reset_size_based_on_texture(size: vector.Vector2{sprite_x_size, 2.0})
		}
		
		note_sprite.reset_time_based_on_transforms()
		note_sprite.reset_attributes_based_on_transforms()

		note.sprites << note_sprite

	}

	// Flicks
	if note.is_flick {
		flick_size := int(math.clamp(math.round(note.width * 2), 1, 6))

		//
		start_x := f64(f32(note.lane - 6) * 0.5) / 2.0 + (0.0 / 4.0)
		end_x := f64(f32(note.lane - 6) * 0.5) + 0.0 / 2.0

		// Add kot
		mut kot_sprite := &sprite.Sprite{
			always_visible: true,
			textures: [skin.get_texture("notes/notes_flick_arrow_0${flick_size}")]
		}

		kot_sprite.add_transform(
			typ: .move, 
			time: time.Time{note.time.start - preempt, note.time.end}, 
			before: [start_x, 50.0], after: [end_x, -6.5]
		)

		kot_sprite.add_transform(typ: .move, time: time.Time{note.time.end, note.time.end + 100}, before: [end_x, -6.5], after: [end_x, -10.0])

		kot_sprite.angle = 180.0
		kot_sprite.z = 0.4

		kot_sprite.reset_size_based_on_texture(size: vector.Vector2{0.7, 1.0})
		kot_sprite.reset_time_based_on_transforms()
		kot_sprite.reset_attributes_based_on_transforms()

		note.sprites << kot_sprite
	}
	
}

pub fn (mut note NoteObjectSprite) update(time f64) {
	if time >= note.time.end && !note.finished && !note.is_path {
		unsafe {

			if note.is_critical {
				if note.is_flick {
					note_flick_critical.play_volume(note_volume)
				} else {
					note_critical.play_volume(note_volume)
				}
			} else {
				if note.is_flick {
					note_flick.play_volume(note_volume)
				} else {
					note_perfect.play_volume(note_volume)
				}
			}
			
		}

		note.finished = true
	}

	// Update sprite
	for mut sprite in note.sprites {
		sprite.update(time)
	}
}

pub fn (mut note NoteObjectSprite) draw(arg sprite.CommonSpriteArgument) {
	for mut sprite in note.sprites {
		// arg.ctx.draw_rect_filled(
		// 	f32(sprite.position.x), 
		// 	f32(sprite.position.y), 
		// 	f32(note.width * 0.5),
		// 	2, 
		// 	gx.blue
		// )

		// println(*sprite)

		sprite.draw(arg)


		// arg.ctx.draw_image(
		// 	f32(f32(note.lane - 6 + note.width / 2.0) * 0.5 - (0.5 * note.width)), 
		// 	50.0 - (50 * f32((arg.time - note.time.start - 1000.0) / 1000.0)), 
		// 	f32(0.5 * note.width), 
		// 	2, 
		// 	sprite.textures[0]
		// )
	}
}
