module curves

import framework.math.vector { Vector2 }


// import math

const (
	bezier_tolerance = f64(0.25)
)

pub fn bezier_is_flat_enough(points []Vector2) bool {
	for i := 1; i < points.len - 1; i++ {
		tmp := points[i - 1].sub_(points[i].multiply_(2)).add_(points[i + 1])

		if tmp.length_squared() > bezier_tolerance {
			return false
		}
	}

	return true
}


pub fn bezier_subdivide(points []Vector2, mut l []Vector2, mut r []Vector2, mut subdivision_buffer []Vector2, count int) {
	mut midpoints := unsafe { subdivision_buffer }


	for i := 0; i < count; i++ {
		unsafe {
			midpoints[i] = points[i]
		}
	}

	for i := 0; i < count; i++ {
		unsafe {
			l[i] = midpoints[0]
			r[count - i - 1] = midpoints[count - i - 1]
		}

		for j := 0; j < count - i - 1; j++ {
			unsafe {
				midpoints[j] = midpoints[j].add_(midpoints[j + 1])
				midpoints[j] = midpoints[j].divide_(2)
			}
		}
	}
}

pub fn bezier_aproximate(points []Vector2, mut output []Vector2, mut subdivision_buffer1 []Vector2, mut subdivision_buffer2 []Vector2, count int) {
	mut l := unsafe { subdivision_buffer1 }
	mut r := unsafe { subdivision_buffer2 } 

	bezier_subdivide(points, mut l, mut r, mut subdivision_buffer1, count)
	
	for i := 0; i < count - 1; i++ {
		for l.len < count + i + 1 {
			l << Vector2{}
		}
		// Fill
		unsafe {	
			l[count + i] = r[i + 1]
		}
	}

	output << points[0]

	for i := 1; i < count - 1; i++ {
		unsafe {
			index := 2 * i
			mut p := l[index].add_(l[index].multiply_(2)).add_(l[index + 1])
			// mut p := l[index].multiply_(2).add_(l[index - 1]).add_(l[index + 1])
			p = p.multiply_(0.25)
			output << p
		}
	}

	
}

pub fn create_bezier(control_points []Vector2) []Vector2 {
	mut output := []Vector2{}
	mut n := control_points.len - 1

	if n < 0 {
		return output
	}

	mut to_flatten := [][]Vector2{}
	mut free_buffer := [][]Vector2{}

	// copy
	mut points := control_points.clone()

	//
	to_flatten << points

	//
	mut subdivision_buffer1 := []Vector2{len: n + 1}
	mut subdivision_buffer2 := []Vector2{len: n * 2 + 1}
	mut left_child := subdivision_buffer2.clone()

	for to_flatten.len > 0 {
		mut parent := to_flatten.pop()

		if bezier_is_flat_enough(parent) {
			bezier_aproximate(parent, mut output, mut subdivision_buffer1, mut subdivision_buffer2, n + 1)
			free_buffer << parent
			continue
		}

		mut right_child := []Vector2{}
		if free_buffer.len > 0 {
			right_child = free_buffer.pop()
		} else {
			right_child = []Vector2{len: n + 1}
		}
		
		bezier_subdivide(parent, mut left_child, mut right_child, mut subdivision_buffer1, n + 1)



		for i := 0; i < n + 1; i++ {
			parent[i] = left_child[i]
		}

		to_flatten << right_child
		to_flatten << parent
	}
	output << control_points[n]

	return output
}