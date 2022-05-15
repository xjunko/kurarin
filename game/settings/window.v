module settings

// TODO: split them up into their own type
pub struct Window {
	pub mut:
		speed  f64
		pitch  f64
		fps    f64 // Update tick

		// Volumes
		audio_volume f64
		effect_volume f64
		overall_volume f64
}

// Factory
pub fn make_window_settings() Window {
	mut window_ := Window{
		speed: 1.0,
		pitch: 1.0,
		fps: 480,
		audio_volume: 50,
		effect_volume: 100,
		overall_volume: 50,
	}

	return window_
}
