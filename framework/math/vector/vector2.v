module vector

import math

pub struct Vector2 {
	pub mut:
		x f64
		y f64
}


// Factory
pub fn new_vec_rad(rad f64, length f64) Vector2 {
	return Vector2{
		math.cos(rad) * length,
		math.sin(rad) * length
	}
}

// Methods
pub fn (mut v Vector2) set(x f64, y f64) {
	v.x, v.y = x, y
}

pub fn (mut v Vector2) set_radian(rad f64, length f64) {
	v.x = math.cos(rad) * length
	v.y = math.sin(rad) * length
}

// Factory??
pub fn (v Vector2) add(v1 Vector2) Vector2 {
	return Vector2{
		v.x + v1.x,
		v.y + v1.y
	}
}

pub fn (v Vector2) add_normal(x f64, y f64) Vector2 {
	return Vector2{
		v.x + x,
		v.y + y
	}
}

pub fn (v Vector2) sub(v1 Vector2) Vector2 {
	return Vector2{
		v.x - v1.x,
		v.y - v1.y,
	}
}

pub fn (v Vector2) multiply(v1 Vector2) Vector2 {
	return Vector2{
		v.x * v1.x,
		v.y * v1.y,
	}
}

pub fn (v Vector2) middle(v1 Vector2) Vector2 {
	return Vector2{
		(v.x + v1.x) / 2,
		(v.y + v1.y) / 2
	}
}

pub fn (v Vector2) dot(v1 Vector2) f64 {
	return v.x * v1.x + v.y * v1.y
}

pub fn (v Vector2) distance(v1 Vector2) f64 {
	return math.sqrt(
		math.pow(v1.x - v.x, 2) +
		math.pow(v1.y - v.y, 2)
	)
}

pub fn (v Vector2) distance_squared(v1 Vector2) f64 {
	return math.pow(v1.x - v.x, 2) + math.pow(v1.y - v.y, 2)
}

pub fn (v Vector2) angle_r() f64 {
	return math.atan2(v.y, v.x)
}

pub fn (v Vector2) angle() f64 {
	return v.angle_r() * 180 / math.pi
}

pub fn (v Vector2) length() f64 {
	return math.sqrt(v.x*v.x + v.y*v.y)
}

pub fn (v Vector2) nor() Vector2 {
	len := v.length()
	return Vector2{
		v.x / len,
		v.y / len
	}
}

pub fn (v Vector2) angle_rv(v1 Vector2) f64 {
	return math.atan2(
		v.y - v1.y,
		v.x - v1.x
	)
}

pub fn (v Vector2) rotate(rad f64) Vector2 {
	cos := math.cos(rad)
	sin := math.sin(rad)
	return Vector2{
		v.x * cos - v.y * sin,
		v.x * sin + v.y * cos
	}
}

pub fn (v Vector2) scale(by f64) Vector2 {
	return Vector2{
		v.x * by,
		v.y * by
	}
}

pub fn (v Vector2) clone() Vector2 {
	return Vector2{v.x, v.y}
}