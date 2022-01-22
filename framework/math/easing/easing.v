module easing

import math

/*
	easing bullshit in here

    t is the current time (or position) of the tween.
    b is the beginning value of the property.
    c is the change between the beginning and destination value of the property.
    d is the total time of the tween.
*/
pub type EasingFunction = fn (f64, f64, f64, f64) f64

// FNs starts here
pub fn linear(t f64, b f64, c f64, d f64) f64 {
	return c*t/d+b
}

pub fn quad_in(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt
	t /= d
	return c * t * t + b
}

pub fn quad_out(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt
	t /= d
	return -c * t * (t - 2) + b
}

pub fn quad_in_out(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt
	t /= d
	t /= d / 2

	if t < 1 {
		return c / 2 * t * t + b
	}
	t -= 1

	return -c / 2 * (t * (t - 2) - 1) + b
}

pub fn quart_in(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt

	t /= d
	return c * t * t * t * t + b
}

pub fn quart_out(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt

	t /= d
	t -= 1
	return -c * (t * t * t * t - 1) + b
}

pub fn quart_in_out(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt

	t /= d / 2

	if t < 1 {
		return c / 2 * t * t * t * t + b
	}

	t -= 2

	return -c / 2 * (t * t * t * t - 2) + b
}

pub fn quint_in(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt

	t /= d

	return c * t * t * t * t * t + b
}

pub fn quint_out(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt

	t /= d
	t -= 1

	return c * (t * t * t * t * t + 1) + b
}

pub fn quint_in_out(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt

	t /= d / 2

	if t < 1 {
		return c / 2 * t * t * t * t * t + b
	}

	t -= 2
	return c / 2 * (t * t * t * t * t + 2) + b
}

pub fn sine_in(t f64, b f64, c f64, d f64) f64 {
	return -c * math.cos(t / d * (math.pi / 2)) + c + b
}

pub fn sine_out(t f64, b f64, c f64, d f64) f64 {
	return c * math.sin(t / d * (math.pi / 2)) + b
}

pub fn sine_in_out(t f64, b f64, c f64, d f64) f64 {
	return -c / 2 * (math.cos(math.pi * t / d) - 1) + b
}

