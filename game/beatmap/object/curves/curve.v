module curves

import framework.math.vector

pub interface Curve {
	point_at(f64) vector.Vector2
	get_length() f64
}