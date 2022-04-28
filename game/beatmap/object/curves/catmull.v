module curves

import math
import framework.math.vector

pub struct Catmull {
	pub mut:
		points []vector.Vector2
		approx_length f64
}

pub fn make_catmull(points []vector.Vector2) &Catmull {
	if points.len != 4 {
		panic("Catmull only needs 4 points, but got ${points.len} instead.")
	}

	mut cum := &Catmull{points: points}
	point_length := math.ceil(points[1].distance(points[2]))

	for i := 1; i <= point_length; i++ {
		cum.approx_length += cum.point_at(f64(i)/f64(point_length)).distance(cum.point_at(f64(i-1)/point_length))
	}

	return cum
}

pub fn (cum Catmull) point_at(t f64) vector.Vector2 {
	return find_point(cum.points[0], cum.points[1], cum.points[2], cum.points[3], t)
}

pub fn find_point(vec1 vector.Vector2, vec2 vector.Vector2, vec3 vector.Vector2, vec4 vector.Vector2, t f64) vector.Vector2 {
	t2 := t * t
	t3 := t * t2

	// OH MY FUCKING GOD WTF IS THIS WIEKU???
	// https://github.com/Wieku/danser-go/blob/2b0ec47f1b93a338df37ece927743d3b92288cc0/framework/math/curves/catmull.go#L40
	return vector.Vector2{
		0.5*(2*vec2.x+(-vec1.x+vec3.x)*t+(2*vec1.x-5*vec2.x+4*vec3.x-vec4.x)*t2+(-vec1.x+3*vec2.x-3*vec3.x+vec4.x)*t3),
		0.5*(2*vec2.y+(-vec1.y+vec3.y)*t+(2*vec1.y-5*vec2.y+4*vec3.y-vec4.y)*t2+(-vec1.y+3*vec2.y-3*vec3.y+vec4.y)*t3)
	}
}

pub fn (cum Catmull) get_length() f64 {
	return cum.approx_length
}

pub fn (cum Catmull) get_start_angle() f64 {
	return cum.points[0].angle_rv(cum.point_at(1.0 / cum.approx_length))
}

pub fn (cum Catmull) get_end_angle() f64 {
	return cum.points[cum.points.len - 1].angle_rv(cum.point_at((cum.approx_length - 1.0) / cum.approx_length))
}