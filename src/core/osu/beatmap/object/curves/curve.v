module curves

import framework.math.vector

pub interface Curve {
	point_at(f64) vector.Vector2[f64]
	get_length() f64
	get_start_angle() f64
	get_end_angle() f64
}
