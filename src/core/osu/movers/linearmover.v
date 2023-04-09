module movers

import framework.math.easing
import framework.math.vector

pub struct LinearMover {
	Mover
}

pub fn (linear &LinearMover) get_point_at(time f64) vector.Vector2 {
	t := linear.get_multiplier(time)
	return vector.Vector2{linear.start.x + (linear.end.x - linear.start.x) * t, linear.start.y +
		(linear.end.y - linear.start.y) * t}
}

pub fn (linear &LinearMover) get_multiplier(time f64) f64 {
	return easing.quad_out(time - linear.time.start, 0, 1.0, linear.time.duration())
}
