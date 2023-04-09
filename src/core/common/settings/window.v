module settings

pub struct Window {
pub mut:
	width  f64
	height f64
	fps    f64
	speed  f64
}

// Factory
pub fn make_window_settings() Window {
	mut window_ := Window{
		width: 1280
		height: 720
		fps: 480
		speed: 1.0
	}

	return window_
}
