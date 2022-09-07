module object

import framework.math.time

pub struct BaseNoteObject {
	pub mut:
		time time.Time
		tick f64
		lane f64
		width f64
		typ int
}