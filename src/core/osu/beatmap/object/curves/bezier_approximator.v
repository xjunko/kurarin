module curves

import sync
import framework.math.vector

const (
	_bezier_quantization    = 0.5
	_bezier_quantization_sq = _bezier_quantization * _bezier_quantization
)

pub struct ItemStack {
pub mut:
	items [][]vector.Vector2[f64]
	mutex &sync.RwMutex = sync.new_rwmutex()
}

pub fn (mut s ItemStack) push(t []vector.Vector2[f64]) {
	s.mutex.@lock()
	s.items << t
	s.mutex.unlock()
}

pub fn (mut s ItemStack) pop() []vector.Vector2[f64] {
	s.mutex.@lock()
	item := s.items[s.items.len - 1]
	s.items = s.items[0..s.items.len - 1]
	s.mutex.unlock()
	return item
}

pub fn (mut s ItemStack) count() int {
	return s.items.len
}

pub struct BezierApproximator {
pub mut:
	count              int
	control_points     []vector.Vector2[f64]
	subdivisionbuffer1 []vector.Vector2[f64]
	subdivisionbuffer2 []vector.Vector2[f64]
}

pub fn make_bezier_approximator(control_points []vector.Vector2[f64]) &BezierApproximator {
	return &BezierApproximator{
		count: control_points.len
		control_points: control_points
		subdivisionbuffer1: []vector.Vector2[f64]{len: control_points.len}
		subdivisionbuffer2: []vector.Vector2[f64]{len: control_points.len * 2 - 1}
	}
}

pub fn is_flat_enough(control_points []vector.Vector2[f64]) bool {
	for i := 1; i < control_points.len - 1; i++ {
		if control_points[i - 1].sub(control_points[i].scale(2)).add(control_points[i + 1]).length_squared() > curves._bezier_quantization_sq {
			return false
		}
	}

	return true
}

pub fn (mut approximator BezierApproximator) subdivide(control_points []vector.Vector2[f64], mut l []vector.Vector2[f64], mut r []vector.Vector2[f64]) {
	unsafe {
		mut midpoints := &approximator.subdivisionbuffer1

		for i := 0; i < approximator.count; i++ {
			midpoints[i] = control_points[i]
		}

		for i := 0; i < approximator.count; i++ {
			l[i] = midpoints[0]
			r[approximator.count - i - 1] = midpoints[approximator.count - i - 1]

			for j := 0; j < approximator.count - i - 1; j++ {
				midpoints[j] = (midpoints[j].add(midpoints[j + 1])).scale(0.5)
			}
		}
	}
}

pub fn (mut approximator BezierApproximator) approximate(control_points []vector.Vector2[f64], mut output []vector.Vector2[f64]) {
	mut l := &approximator.subdivisionbuffer2
	mut r := &approximator.subdivisionbuffer1

	approximator.subdivide(control_points, mut l, mut r)

	unsafe {
		for i := 0; i < approximator.count - 1; i++ {
			l[approximator.count + i] = r[i + 1]
		}

		output << control_points[0]

		for i := 1; i < approximator.count - 1; i++ {
			index := 2 * i
			p := (l[index - 1].add(l[index].scale(2.0)).add(l[index + 1])).scale(0.25)
			output << p
		}
	}
}

pub fn (mut approximator BezierApproximator) create_bezier() []vector.Vector2[f64] {
	mut output := []vector.Vector2[f64]{}

	if approximator.count == 0 {
		return output
	}

	mut to_flatten := &ItemStack{}
	mut free_buffers := &ItemStack{}

	mut n_cp := approximator.control_points.clone()
	to_flatten.push(n_cp)

	mut left_child := &approximator.subdivisionbuffer2

	for to_flatten.count() > 0 {
		mut parent := to_flatten.pop()

		if is_flat_enough(parent) {
			approximator.approximate(parent, mut &output)
			free_buffers.push(parent)
			continue
		}

		mut right_child := []vector.Vector2[f64]{}

		if free_buffers.count() > 0 {
			right_child = free_buffers.pop()
		} else {
			right_child = []vector.Vector2[f64]{len: approximator.count}
		}

		approximator.subdivide(parent, mut left_child, mut right_child)

		unsafe {
			for i := 0; i < approximator.count; i++ {
				parent[i] = left_child[i]
			}
		}
		to_flatten.push(right_child)
		to_flatten.push(parent)
	}

	output << approximator.control_points[approximator.count - 1]

	return output
}
