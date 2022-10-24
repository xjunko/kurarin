module object

import framework.math.time
import framework.graphic.sprite

pub struct BaseNoteObject {
	pub mut:
		time time.Time
		tick f64
		lane f64
		width f64
		typ int

		// Internal repr
		is_critical bool
		is_flick bool
		is_slider_start bool
		is_slider_path bool
		is_slider_end bool
}

// HACK: headache
pub struct NoteObject {
	BaseNoteObject
}

pub struct FlickObject {
	BaseNoteObject

	pub mut:
		direction int
}

pub struct SliderObject {
	BaseNoteObject

	pub mut:
		start NoteObject
		end   NoteObject
		ticks []NoteObject
}

// Interface
pub interface INoteObject {
	mut:
		object NoteObject

		// time time.Time
		// tick f64
		// lane f64
		// width f64
		// typ  int

		// is_critical bool
		// is_flick bool
		// is_slider_start bool
		// is_slider_path bool
		// is_slider_end bool


		update(f64)
		draw(sprite.CommonSpriteArgument)
		initialize(bool, bool, int)
}