module curves

import math
import framework.math.vector

pub struct CircArc {
	pub mut:
		p1 vector.Vector2
		p2 vector.Vector2
		p3 vector.Vector2
		centre vector.Vector2
		start_angle f64
		total_angle f64
		r f64
		dir f64
}

pub fn make_circ_arc(p1 vector.Vector2, p2 vector.Vector2, p3 vector.Vector2) &CircArc {
	mut arc := &CircArc{p1: p1, p2: p2, p3: p3}

	asq := p2.distance_squared(p3)
	bsq := p1.distance_squared(p3)
	csq := p1.distance_squared(p2)

	s := asq * (bsq + csq - asq)
	t := bsq * (asq + csq - bsq)
	u := csq * (asq + bsq - csq)

	sum := s + t + u

	centre := p1.scale(s).add(p2.scale(t)).add(p3.scale(u)).scale(f64(1) / sum)

	da := p1.sub(centre)
	dc := p3.sub(centre)

	r := da.length()

	mut start := math.atan2(da.y, da.x)
	mut end := math.atan2(dc.y, dc.x)

	for end < start {
		end += 2.0 * math.pi
	}

	mut dir := 1.0
	mut total_angle := end - start

	mut atoc := p3.sub(p1)
	atoc = vector.Vector2{atoc.y, -atoc.x}

	if atoc.dot(p2.sub(p1)) < 0 {
		dir = -dir
		total_angle = 2.0 * math.pi - total_angle
	}

	// HOLY FUCKING SHIT I HATE MATH SO MUCh
	// IM NOT EVEN DOING THE MATH BUT HOLY
	arc.total_angle = total_angle
	arc.dir = dir
	arc.start_angle = start
	arc.centre = centre
	arc.r = r

	return arc
}

pub fn (circ CircArc) point_at(time f64) vector.Vector2 {
	return vector.new_vec_rad(circ.start_angle + circ.dir * time * circ.total_angle, circ.r).add(circ.centre)
}

pub fn (circ CircArc) get_length() f64 {
	return circ.r * circ.total_angle
}