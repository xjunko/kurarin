module difficulty

import math

pub const (
	// explicit type
	hit_fade_in     = f64(400.0)
	hit_fade_out    = f64(240.0)
	hitable_range   = f64(400.0)
	/*
	ResultFadeIn  = f64(120.0)
	ResultFadeOut = f64(600.0)
	PostEmpt      = f64(500.0)
	*/
)

pub struct DifficultyInfo {
	pub mut:
		hpdrainrate f32
		circlesize f32
		overalldifficulty f32
		approachrate f32
		slidermultiplier f32
		slidertickrate f32

		//
		created bool
}

pub fn (mut diff_info DifficultyInfo) make_difficulty() Difficulty {
	if diff_info.created { panic("YOOO") }
	diff_info.created = true

	mut diff := Difficulty{}
	diff.hp = diff_info.hpdrainrate
	diff.cs = diff_info.circlesize
	diff.od = diff_info.overalldifficulty
	diff.ar = diff_info.approachrate
	diff.slider_multiplier = diff_info.slidermultiplier
	diff.slider_tick_rate = diff_info.slidertickrate
	diff.custom_speed = 1
	

	diff.calculate()
	return diff
}


pub struct Difficulty {
	pub mut:
		hp f32
		cs f32
		od f32
		ar f32

		slider_multiplier f32
		slider_tick_rate  f32

		preempt f32
		fadein  f32

		circleradius f32
		mods         int

		hit50  int
		hit100 int
		hit300 int
		hp_mod f32
		spinner_ratio f32
		speed f32

		real_ar f32
		real_od f32
		custom_speed f32

		//

		//
		calculated bool
}

pub fn (mut diff Difficulty) calculate() {
	mut hp, mut cs, mut od, mut ar := diff.hp, diff.cs, diff.od, diff.ar


	if (diff.mods & 2) == 2 {
		ar /= 2
		cs /= 2
		od /= 2
		hp /= 2
	}

	diff.hp_mod = hp
	diff.circleradius = calculate_difficulty(cs, 54.4, 32, 9.6) * 1.00041
	diff.preempt = f32(math.floor(calculate_difficulty(ar, 1800, 1200, 450)))
	diff.fadein = calculate_difficulty(ar, 1200, 800, 300)

	// hitwindow
	diff.hit50 = int(calculate_difficulty(od, 200, 150, 100))
	diff.hit100 = int(calculate_difficulty(od, 140, 100, 60))
	diff.hit300 = int(calculate_difficulty(od, 80, 50, 20))
	diff.spinner_ratio = calculate_difficulty(od, 3, 5, 7.5)
	diff.speed = 1.0 / diff.calculate_time(1)

	diff.real_ar = calculate_difficulty_from_rate(diff.calculate_time(diff.preempt), 1800, 1200, 450)
	diff.real_od = calculate_difficulty_from_rate(diff.calculate_time(diff.hit300), 80, 50, 20)

	// ayayayayayaya
	diff.calculated = true
}

pub fn (diff Difficulty) calculate_time(time f32) f32 {
	if (diff.mods & 64) == 64 {
		return time / (1.5 * diff.custom_speed)
	} else if (diff.mods & 256) == 256 {
		return time / (0.75 * diff.custom_speed)
	} else {
		return time / diff.custom_speed
	}
}

pub fn calculate_difficulty(diff f32, min f32, mid f32, max f32) f32 {
	if diff > 5 {
		return mid + (max - mid) * (diff - 5) / 5
	}

	if diff < 5 {
		return mid - (mid - min) * (5 - diff) / 5
	}

	return diff
}

pub fn calculate_difficulty_from_rate(rate f32, min f32, mid f32, max f32) f32 {
	min_step := (min - mid) / 5
	max_step := (mid - max) / 5

	if rate > mid {
		return -(rate - min) / min_step
	}

	return 5.0 - (rate - mid) / max_step
}