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
	return f64(c * t * t + b)
}

pub fn quad_out(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt
	t /= d
	return f64(-c * t * (t - 2) + b)
}

pub fn quad_in_out(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt
	t /= d
	t /= d / 2

	if t < 1 {
		return f64(c / 2 * t * t + b)
	}
	t -= 1

	return f64(-c / 2 * (t * (t - 2) - 1) + b)
}

pub fn quart_in(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt

	t /= d
	return f64(c * t * t * t * t + b)
}

pub fn quart_out(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt

	t /= d
	t -= 1
	return f64(-c * (t * t * t * t - 1) + b)
}

pub fn quart_in_out(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt

	t /= d / 2

	if t < 1 {
		return f64(c / 2 * t * t * t * t + b)
	}

	t -= 2
	return f64(-c / 2 * (t * t * t * t - 2) + b)
}

pub fn quint_in(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt

	t /= d

	return f64(c * t * t * t * t * t + b)
}

pub fn quint_out(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt

	t /= d
	t -= 1

	return f64(c * (t * t * t * t * t + 1) + b)
}

pub fn quint_in_out(tt f64, b f64, c f64, d f64) f64 {
	mut t := tt

	t /= d / 2

	if t < 1 {
		return f64(c / 2 * t * t * t * t * t + b)
	}

	t -= 2
	return f64(c / 2 * (t * t * t * t * t + 2) + b)
}

pub fn sine_in(t f64, b f64, c f64, d f64) f64 {
	return f64(-c * math.cos(t / d * (math.pi / 2)) + c + b)
}

pub fn sine_out(t f64, b f64, c f64, d f64) f64 {
	return f64(c * math.sin(t / d * (math.pi / 2)) + b)
}

pub fn sine_in_out(t f64, b f64, c f64, d f64) f64 {
	return f64(-c / 2 * (math.cos(math.pi * t / d) - 1) + b)
}


// Storyboard
pub enum Easing {
	linear
	ease_out
	ease_in
	quad_in
	quad_out
	quad_in_out
	cubic_in
	cubic_out
	cubic_in_out
	quart_in
	quart_out
	quart_in_out
	quint_in
	quint_out
	quint_in_out
	sine_in
	sine_out
	sine_in_out
	expo_in
	expo_out
	expo_in_out
	circ_in
	circ_out
	circ_in_out
	elastic_in
	elastic_out
	elastic_half_out
	elasic_quart_out
	elastic_in_out
	back_in
	back_out
	back_in_out
	bounce_in
	bounce_out
	bounce_in_out
}

pub fn get_easing_from_enum(e Easing) EasingFunction {
	// Temporary cuz v is fucky wucky
	return match e {
		.linear { linear }
		.quad_in { quad_in }
		.quad_out { quad_out }
		.quad_in_out { quad_in_out }
		else { quad_out }
	}
	/*
	return match e {
		.linear { linear }
		.quad_in { quad_in }
		.quad_out { quad_out }
		.quad_in_out { quad_in_out }
		.quart_in { quart_in }
		.quart_out { quart_out }
		.quart_in_out { quart_in_out }
		.quint_in { quint_in }
		.quint_out { quint_out }
		.quint_in_out { quint_in_out }
		.sine_in { sine_in }
		.sine_out { sine_out }
		.sine_in_out { sine_in_out }
		else { quad_out }
	}
	*/
}
