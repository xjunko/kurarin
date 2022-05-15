module ruleset

pub enum HitResult {
	ignore
	slider_miss
	miss
	hit50
	hit100
	hit300
	slider_start
	slider_point
	slider_repeat
	slider_end
	spinner_spin
	spinner_points
	spinner_bonus
	mu_addition
	katu_addition
	geki_addition
}

pub fn (result HitResult) get_value() i64 {
	match result {
		.hit50 { return 50 }
		.hit100 { return 100 }
		.hit300 { return 300 }
		.slider_start, .slider_repeat, .slider_end { return 30 }
		.slider_point { return 100 }
		.spinner_bonus { return 1100 }
		
		else {}
	}

	return 0
}