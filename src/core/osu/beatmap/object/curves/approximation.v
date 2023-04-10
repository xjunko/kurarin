module curves

import framework.math.vector

pub fn approximate_circular_arc(p1 vector.Vector2, p2 vector.Vector2, p3 vector.Vector2, detail f64) []Linear {
	arc := make_circ_arc(p1, p2, p3)

	if arc.unstable {
		return [*make_linear(p1, p2), *make_linear(p2, p3)]
	}

	segments := int(f64(arc.r) * arc.total_angle * detail)
	mut lines := []Linear{len: segments}

	for i := 0; i < segments; i++ {
		lines[i] = make_linear(arc.point_at(f64(i) / f64(segments)), arc.point_at(f64(i + 1) / f64(segments)))
	}

	return lines
}

pub fn approximate_catmullrom(points []vector.Vector2, detail int) []Linear {
	catmull := make_catmull(points)

	mut lines := []Linear{len: detail}

	for i := 0; i < detail; i++ {
		lines[i] = make_linear(catmull.point_at(f64(i) / f64(detail)), catmull.point_at(f64(i + 1) / f64(detail)))
	}

	return lines
}

pub fn approximate_bezier(points []vector.Vector2) []Linear {
	mut bezier_approx := make_bezier_approximator(points)
	mut extracted := bezier_approx.create_bezier()

	mut lines := []Linear{len: extracted.len - 1}

	for i := 0; i < lines.len; i++ {
		lines[i] = make_linear(extracted[i], extracted[i + 1])
	}

	return lines
}
