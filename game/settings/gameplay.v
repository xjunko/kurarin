module settings

pub struct Gameplay {
	pub mut:
		playfield Playfield
		cursor Cursor
		hitobjects HitObjects
		overlay Overlay
}

pub struct Playfield {
	pub mut:
		objects_visible bool
		lead_in_time f64

		background Background
}

pub struct Background {
	pub mut:
		enable_storyboard bool
		enable_video      bool
		background_dim    int
}

pub struct Cursor {
	pub mut:
		visible bool
		size f64
		style f64
		trail_length int
}

pub struct HitObjects {
	pub mut:
		disable_hitobjects bool

		scale_to_beat bool

		// dumbass shit
		rainbow_hitcircle bool
		rainbow_slider    bool

		// fallback
		old_slider bool
}

pub struct Overlay {
	pub mut:
		info bool // Score, Combo
		visualizer bool
}

// Factory 
pub fn make_gameplay_settings() Gameplay {
	mut gameplay_ := Gameplay{
		playfield: Playfield{
			objects_visible: true,
			lead_in_time: 3.0,

			background: Background{
				enable_storyboard: true,
				enable_video: true,
				background_dim: 100
			}
		}

		cursor: Cursor{
			visible: true,
			size: 0.75,
			style: 0,
			trail_length: 1000
		}

		hitobjects: HitObjects{
			disable_hitobjects: false,
			scale_to_beat: false,
			rainbow_hitcircle: false,
			rainbow_slider: false,
			old_slider: false,
		},

		overlay: Overlay{
			visualizer: true,
			info: true
		}

	}

	return gameplay_
}
