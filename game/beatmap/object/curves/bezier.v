module curves

import math
import framework.math.vector

pub struct Bezier {
	pub mut:
		points []vector.Vector2
		approx_length f64
		control_length f64
}

pub fn make_bezier(points []vector.Vector2) &Bezier {
	mut bezier := &Bezier{points: points}

	for i := 1; i < bezier.points.len; i++ {
		bezier.control_length += bezier.points[i].distance(bezier.points[i-1])
	}

	sections := math.ceil(bezier.control_length)
	
	mut previous := bezier.points[0]
	for i := 1; i <= sections; i++ {
		current := bezier.n_point_at(f64(i) / sections)
		bezier.approx_length += current.distance(previous)
		previous = current
	}
	return bezier
}

pub fn (bezier Bezier) n_point_at(time f64) vector.Vector2 {
	mut p := vector.Vector2{}
	n := bezier.points.len - 1

	for i := 0; i <= n; i++ {
		b := bernstein(i64(i), i64(n), time)
		p.x += bezier.points[i].x * b
		p.y += bezier.points[i].y * b
	}
	return p
}

pub fn (bezier Bezier) point_at(time f64) vector.Vector2 {
	desired_width := bezier.approx_length * time
	mut width := f64(0.0)
	mut c := f64(0.0)
	mut pos := bezier.points[0]
	
	for width < desired_width {
		pt := bezier.n_point_at(c)
		width += pt.distance(pos)
		if width > desired_width {
			return pos
		}
		pos = pt
		c += 1.0 / f64(bezier.points.len * 50 - 1)
	}
	return pos
}

pub fn (bezier Bezier) get_length() f64 {
	return bezier.approx_length
}

pub fn (bezier Bezier) get_start_angle() f64 {
	return bezier.points[0].angle_rv(bezier.point_at(1.0 / bezier.control_length))
}

pub fn (bezier Bezier) get_end_angle() f64 {
	return bezier.points[bezier.points.len - 1].angle_rv(bezier.point_at(1.0 - 1.0 / bezier.control_length))
}

// Utils ?
pub fn binomial_coeff(n i64, k i64) i64 {
	if k < 0 || k > n {
		return 0
	}

	if k == 0 || k == n {
		return 1
	}

	kk := math.min(k, n-k)
	mut c := i64(1)
	mut i := 0
	for ;i < kk; i++ {
		c = c * (n - i) / (i + 1)
	}

	return c
}

pub fn bernstein(i i64, n i64, time f64) f64 {
	return f64(binomial_coeff(n, i)) * math.pow(time, f64(i)) * math.pow(1.0 - time, f64(n - i))
}