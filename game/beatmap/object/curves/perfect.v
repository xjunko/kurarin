module curves
import framework.math.vector { Vector2 }

import math

/*
const (
	perfect_tolerance = f64(0.1)
)

pub fn almost_equal(x f64, y f64, delta f64) bool {
	return math.abs(x-y) < delta
}

pub fn float_equal(val1 f64, val2 f64) bool {
	return almost_equal(val1, val2, f64(1e-3))
}


pub fn circular_arc_properties(points []Vector2) ?(f64, f64, f64, f64, Vector2) {
	mut a := points[0]
	mut b := points[1]
	mut c := points[2]

	if float_equal(0, (b.y - a.y) * (c.x - a.x) - (b.x - a.x) * (c.y - a.y)) {
		return none
	}

	d := 2 * (a.x * b.sub_(c).y + b.x * c.sub_(a).y + c.x * a.sub_(b).y)
	asq := a.length_squared()
	bsq := b.length_squared()
	csq := c.length_squared()

	centre := Vector2{
		asq * b.sub_(c).y + bsq * c.sub_(a).y + csq * a.sub_(b).y,
		asq * c.sub_(b).x + bsq * a.sub_(c).x + csq * b.sub_(a).x
	}.divide_(d)

	da := a.sub_(centre)
	dc := c.sub_(centre)

	r := da.length()
	mut theta_start := math.atan2(da.y, da.x)
	mut theta_end := math.atan2(dc.y, dc.x)

	for theta_end < theta_start {
		theta_end += 2 * math.pi
	}

	mut dir := 1
	mut theta_range := theta_end - theta_start
	mut orthoc := c.sub_(a)
	orthoc = Vector2{orthoc.y, -orthoc.x}

	if orthoc.multiply_vector(b.sub_(a)) < 0 {
		dir = -dir
		theta_range = 2 * math.pi - theta_range
	}

	return theta_start, theta_range, dir, r, centre
}

pub fn create_perfect(points []Vector2) []Vector2 {
	theta_start, theta_range, direction, radius, _ := circular_arc_properties(points) or {
		println("> THE FUCK")
		return []Vector2{}
	}

	amount_points := if 2 * radius <= perfect_tolerance { 2 } else { math.max(2, math.ceil(theta_range / (2 * math.acos(1 - perfect_tolerance / radius)))) }
	mut output := []Vector2{}

	for i := 0; i < amount_points; i++ {
		fract := i / (amount_points - 1)
		theta := theta_start + direction * fract * theta_range
		o := Vector2{math.cos(theta), math.sin(theta)}.scale_(radius)
		output << o
	}
	return output
}
*/



pub fn circle_t_at(pt Vector2, centre Vector2) f64 {
	return math.atan2(pt.y - centre.y, pt.x - centre.x)
}

pub fn circle_through_points(control_points []Vector2) (Vector2, f64, f64, f64) {
	a := control_points[0]								 
	b := control_points[1]
	c := control_points[2]

	d := 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
	amagsq := a.length_squared()
	bmagsq := b.length_squared()
	cmagsq := c.length_squared()

	centre := Vector2{
		(amagsq * (b.y - c.y) + bmagsq * (c.y - a.y) + cmagsq * (a.y - b.y)) / d,
		(amagsq * (c.x - b.x) + bmagsq * (a.x - c.x) + cmagsq * (b.x - a.x)) / d
	}
	radius := a.distance(centre)

	mut t_initial := circle_t_at(a, centre)
	mut t_mid := circle_t_at(b, centre)
	mut t_final := circle_t_at(c, centre)

	for t_mid < t_initial {
		t_mid += 2 * math.pi
	}

	for t_final < t_initial {
		t_final += 2 * math.pi
	}

	return centre, radius, t_initial, t_final
}

pub fn circle_point(centre Vector2, radius f64, t f64) Vector2 {
	return Vector2{
		math.cos(t) * radius,
		math.sin(t) * radius
	}.add_(centre)
}


// TODO: checks
pub fn create_perfect(control_points []Vector2) []Vector2 {
	mut output := []Vector2{}
	mut centre := Vector2{}
	mut radius := f64(0)
	mut t_initial := f64(0)
	mut t_final := f64(0)
	tolerance := f64(0.125)

	centre, radius, t_initial, t_final = circle_through_points(control_points)
	output << control_points[0]
	curve_length := math.abs((t_final - t_initial) * radius)
	segments := int(curve_length * tolerance)

	for i := 0; i < segments; i++ {
		progress := f64(i) / f64(segments)
		t := t_final * progress + t_initial * (1 - progress)

		new_point := circle_point(centre, radius, t)
		output << new_point
	}
	
	output << control_points[2]

	return output
}
