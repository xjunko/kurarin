module curves

import framework.math.vector { Vector2 }

pub struct Linear {
	pub mut:
		p1 Vector2
		p2 Vector2
}

pub fn (ln Linear) point_at(t f64) Vector2 {
	return ln.p1.lerp(ln.p2, t)
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