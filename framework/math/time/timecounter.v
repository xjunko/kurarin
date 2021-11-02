module time

import math
import time as time2

pub struct TimeCounter {
	pub mut:
		last  f64
		delta f64
		time  f64
		fps   f64

		//
		multiplier f64 = 1.0
}

pub fn (mut t TimeCounter) reset() {
	t.last = time2.ticks()
	t.time = 0
}

pub fn (mut t TimeCounter) tick() f64 {
	now := time2.ticks()
	last := t.last

	t.last = now
	t.delta = now - last
	t.time += t.delta * t.multiplier
	t.fps = math.min(1000 / t.delta, 1000)


	return t.time
}