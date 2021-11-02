module vector

import math

pub struct Vector2 {
	pub mut:
		x f64
		y f64
}

//
pub fn (vector &Vector2) len() f64 {
	return math.sqrt(
		vector.x * vector.x + vector.y * vector.y
	)
}

pub fn (vector &Vector2) equal(o Vector2) bool {
	return (vector.x == o.x && vector.y == o.y)
}

// Operators
pub fn (mut vector Vector2) set(nx f64, ny f64) Vector2 {
	vector.x = nx
	vector.y = ny

	return vector
}

pub fn (vector &Vector2) middle_point(o Vector2) Vector2 {
	return Vector2{
		(vector.x + o.x)/2,
		(vector.y + o.y)/2
	}
}

pub fn (mut vector Vector2) scale(s f64) Vector2 {
	vector.x *= s
	vector.y *= s

	return vector
}

pub fn (mut vector Vector2) add(nx f64, ny f64) Vector2 {
	vector.x += nx
	vector.y += ny

	return vector
}

pub fn (mut vector Vector2) add_vec(o Vector2) Vector2 {
	vector.x += o.x
	vector.y += o.y

	return vector
}

pub fn (mut vector Vector2) sub(o Vector2) Vector2 {
	vector.x -= o.x
	vector.y -= o.y

	return vector
}

pub fn (mut vector Vector2) nor(o Vector2) Vector2 {
	nx := -vector.y
	ny := vector.x
	vector.x = nx
	vector.y = ny

	return vector
}

pub fn (mut vector Vector2) normalize() Vector2 {
	len := vector.len()
	vector.x /= len
	vector.y /= len

	return vector
}

pub fn (vector &Vector2) copy() Vector2 {
	return Vector2{vector.x, vector.y}
}


// from danser
pub fn (v &Vector2) lerp(v1 Vector2, t f64) Vector2 {
	return Vector2{
		(v1.x - v.x) * t + v.x,
		(v1.y - v.x) * t + v.y
	}
}

pub fn (v &Vector2) distance(v1 Vector2) f64 {
	x := v1.x - v.x
	y := v1.y - v.y

	return math.sqrt(x*x + y*y)
}

pub fn (v &Vector2) angle_rv(v1 Vector2) f64 {
	return math.atan(v.y-v1.y + v.x-v1.x)
}