module difficulty

pub const (
	hit_fade_in = 400.0
	hit_fade_out = 240.0
	hit_range = 400.0
)

pub struct Difficulty {
	pub mut:
		hp f64 [HPDrainRate]
		cs f64 [CircleSize]
		od f64 [OverallDifficulty]
		ar f64 [ApproachRate]
		slider_multiplier f64 [SliderMultiplier]
		slider_tick_rate  f64 [SliderTickRate]

		// Actual values
		hit300 f64 [_SKIP]
		hit100 f64 [_SKIP]
		hit50  f64 [_SKIP]

		circle_radius f64 [_SKIP]
		preempt f64 [_SKIP]
		fade_in f64 [_SKIP]

		// 
		calculated bool [_SKIP]
}

pub fn (mut diff Difficulty) calculate() {
	if diff.calculated { return }

	diff.circle_radius = calculate_difficulty_rate(diff.cs, 54.4, 32.0, 9.6) * 1.00041

	diff.preempt = calculate_difficulty_rate(diff.ar, 1800.0, 1200.0, 450.0)

	diff.fade_in = calculate_difficulty_rate(diff.ar, 1200.0, 800.0, 300.0)

	diff.hit50 = calculate_difficulty_rate(diff.od, 200.0, 150.0, 100.0)
	diff.hit100 = calculate_difficulty_rate(diff.od, 140.0, 100.0, 60.0)
	diff.hit300 = calculate_difficulty_rate(diff.od, 80.0, 50.0, 20.0)

	// Done
	diff.calculated = true
}

//
pub fn calculate_difficulty_rate(_diff f64, min f64, mid f64, max f64) f64 {
	diff := f64(f32(_diff)) // WHAT: ?? this is from danser not sure what this does

	if diff > 5 {
		return mid + (max-mid)*(diff-5)/5
	}
	if diff < 5 {
		return mid - (mid-min)*(5-diff)/5
	}
	return mid
}

pub fn calculate_difficulty_from_rate(_rate f64, min f64, mid f64, max f64) f64 {
	rate := f64(f32(_rate)) // WHAT: ?? this is from danser not sure what this does

	min_step := (min - mid) / 5
	max_step := (mid - max) / 5

	if rate > mid {
		return -(rate - min) / min_step
	}

	return 5.0 - (rate-mid) / max_step
}
