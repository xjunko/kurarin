module settings

pub struct Audio {
pub mut:
	global f64
	music  f64
	sample f64
	pitch  f64

	disable_samples        bool
	ignore_beatmap_samples bool
	ignore_beatmap_volume  bool
}

pub fn Audio.new() Audio {
	return Audio{
		global: 100
		music: 75
		sample: 75
		pitch: 1.0
		disable_samples: false
		ignore_beatmap_samples: false
		ignore_beatmap_volume: false
	}
}
