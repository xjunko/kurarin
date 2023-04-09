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
	return c * t / d + b
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

pub fn elastic_in(_t f64, b f64, c f64, d f64) f64 {
	mut s := 1.70158
	mut a := c
	mut t := _t

	if t == 0 {
		return b
	}

	t /= d

	if t == 1 {
		return b + c
	}

	p := d * 0.3
	if a < math.abs(c) {
		a = c
		s = p / 4
	} else {
		s = p / (2 * math.pi) * math.asin(c / a)
	}

	t -= 1
	return -(a * math.pow(2, 10 * t) * math.sin((t * d - s) * (2 * math.pi) / p)) + b
}

pub fn elastic_out(_t f64, b f64, c f64, d f64) f64 {
	mut s, mut a := 1.70158, c
	mut t := _t

	if t == 0 {
		return b
	}
	t /= d
	if t == 1 {
		return b + c
	}

	mut p := d * 0.3
	if a < math.abs(c) {
		a, s = c, p / 4
	} else {
		s = p / (2 * math.pi) * math.asin(c / a)
	}

	return a * math.pow(2, -10 * t) * math.sin((t * d - s) * (2 * math.pi) / p) + c + b
}

pub fn elastic_in_out(_t f64, b f64, c f64, d f64) f64 {
	mut s, mut a := 1.70158, c
	mut t := _t

	if t == 0 {
		return b
	}

	t /= (d / 2)

	if t == 2 {
		return b + c
	}

	p := d * (0.3 * 1.5)
	if a < math.abs(c) {
		a, s = c, p / 4
	} else {
		s = p / (2 * math.pi) * math.asin(c / a)
	}

	if t < 1 {
		t -= 1
		return -0.5 * (a * math.pow(2, 10 * t) * math.sin((t * d - s) * (2 * math.pi) / p)) + b
	}

	return 0.0
}
