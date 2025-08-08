module time

import math

pub struct Ticks {
	TimeCounter
mut:
	average f64
}

pub fn (mut ticks Ticks) tick() {
	if ticks.start_time == 0 {
		ticks.reset()
	}

	delta := ticks.TimeCounter.tick()

	if ticks.average == 0.0 {
		ticks.average = delta
	} else {
		rate := f64(1.0 - math.pow(0.5, delta / 100.0))
		ticks.average = ticks.average + (delta - ticks.average) * rate
	}
}

pub fn (mut ticks Ticks) get_average_delta() f64 {
	return ticks.average
}

pub fn (mut ticks Ticks) get_average_fps() f64 {
	return 1000.0 / ticks.get_average_delta()
}
