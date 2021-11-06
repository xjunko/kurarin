module curves
import math

import framework.math.vector { Vector2 }

pub fn is_straight_line(vectors []Vector2) bool {
	a := vectors[0]	
	b := vectors[1]
	c := vectors[2]
	return f64((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) == f64(0.0)
}

pub fn get_bezier(vectors []Vector2) []Vector2 {
	return create_bezier(vectors)
}

pub fn get_perfect(vectors []Vector2) []Vector2 {
	if is_straight_line(vectors) || vectors.len < 3 {
		return create_linear(vectors)
	} else if vectors.len > 3 {
		return create_bezier(vectors)
	} else {
		return create_perfect(vectors)
	}
}

pub fn get_linear(vectors []Vector2) []Vector2 {
	return create_linear(vectors)
}

pub fn get_catmull(vectors []Vector2) []Vector2 {
	return create_catmull(vectors)
}



pub fn normalize(value_ Vector2) Vector2 {
	mut value := value_
	mut val := f64(1.0) / math.sqrt((value.x * value.x) + (value.y + value.y))
	value.x *= val
	value.y *= val
	return value
}


pub fn distance(a Vector2, b Vector2) f64 {
	return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2))
}

pub fn adjust_curve(vectors []Vector2, expected_length f64) []Vector2 {
	min_segment_length := f64(0.0001)
	mut total := f64(0)
	mut path := vectors.clone()

	unsafe {
		vectors.free()
	}

	for i := 1; i < path.len; i++ {
		total = distance(path[i - 1], path[i])
	}

	mut excess := f64(total - expected_length)

	for path.len >= 2 {
		v2 := Vector2{path[path.len - 1].x, path[path.len - 1].y}
		v1 := Vector2{path[path.len - 2].x, path[path.len - 2].y}
		lsat_line_length := v1.distance(v2)

		if lsat_line_length > excess + min_segment_length {
			if !v2.equals(v1) {
				l := v1.add_(normalize(v2.sub_(v1))).multiply_((v2.sub_(v1)).length() - excess)
				path[path.len - 1].x = l.x
				path[path.len - 1].y = l.y
			}
			break
		}

		path = path[0 .. path.len - 1]
		excess -= lsat_line_length
	}
	
	return path
}


pub fn create_curve(typ string, vectors []Vector2, expected_length f64) []Vector2 {
	mut path := []Vector2{}

	match typ.to_lower() {
		"b" {
			path = get_bezier(vectors)
		}
		"l" {
			path = get_linear(vectors)
		}
		"c" {
			path = get_catmull(vectors)
		}
		"p" {
			path = get_perfect(vectors)
		}

		else { panic("WHAT: ${typ}") }
	}

	// path = adjust_curve(path, expected_length)

	return path
}