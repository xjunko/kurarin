module curves

import framework.math.vector { Vector2 }

pub fn create_linear(control_points []Vector2) []Vector2 {
	mut output := []Vector2{}

	for i := 1; i < control_points.len; i++ {
		l1 := control_points[i - 1]
		l2 := control_points[i]
		
		mut segments := 1

		for j := 0; j <= segments; j++ {
			v1 := l1.add_(l2.sub_(l1).multiply_(j / segments))
			output << v1
		}
	}

	return output
}