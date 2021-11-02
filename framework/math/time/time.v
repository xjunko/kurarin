module time

import math

pub struct Time {
	pub mut:
		start f64
		end   f64
}

pub fn (t Time) duration() f64 {
	return math.max(t.end - t.start, 1)
}