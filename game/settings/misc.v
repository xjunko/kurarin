module settings


// Put dumb shit in here
pub struct Miscellaneous {
	pub mut:
		rainbow_hitcircle  bool
		rainbow_slider     bool
}

pub fn make_miscellaneous_settings() Miscellaneous {
	mut misc := Miscellaneous{
		rainbow_hitcircle: false,
		rainbow_slider: false
	}

	return misc
}