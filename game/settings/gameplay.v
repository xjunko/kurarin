module settings

pub struct Gameplay {
	pub mut:
		global_offset  f64
		lead_in_time   f64
		background_dim int

		disable_hitsound   bool
		disable_hitobject  bool
		disable_storyboard bool

		use_beatmap_hitsound bool

		disable_cursor     		 bool
		cursor_size        	     f64
		cursor_trail_update_rate f64
		cursor_trail_length      int
		cursor_style             f64

		auto_update_rate         f64
}

// Factory 
pub fn make_gameplay_settings() Gameplay {
	mut gameplay_ := Gameplay{
		global_offset: 0,
		lead_in_time: 3.0, // n Seconds
		background_dim: 100,

		disable_hitsound: false,
		disable_hitobject: false,
		disable_storyboard: false,

		use_beatmap_hitsound: false,

		disable_cursor: false,
		cursor_size: 0.75,
		cursor_trail_update_rate: 16.6667, // 60FPS delta
		cursor_trail_length: 1000, // Maximum length
		cursor_style: 2, // 0: Normal, 1: Particle (terrible), 2: Long (Like style 0 but the trail is smoother)

		auto_update_rate: 16.6667
	}

	return gameplay_
}
