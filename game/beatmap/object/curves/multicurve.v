module curves

import math
import framework.math.vector

const (
	min_part_width = f64(0.0001)
)

pub struct MultiCurve {
	pub mut:
		sections []f64
		lines []Linear
		length f64
		first_point vector.Vector2
}

pub fn (mut m_curve MultiCurve) point_at(time f64) vector.Vector2 {
	if m_curve.lines.len == 0 || m_curve.length == 0.0 {
		return m_curve.first_point
	}

	desired_width := f64(m_curve.length * math.clamp(time), 0.0, 1.0)

	without_first := m_curve.sections[1 ..]
	mut index := m_curve.lines.len

	for i, value in without_first {
		if value > desired_width {
			index = i
			break
		}
	}

	// panic("Lines: ${m_curve.lines.len} | Length: ${m_curve.length} | Index: ${index}")

	index = math.min<int>(index, m_curve.lines.len - 1)

	if m_curve.sections[index + 1] - m_curve.sections[index] == 0.0 {
		return m_curve.lines[index].p1
	}

	return m_curve.lines[index].point_at((desired_width - m_curve.sections[index]) / (m_curve.sections[index+1] - m_curve.sections[index]))
	
}

pub fn (mut m_curve MultiCurve) get_length() f64 {
	return m_curve.length
}

pub fn (mut m_curve MultiCurve) get_start_angle() f64 {
	if m_curve.lines.len > 0 {
		return m_curve.lines[0].get_start_angle()
	}

	return 0.0
}

pub fn (mut m_curve MultiCurve) get_end_angle() f64 {
	if m_curve.lines.len > 0 {
		return m_curve.lines[m_curve.lines.len - 1].get_end_angle()
	}

	return 0.0
}

pub fn (mut m_curve MultiCurve) get_lines() []Linear {
	return m_curve.lines
}

pub fn new_multi_curve(typ string, points []vector.Vector2) &MultiCurve {
	mut lines := []Linear{}

	match typ {
		"P" { lines = process_perfect(points) }
		"L" { lines = process_linear(points) }
		"B" { lines = process_bezier(points) }
		"C" { lines = process_catmull(points) }
		else {}
	}

	mut length := f64(0.0)

	for l in lines {
		length += l.get_length()
	}

	mut first_point := points[0]

	mut sections := []f64{len: lines.len + 1}
	mut prev := f64(0.0)

	for i := 0; i < lines.len; i++ {
		prev += lines[i].get_length()
		sections[i + 1] = prev
	}

	return &MultiCurve{sections, lines, length, first_point}
}

pub fn new_multi_curve_t(typ string, points []vector.Vector2, desired_length f64) &MultiCurve {
	mut m_curve := new_multi_curve(typ, points)

	if m_curve.length > 0 {
		mut diff := f64(m_curve.length) - desired_length

		for m_curve.lines.len > 0 {
			mut line := m_curve.lines[m_curve.lines.len - 1]

			if line.get_length() > diff + min_part_width {
				if !line.p1.equal(line.p2) {
					pt := line.point_at((line.get_length() - f64(diff)) / line.get_length())
					m_curve.lines[m_curve.lines.len - 1] = make_linear(line.p1, pt)
				}

				break
			}

			diff -= line.get_length()
			m_curve.lines = m_curve.lines[.. m_curve.lines.len - 1]
		}
	}

	m_curve.length = 0.0

	for line in m_curve.lines {
		m_curve.length += line.get_length()
	}

	m_curve.sections = []f64{len: m_curve.lines.len + 1}
	mut prev := f64(0.0)

	for i := 0; i < m_curve.lines.len; i++ {
		prev += m_curve.lines[i].get_length()
		m_curve.sections[i + 1] = prev
	}

	return m_curve
}

pub fn process_perfect(points []vector.Vector2) []Linear {
	if points.len > 3 {
		return process_bezier(points)
	} else if points.len < 3 || vector.is_straight_line(points[0], points[1], points[2]) {
		return process_linear(points)
	}

	return approximate_circular_arc(points[0], points[1], points[2], 0.125)
}

pub fn process_linear(points []vector.Vector2) []Linear {
	mut lines := []Linear{}

	for i := 0; i < points.len - 1; i++ {
		if points[i].equal(points[i + 1]) { // Skip red anchors, legacy shit.
			continue
		}

		lines << make_linear(points[i], points[i+1])
	}

	return lines
}

pub fn process_bezier(points []vector.Vector2) []Linear {
	mut last_index := 0
	mut lines := []Linear{}

	for i := 0; i < points.len; i++ {
		// FIXME: THis shits fucked
		multi := i < points.len - 2 && points[i].equal(points[i + 1])

		if multi || i == points.len - 1 {
			sub_points := points[int(last_index) .. int(i + 1)]

			if sub_points.len == 2 {
				lines << make_linear(sub_points[0], sub_points[1])
			} else {
				lines << approximate_bezier(sub_points)
			}

			if multi {
				i++
			}

			last_index = i
		}
	}

	return lines
}

pub fn process_catmull(points []vector.Vector2) []Linear {
	mut lines := []Linear{}

	for i := 0; i < points.len - 1; i++ {
		mut p1 := vector.Vector2{}
		mut p2 := vector.Vector2{}
		mut p3 := vector.Vector2{}
		mut p4 := vector.Vector2{}

		if i - 1 >= 0 {
			p1 = points[i - 1]
		} else {
			p1 = points[i]
		}

		p2 = points[i]

		if i + 1 < points.len {
			p3 = points[i + 1]
		} else {
			p3 = p2.add(p2.sub(p1))
		}

		if i + 2 < points.len {
			p4 = points[i + 2]
		} else {
			p4 = p3.add(p3.sub(p2))
		}

		lines << approximate_catmullrom([p1, p2, p3, p4], 50)
	}

	return lines
}