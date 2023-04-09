module curves

import framework.math.vector

pub struct Linear {
	pub mut:
		p1 vector.Vector2
		p2 vector.Vector2
}

pub fn make_linear(p1 vector.Vector2, p2 vector.Vector2) &Linear {
	mut linear := &Linear{p1, p2}
	return linear
}

pub fn (ln Linear) point_at(time f64) vector.Vector2 {
	return ln.p2.sub(ln.p1).scale(time).add(ln.p1)
}

pub fn (ln Linear) get_start_angle() f64 {
	return ln.p1.angle_rv(ln.p2)
}

pub fn (ln Linear) get_end_angle() f64 {
	return ln.p2.angle_rv(ln.p1)
}

pub fn (ln Linear) get_length() f64 {
	return ln.p1.distance(ln.p2)
}