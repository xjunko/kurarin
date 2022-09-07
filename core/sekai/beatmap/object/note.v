module object

// import gx

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

pub struct NoteObject {
	BaseNoteObject

	mut:
		finished bool

		is_flick bool
		is_critical bool

	pub mut:
		sprites []&sprite.Sprite
}

pub fn (mut note NoteObject) initialize(is_flick bool, is_critical bool) {
	// note.lane = 6
	// note.width = 5.0
	note.is_flick = is_flick
	note.is_critical = is_critical
	preempt := 700.0

	for i, sprite_name in ["notes/notes_normal_middle", "notes/notes_normal_right", "notes/notes_normal_left"] {
		mut note_sprite := &sprite.Sprite{origin: vector.centre, always_visible: true}
		note_sprite.textures << skin.get_texture(sprite_name)

		mut offset := 0.0

		if i == 1 {
			offset = 0.5
		} else if i == 2 {
			offset = -0.5
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

		if note.is_flick {
			// Red
			note_sprite.add_transform(typ: .color, time: time.Time{note.time.start, note.time.start}, before: [255.0, 0.0, 0.0])
		} else if note.is_critical {
			// Yellow
			note_sprite.add_transform(typ: .color, time: time.Time{note.time.start, note.time.start}, before: [255.0, 255.0, 0.0])
		}

		note_sprite.reset_size_based_on_texture(size: vector.Vector2{sprite_x_size, 2.0})
		note_sprite.reset_time_based_on_transforms()
		note_sprite.reset_attributes_based_on_transforms()

		note.sprites << note_sprite

	}

	// Flicks
	if note.is_flick {
		//
		start_x := f64(f32(note.lane - 6) * 0.5) / 2.0 + (0.0 / 4.0)
		end_x := f64(f32(note.lane - 6) * 0.5) + 0.0 / 2.0

		// Add kot
		mut kot_sprite := &sprite.Sprite{
			always_visible: true,
			textures: [skin.get_texture("notes/kot")]
		}

		kot_sprite.add_transform(
			typ: .move, 
			time: time.Time{note.time.start - preempt, note.time.end}, 
			before: [start_x, 60.0], after: [end_x, -7.0]
		)

		kot_sprite.add_transform(typ: .move, time: time.Time{note.time.end, note.time.end + 100}, before: [end_x, -7.0], after: [end_x, -10.5])

		kot_sprite.angle = 180.0

		kot_sprite.reset_size_based_on_texture(size: vector.Vector2{0.5, 2.0})
		kot_sprite.reset_time_based_on_transforms()
		kot_sprite.reset_attributes_based_on_transforms()

		note.sprites << kot_sprite
	}
	
}

pub fn (mut note NoteObject) update(time f64) {
	if time >= note.time.end && !note.finished {
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

pub fn (mut note NoteObject) draw(arg sprite.CommonSpriteArgument) {
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
