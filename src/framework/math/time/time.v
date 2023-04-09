module time

import math

pub struct Time {
pub mut:
	start f64
	end   f64
}

pub fn (time &Time) duration() f64 {
	return math.max(time.end - time.start, 1.0)
}
