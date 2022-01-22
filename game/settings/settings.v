module settings

pub const (
	window = make_window_settings()
	gameplay = make_gameplay_settings()
)

// TODO: split them up into their own type
pub struct Window {
	pub mut:
		speed  f64
		fps    f64 // Update tick
		record bool
		record_fps f64 // Record tick 
}

pub struct Gameplay {
	pub mut:
		lead_in_time   f64
		background_dim int

		disable_hitsound   bool
		disable_hitobject  bool
		disable_storyboard bool

		disable_cursor     		 bool
		cursor_size        	     f64
		cursor_trail_update_rate f64
		cursor_trail_length      int
		cursor_style             f64

		auto_update_rate         f64
}

// Factory
pub fn make_window_settings() &Window {
	mut window_ := &Window{
		speed: 1.0,
		fps: 60,
		record: true,
		record_fps: 60
	}

	return window_
}

pub fn make_gameplay_settings() &Gameplay {
	mut gameplay_ := &Gameplay{
		lead_in_time: 3.0 * 1000.0, // n Seconds
		background_dim: 0,

		disable_hitsound: true, // Miniaudio doesnt work well rn so yea
		disable_hitobject: false,
		disable_storyboard: false,

		disable_cursor: false,
		cursor_size: 0.75,
		cursor_trail_update_rate: 16.6667, // 60FPS delta
		cursor_trail_length: 1000, // Maximum length
		cursor_style: 2, // 0: Normal, 1: Particle (terrible), 2: Long (bootleg style 0)

		auto_update_rate: 16.6667
	}

	return gameplay_
}
